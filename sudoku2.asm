#---+----1----+----2----+----3----+----4----+----5----+----6----+----7----+----8

#   File:     sudoku.asm
#   Author:   Robert Tetreault (rrt2850)
#
#   Description:  
#       This program uses backtracking to solve a sudoku game
#       entered by the user
#

#-------------------------------
#
#   Constants
#

PRINT_STRING    = 4     # code for syscall to print a string
PRINT_CHAR      = 11    # code for syscall to print a character
READ_CHAR       = 12    # code for syscall to read a character

BOARD_DIM       = 6     # width/height of the board
BOARD_SIZE      = 36    # the area covered by the board
BACKSPACE       = 10    # the ascii for the backspace character

ROW_SEC_1       = 2     # if the row is < 2 it's in section 1
ROW_SEC_2       = 4     # if the row is < 4 it's in section 2
COL_SEC_1       = 3     # if the col is < 3 it's in section 1

ZERO_CHAR       = 48    # the number representing zero in ascii
ONE_CHAR        = 49    # the number representing one in ascii
SEVEN_CHAR      = 55    # the number representing seven in ascii

#-------------------------------
#
#   Data Area
#

    .data
    .align 0    # no alignment needed for strings

#
#   Stuff explaining what's happening to user
#
intro:          .asciiz "\n**************\n**  SUDOKU  **\n**************\n\n"
iniPuzzle:      .asciiz "Initial Puzzle\n\n"
finalPuzzle:    .asciiz "Final Puzzle\n\n"
badPuzzle:      .asciiz "Impossible Puzzle"
badEnd:         .asciiz "ERROR: bad input value, Sudoku terminating\n"

#
#   Stuff used to print the table
#
horiBar:    .asciiz "+-----+-----+\n"
vertBar:    .asciiz "|"
space:      .asciiz " "
newLine:    .asciiz "\n"

#
#   A 2d array representing the board
#
#   NOTE:   I chose this representation instead allocating space in one go
#           because it's easier to visualize and can be used to test stuff
board:
    .byte '0', '0', '0', '0', '0', '0'
    .byte '0', '0', '0', '0', '0', '0'
    .byte '0', '0', '0', '0', '0', '0'
    .byte '0', '0', '0', '0', '0', '0'
    .byte '0', '0', '0', '0', '0', '0'
    .byte '0', '0', '0', '0', '0', '0'

#
#   A 2d array representing the initial board. This is used during the 
#   backtracking to know which cells to skip.
#
occupiedBoard:
    .byte 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0
   
.text               # switch back to program code
.align 2            # set code back to word boundaries


#-----------------------------------------------------------------------------#
#   Name:           main
#
#   Description:    execution begins here, main sets everything up and prints
#                   the results to the user
#
#   Arguments:      none
#   Returns:
#                   - v0 = 1 if it failed
#                   - v0 = 0 if it succeeded
#   modifies:       a0, v0
#-----------------------------------------------------------------------------#

FRAMESIZE_4 = 4

.globl main         # entrance for the linker
main:                                  
    addi    $sp, $sp, -FRAMESIZE_4      # allocate space for the stack frame
    sw      $ra, -4+FRAMESIZE_4($sp)    # store the ra on the stack

    la  $a0, intro
    li  $v0, PRINT_STRING
    syscall                             # print the intro message

    jal     makeBoard                   # make the board
    bne     $v0, $zero, exitMain        # exit if it failed

    la      $a0, iniPuzzle
    li      $v0, PRINT_STRING
    syscall                             # print "Initial Puzzle"

    jal     printBoard                  # print the initial board

    jal     solver                      # attempt to solve the puzzle
    bne     $v0, $zero, exitMain        # exit if it failed

    la      $a0, finalPuzzle
    li      $v0, PRINT_STRING
    syscall                             # print "Final Puzzle"

    jal     printBoard                  # print the solved puzzle

    move    $v0, $zero                  # return 0 on success
    
exitMain:
    lw      $ra, -4+FRAMESIZE_4($sp)    # restore the ra
    addi    $sp, $sp, FRAMESIZE_4       # deallocate stack space
    jr      $ra                         # return from main and exit

