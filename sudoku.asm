#-----------------------------------------------------------------------------#
#   File:       sudoku.asm
#   Author:     Robert Tetreault (rrt2850)
#   Section:    3
#
#   Description:  
#       This program uses backtracking to solve a sudoku game
#       entered by the user
#-----------------------------------------------------------------------------#


#
#   Constants
#
READ_INT        = 5      # code for syscall to read an integer

BOARD_SIZE      = 36    # the area covered by the board
BOARD_DIM       = 6     # width/height of the board

BACKSPACE       = 10    # the ascii for the backspace character


.data
.align 0    # no alignment needed for bytes


#
#   A 2d array representing the board
#
#   NOTE:   I chose this representation instead allocating space in one go
#           because it's easier to visualize and can be used to test stuff
board:
    .byte 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0
    .byte 0, 0, 0, 0, 0, 0

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

#
#   Global labels in this file
#
.globl main         
.globl getIndex
.globl board
.globl occupiedBoard


#
#   External functions called
#
.globl  printBoard
.globl  printIntro
.globl  solverErrorMessage
.globl  announcePuzzle
.globl  announceFinalPuzz
.globl  mbError

.globl  checkRow
.globl  checkCol
.globl  checkBox  

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
main:                                  
    addi    $sp, $sp, -FRAMESIZE_4      # allocate space for the stack frame
    sw      $ra, -4+FRAMESIZE_4($sp)    # store the ra on the stack

    jal     printIntro                  # print the intro

    jal     makeBoard                   # make the board
    bne     $v0, $zero, exitMain        # exit if it failed

    jal     announcePuzzle              # display first puzzle title
    jal     printBoard                  # print the initial board

    jal     solver                      # attempt to solve the puzzle
    bne     $v0, $zero, exitMain        # exit if it failed

    jal     announceFinalPuzz           # display second puzzle title
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
    li      $t3, 1                      
    move    $t4, $zero                  # input counter


inputLoop:
    li      $v0, READ_INT
    syscall                             # get input from user
    beq     $v0, $t2, inputLoop         # parse out backspace characters
    
    slti    $t5, $v0, 0         
    bne     $t5, $zero, mbBadEnd        # exit if input < 0
    
    slti    $t5, $v0, 7            
    beq     $t5, $zero, mbBadEnd        # exit if input > 6

    sb      $v0, 0($t0)                 # store valid number

    slti    $t5, $v0, 1
    bne     $t5, $zero, oneSkip         # if input = 0, don't modify 
                                        # the occupiedBoard

    sb      $t3, 0($t1)                 # store 1 on occupied board
oneSkip:

    addi    $t0, $t0, 1                 # increment board address
    addi    $t1, $t1, 1                 # increment occupiedBoard address
    addi    $t4, $t4, 1                 # increment counter

    slti    $t5, $t4, BOARD_SIZE
    bne     $t5, $zero, inputLoop       # loop until counter gets to 35

    move    $v0, $zero                  # return 1 on success
    j       mbExit

mbBadEnd:
    jal     mbError
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
    lb      $t4, 0($t2)                 # load corresponding board spot in t4

#
#   startGuessing:  methodically guesses numbers until a valid one is found for
#                   each square
#
startGuessing:
    addi    $t4, $t4, 1                 # increment number

    slti    $t5, $t4, 7
    beq     $t5, $zero, backtrack       # backtrack if number > 6

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
         
    sb      $zero, 0($t2)                 # replace the current spot with 0

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

    sb      $zero, 0($t2)                 # replace the current spot with '0'

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
    jal solverErrorMessage
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
FRAMESIZE_16 = 16
getIndex:
    addi    $sp, $sp, -FRAMESIZE_16         # allocate stack space
    sw      $ra, -4+FRAMESIZE_16($sp)       # store ra on the stack
    sw      $t0, -8+FRAMESIZE_16($sp)       
    sw      $t1, -12+FRAMESIZE_16($sp)      
    sw      $t2, -16+FRAMESIZE_16($sp)      

    move    $t0, $s0                        
    li      $t2, BOARD_DIM                  
    mul     $t1, $s1, $t2                   # multiply columns by width
    add     $t1, $t1, $s2                   # add the remainder
    add     $t0, $t0, $t1                   # add it to the board address 
        
    lb $v0, 0($t0)                          # return value from new address

    lw  $t2, -16+FRAMESIZE_16($sp)      # restore all the registers used
    lw  $t1, -12+FRAMESIZE_16($sp)  
    lw  $t0, -8+FRAMESIZE_16($sp)   
    lw  $ra, -4+FRAMESIZE_16($sp)       # restore the ra
    addi    $sp, $sp, FRAMESIZE_16      # deallocate stack space
    jr  $ra