#-----------------------------------------------------------------------------#
#   Name:           makeBoard
#
#   Description:    gets 36 characters from the user and stores them on
#                   the board
#
#   Arguments:      none
#   Returns:
#                   - v0 = 1 if it failed
#                   - v0 = 0 if it succeeded
#   modifies:       t0,t1,t2,t3,t4,t5,t6,v0
#
#   Note: assumes that the user will enter 36 characters
#
#-----------------------------------------------------------------------------#
makeBoard:
    addi    $sp, $sp, -FRAMESIZE_4      # allocate stack space
    sw      $ra, -4+FRAMESIZE_4($sp)    # store the ra on the stack
    
    la      $t0, board                  # current memory location
    la      $t1, occupiedBoard          # occupiedBoard memory location
    li      $t2, BACKSPACE              
    li      $t3, SEVEN_CHAR             
    li      $t4, 1                      
    move    $t5, $zero                  # input counter


inputLoop:
    li      $v0, READ_CHAR
    syscall                             # get input from user
    beq     $v0, $t2, inputLoop         # parse out backspace characters
    
    slti    $t6, $v0, ZERO_CHAR         
    bne     $t6, $zero, mbBadEnd        # exit if input < '0'
    
    slt     $t6, $t3, $v0               
    bne     $t6, $zero, mbBadEnd        # exit if input > '7'

    sb      $v0, 0($t0)                 # store valid character

    slti    $t6, $v0, ONE_CHAR
    bne     $t6, $zero, oneSkip         # if input = '0', don't modify 
                                        # the occupiedBoard

    sb      $t4, 0($t1)                 # store 1 on occupied board

oneSkip:
    addi    $t0, $t0, 1                 # increment board address
    addi    $t1, $t1, 1                 # increment occupiedBoard address
    addi    $t5, $t5, 1                 # increment counter

    slti    $t6, $t5, BOARD_SIZE
    bne     $t6, $zero, inputLoop       # loop until counter gets to 35

    move    $v0, $zero                  # return 1 on success
    j       mbExit

mbBadEnd:
    la      $a0, badEnd                 
    li      $v0, PRINT_STRING
    syscall                             # print error output

    li    $v0, 1                        # return 0 on failure

mbExit:
    lw      $ra, -4+FRAMESIZE_4($sp)    # restore the ra
    addi    $sp, $sp, FRAMESIZE_4       # deallocate stack space
    jr      $ra

#-----------------------------------------------------------------------------#
#   Name:           solver
#
#   Description:    uses backtracking to attempt to solve the board
#
#   Arguments:      none
#   Returns:
#                   - v0 = 1 if it failed
#                   - v0 = 0 if it succeeded
#   modifies:       t0,t1,t2,t3,t4,t5,s0,s1,s2,s3,v0,a0
#-----------------------------------------------------------------------------#

solver:
    S_FRAMESIZE = 4                    
    addi    $sp, $sp, -FRAMESIZE_4      # allocate stack space
    sw      $ra, -4+FRAMESIZE_4($sp)    # store return address on stack

    move    $t0, $zero                  # initialize row counter
    move    $t1, $zero                  # initialize column counter
    la      $t2, board                  # store board address in t2
    la      $t3, occupiedBoard          # store occupied board address in t3

#   enter row loop
sRowLoop:
#   enter column loop
sColLoop:
    lb      $t4, 0($t3)
    bne     $t4, $zero, skipGuesswork   # skip spot if it's occupied at start 
    lb      $t4, 0($t2)                 # load corresponding board number in t4

#
#   startGuessing:  methodically guesses numbers until a valid one is found for
#                   each square
#
startGuessing:
    addi    $t4, $t4, 1                 # increment number

    slti    $t5, $t4, SEVEN_CHAR
    beq     $t5, $zero, backtrack       # backtrack if number > '6'

    #
    #   Store variables in s registers for the checkers to use
    #
    la      $s0, board
    move    $s1, $t0
    move    $s2, $t1                
    move    $s3, $t4

    jal     checkRow                    
    bne     $v0, $zero, startGuessing   # increment and try again if num found

    jal     checkCol                    
    bne     $v0, $zero, startGuessing   # increment and try again if num found

    jal     checkBox                    
    bne     $v0, $zero, startGuessing   # increment and try again if num found

    sb      $t4, 0($t2)                 # if number is valid change board value

    j       skipGuesswork

#
#   Backtrack:  goes back and tries different numbers on previous squares if a
#               value can't be found in startGuessing
#
backtrack:
    beq     $t1, $zero, colZero         # if col = 0 go back row

    addi    $t1, $t1, -1                # decrement column counter
    addi    $t2, $t2, -1                # decrement board address
    addi    $t3, $t3, -1                # decrement occupied board address

    lb      $t4, 0($t3)
    bne     $t4, $zero, backtrack       # if the spot is occupied backtrack
    lb      $t4, 0($t2)                 

    li      $t5, ZERO_CHAR              
    sb      $t5, 0($t2)                 # replace the current spot with '0'

    j       startGuessing               # start guessing using the new square

#
#   colZero:    called when the program is trying to backtrack but it's already
#               in column zero. Because the column is zero, it needs to go up a
#               row to backtrack
#
colZero:
    beq     $t0, $zero, solverBadExit   # if index is (0,0) exit

    li      $t1, 5                      # max out column counter
    addi    $t0, $t0, -1                # decrement row counter
    addi    $t2, $t2, -1                # decrement board address
    addi    $t3, $t3, -1                # decrement occupied board address

    lb      $t4, 0($t3)
    bne     $t4, $zero, backtrack       # if the spot is occupied, backtrack
    lb      $t4, 0($t2)                 

    li      $t5, ZERO_CHAR              # load '0' into t9
    sb      $t5, 0($t2)                 # replace the current spot with '0'

    j       startGuessing               # start guessing using new spot

skipGuesswork:
    addi    $t1, $t1, 1                 # increment col counter
    addi    $t2, $t2, 1                 # increment board address
    addi    $t3, $t3, 1                 # increment occupied board address

    slti    $t5, $t1, BOARD_DIM
    bne     $t5, $zero, sColLoop        # loop while col < 6
#   leave column loop

    move    $t1, $zero                  # reset col counter
    addi    $t0, $t0, 1                 # increment row counter

    slti    $t5, $t0, BOARD_DIM
    bne     $t5, $zero, sRowLoop        # loop while row < 6
#   leave row loop

    move    $v0, $zero                  
    j       solverExit                  # return 0 upon success

solverBadExit:
    la      $a0, badPuzzle
    li      $v0, PRINT_STRING
    syscall                             # print error message

    li      $v0, 1                      # return 1 upon failure

solverExit:
    lw      $ra, -4+FRAMESIZE_4($sp)    # restore the ra
    addi    $sp, $sp, FRAMESIZE_4       # deallocate stack space
    jr      $ra


#-----------------------------------------------------------------------------#
#   Name:           getIndex
#
#   Description:    returns the contents of the board at the coordinates
#                   provided.         
#
#   Arguments:      
#                   - s0 = board
#                   - s1 = row
#                   - s2 = col
#   Returns:
#                   - v0 = the number found at the coordinates

#   modifies:       v0
#-----------------------------------------------------------------------------#
getIndex:
    GI_FRAMESIZE = 16
    addi    $sp, $sp, -GI_FRAMESIZE         # allocate stack space
    sw      $ra, -4+GI_FRAMESIZE($sp)       # store ra on the stack
    sw      $t0, -8+GI_FRAMESIZE($sp)       
    sw      $t1, -12+GI_FRAMESIZE($sp)      
    sw      $t2, -16+GI_FRAMESIZE($sp)      

    
    move    $t0, $s0                        
    li      $t2, BOARD_DIM                  
    mul     $t1, $s1, $t2                   # multiply columns by width
    add     $t1, $t1, $s2                   # add the remainder
    add     $t0, $t0, $t1                   # add it to the board address 
        
    lb $v0, 0($t0)                          # return value from new address

    lw  $t2, -16+GI_FRAMESIZE($sp)      # restore all the registers used
    lw  $t1, -12+GI_FRAMESIZE($sp)  
    lw  $t0, -8+GI_FRAMESIZE($sp)   
    lw  $ra, -4+GI_FRAMESIZE($sp)       # restore the ra
    addi    $sp, $sp, GI_FRAMESIZE      # deallocate stack space
    jr  $ra



#-----------------------------------------------------------------------------#
#                               Checker Functions                             #
#-----------------------------------------------------------------------------#



#-----------------------------------------------------------------------------#
#   Name:           checkRow
#
#   Description:    scans through columns in a row and looks for a number
#                   specified by s3
#
#   Arguments:      
#                   - s0 = board
#                   - s1 = row
#                   - s2 = col
#                   - s3 = number to check
#   Returns:
#                   - v0 = 1 if the number is found
#                   - v0 = 0 otherwise
#   modifies:       v0,a0
#-----------------------------------------------------------------------------#

FRAMESIZE_32 = 32
checkRow:                  
    addi    $sp, $sp, -FRAMESIZE_32     # allocate stack space
    sw      $ra, -4+FRAMESIZE_32($sp)   # backup all the registers used
    sw      $t0, -8+FRAMESIZE_32($sp)
    sw      $t1, -12+FRAMESIZE_32($sp)
    sw      $t2, -16+FRAMESIZE_32($sp)
    sw      $s0, -20+FRAMESIZE_32($sp)
    sw      $s1, -24+FRAMESIZE_32($sp)
    sw      $s2, -28+FRAMESIZE_32($sp)
    sw      $s3, -32+FRAMESIZE_32($sp)

    move    $t0, $zero              # initialize column counter
    
#   Enter check row loop
crLoop:
    move    $s2, $t0               
    jal     getIndex                # get the value at new coordinates

    beq     $s3, $v0, crBadEnd      # return 1 if s0 is found in the row

    addi    $t0, $t0, 1             # increment counter
    slti    $t1, $t0, 6
    bne     $t1, $zero, crLoop      # loop if column < 6

    li      $v0, 0
    j       crExit                  # return 0 upon success
  
crBadEnd:
    li      $v0, 1                  # return 1 upon failure

crExit:
    lw      $s3, -32+FRAMESIZE_32($sp)
    lw      $s2, -28+FRAMESIZE_32($sp)
    lw      $s1, -24+FRAMESIZE_32($sp)
    lw      $s0, -20+FRAMESIZE_32($sp)
    lw      $t2, -16+FRAMESIZE_32($sp)
    lw      $t1, -12+FRAMESIZE_32($sp)  
    lw      $t0, -8+FRAMESIZE_32($sp)   
    lw      $ra, -4+FRAMESIZE_32($sp)   # restore the ra
    addi    $sp, $sp, FRAMESIZE_32      # deallocate stack space
    jr      $ra

#-----------------------------------------------------------------------------#
#   Name:           checkCol
#
#   Description:    scans through rows in a column and looks for a number
#                   specified by s3
#
#   Arguments:      
#                   - s0 = board
#                   - s1 = row
#                   - s2 = col
#                   - s3 = number to check
#   Returns:
#                   - v0 = 1 if the number is found
#                   - v0 = 0 otherwise
#   modifies:       v0,a0
#-----------------------------------------------------------------------------#
checkCol:              
    addi    $sp, $sp, -FRAMESIZE_32     # allocate stack space
    sw      $ra, -4+FRAMESIZE_32($sp)   # backup all the registers used
    sw      $t0, -8+FRAMESIZE_32($sp)
    sw      $t1, -12+FRAMESIZE_32($sp)
    sw      $t2, -16+FRAMESIZE_32($sp)
    sw      $s0, -20+FRAMESIZE_32($sp)
    sw      $s1, -24+FRAMESIZE_32($sp)
    sw      $s2, -28+FRAMESIZE_32($sp)
    sw      $s3, -32+FRAMESIZE_32($sp)

    move    $t0, $zero              # set row counter to 0

#   Enter check column loop
ccLoop:
    move    $s1, $t0
    jal     getIndex                # update v0 with new s2 value

    beq     $s3, $v0, ccBadEnd      # return 1 if s3 is found in the column

    addi    $t0, $t0, 1             #increment row counter

    slti    $t1, $t0, 6
    bne     $t1, $zero, ccLoop      # loop if row < 6

    li  $v0, 0
    j   ccExit                      # return 0 on success

ccBadEnd:

    li  $v0, 1                      # return 1 on failure

ccExit:
    lw      $s3, -32+FRAMESIZE_32($sp)
    lw      $s2, -28+FRAMESIZE_32($sp)
    lw      $s1, -24+FRAMESIZE_32($sp)
    lw      $s0, -20+FRAMESIZE_32($sp)
    lw      $t2, -16+FRAMESIZE_32($sp)
    lw      $t1, -12+FRAMESIZE_32($sp) 
    lw      $t0, -8+FRAMESIZE_32($sp)   
    lw      $ra, -4+FRAMESIZE_32($sp)   # restore the ra
    addi    $sp, $sp, FRAMESIZE_32      # deallocate stack space
    jr      $ra

#-----------------------------------------------------------------------------#
#   Name:           checkBox
#
#   Description:    more complicated than the other check functions. Divides
#                   the board into 6 different groups and adjusts the row and
#                   column offset accordingly. Afterwards, it looks at all
#                   members of the group to find a number specified by s3                  
#
#   Arguments:      
#                   - s0 = board
#                   - s1 = row
#                   - s2 = col
#                   - s3 = number to check
#   Returns:
#                   - v0 = 1 if the number is found
#                   - v0 = 0 otherwise
#   modifies:       v0
#-----------------------------------------------------------------------------#
checkBox:
    CB_FRAMESIZE = 40
    addi    $sp, $sp, -CB_FRAMESIZE
    sw      $ra, -4+CB_FRAMESIZE($sp)
    sw      $t0, -8+CB_FRAMESIZE($sp)
    sw      $t1, -12+CB_FRAMESIZE($sp)
    sw      $t2, -16+CB_FRAMESIZE($sp)
    sw      $t3, -20+CB_FRAMESIZE($sp)
    sw      $t4, -24+CB_FRAMESIZE($sp)
    sw      $t5, -28+CB_FRAMESIZE($sp)
    sw      $s0, -32+CB_FRAMESIZE($sp)
    sw      $s1, -36+CB_FRAMESIZE($sp)
    sw      $s2, -40+CB_FRAMESIZE($sp)

    slti    $t0, $s1, ROW_SEC_1         
    bne     $t0, $zero, rowSecOne       # if row < 2, offset = 0

    slti    $t0, $s1, ROW_SEC_2         
    bne     $t0, $zero, rowSecTwo       # if 1 < row < 4, offset = 2

    li      $t1, ROW_SEC_2              # if 3 < row < 6, offset = 4 
    j       getColSec

#
#   rowSecOne:  sets the row offset to 0 because the row is in group 1
#
rowSecOne:
    move    $t1, $zero                  # set row offset to 0
    j       getColSec

#
#   rowSecTwo:  sets the row offset to 2 because the row is in group 2
#
rowSecTwo:
    li  $t1, ROW_SEC_1                  # set row offset to 2

getColSec:
    slti    $t0, $s2, COL_SEC_1         
    bne     $t0, $zero, colSecOne       # if col < 3, offset = 0

    li      $t2, COL_SEC_1              # else, offset = 3 (section 2)
    j       loopSetup

#
#   colSecOne:  sets the column offset to 0 because the column is in group 1
#
colSecOne:
    move $t2, $zero                     # set column offset to 0

loopSetup:
    move    $t3, $zero                  # initialize row counter
    move    $t4, $zero                  # initialize column counter

#   registers used in the loop:
#       t0 = boolean
#       t1 = row offset
#       t2 = col offset
#       t3 = row counter
#       t4 = col counter

cbRowLoop:
cbColLoop:
    move    $s1, $t3                    
    add     $s1, $s1, $t1               # increase row by offset

    move    $s2, $t4                    
    add     $s2, $s2, $t2               # increase column by offset

    jal     getIndex                    # get value at adjusted spot

    beq     $s3, $v0, cbBadEnd          # exit function if the number is found

    addi    $t4, $t4, 1                 # increment column counter 

    slti    $t0, $t4, 3
    bne     $t0, $zero, cbColLoop       # loop if column < 3
#   leave column loop
    
    move    $t4, $zero                  # reset column counter
    addi    $t3, $t3, 1                 # increment row counter

    slti    $t0, $t3, 2
    bne     $t0, $zero, cbRowLoop       # loop if row < 2
#   leave row loop

    li      $v0, 0                      # return 0 on success
    j       cbExit

#   return 0 if number is found    
cbBadEnd:
    li      $v0, 1                      # return 1 on failure

cbExit:
    lw      $s2, -40+CB_FRAMESIZE($sp)  # restore all registers used
    lw      $s1, -36+CB_FRAMESIZE($sp)
    lw      $s0, -32+CB_FRAMESIZE($sp)
    lw      $t5, -28+CB_FRAMESIZE($sp)
    lw      $t4, -24+CB_FRAMESIZE($sp)
    lw      $t3, -20+CB_FRAMESIZE($sp)
    lw      $t2, -16+CB_FRAMESIZE($sp)
    lw      $t1, -12+CB_FRAMESIZE($sp)  
    lw      $t0, -8+CB_FRAMESIZE($sp)   
    lw      $ra, -4+CB_FRAMESIZE($sp)   # restore the ra
    addi    $sp, $sp, CB_FRAMESIZE      # deallocate stack space
    jr      $ra


#-----------------------------------------------------------------------------#
#                               Print Functions                               #
#-----------------------------------------------------------------------------#

#-----------------------------------------------------------------------------#
#   Name:           printBoard
#
#   Description:    prints the current board
#
#   Arguments:      none
#   Returns:        none
#   modifies:       t0,t1,t2,t3,t4,t5,t6
#
#   Note: sorry that my solution to printing the bars on the board is kind of
#         gross, It's the best I could think of
#-----------------------------------------------------------------------------#

printBoard:           
    addi    $sp, $sp, -FRAMESIZE_4      # allocate space on the stack
    sw      $ra, -4+FRAMESIZE_4($sp)    # store the return address to stack

    move    $t0, $zero          # row counter
    move    $t1, $zero          # column counter
    move    $t2, $zero          # horizontal section counter (for middle bar)
    move    $t3, $zero          # vertical section counter (for vertical bars)
    la      $t4, board          # current memory location 
    li      $t5, ZERO_CHAR

    jal     printHoriBar 

rowLoop:
    jal     printVertBar        

colLoop:
    lb      $a0, 0($t4)             
    bne     $a0, $t5, switchSkip    
    jal     switch                  # if index is '0', print ' ' instead

switchSkip:                         # jump here if the character isn't '0'
    li      $v0, PRINT_CHAR
    syscall                         # print the character
    
    slti    $t6, $t2, 2             # print a bar every three characters
    bne     $t6, $zero, barSkip     # print a space otherwise

    jal     printVertBar            
    move    $t2, $zero              # reset section counter
    j       spaceSkip

barSkip:
    jal     printSpace             
    addi    $t2, $t2, 1             # increment section counter

spaceSkip:

    addi    $t1, $t1, 1             # increment column counter
    addi    $t4, $t4, 1             # increment current memory address

    slti    $t6, $t1, BOARD_DIM
    bne     $t6, $zero, colLoop     # loop 6 times
### Exit colLoop

    jal endl                        

    addi    $t0, $t0, 1             # increment row counter
    move    $t1, $zero              # reset column counter
    move    $t2, $zero              # reset vertical bar counter

    slti    $t6, $t3, 1
    bne     $t6, $zero, horiSkip    # print the horizontal bar every 2 rows
    
    jal     printHoriBar            
    move    $t3, $zero              # reset horizontal bar counter
    j       horiFinish

horiSkip:
    addi    $t3, $t3, 1             # increment horizontal section counter

horiFinish:
    slti    $t6, $t0, BOARD_DIM
    bne     $t6, $zero, rowLoop     # loop 6 times

### Exit rowLoop

    jal endl

    lw      $ra, -4+FRAMESIZE_4($sp)    # restore the ra
    addi    $sp, $sp, FRAMESIZE_4       # deallocate stack space
    jr      $ra

#
#   printVertBar:   prints '|' when called
#
printVertBar:
    la  $a0, vertBar
    li  $v0, PRINT_STRING
    syscall
    jr  $ra

#
#   printHoriBar:   prints "+-----+-----+\n" when called
#
printHoriBar:
    la  $a0, horiBar
    li  $v0, PRINT_STRING
    syscall
    jr  $ra

#
#   printSpace: prints " " when called
#
printSpace:
    la  $a0, space
    li  $v0, PRINT_STRING
    syscall
    jr  $ra

#
#   endl:   prints "\n" when called 
#
endl:
    la  $a0, newLine
    li  $v0, PRINT_STRING
    syscall
    jr  $ra

#
#   switch: sets the a register to ' ' so whatever character being printed
#           now prints ' ' instead
#
switch:
    li $a0, 32
    jr $ra
