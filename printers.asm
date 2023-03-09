#-----------------------------------------------------------------------------#
#   File:       checkers.asm
#   Author:     Robert Tetreault (rrt2850)
#   Section:    3
#
#   Description:  
#       This file is full of functions for sudoku.asm to use for printing
#       things or changing how something is printed
#-----------------------------------------------------------------------------#

PRINT_INT       = 1     # code for syscall to print an integer
PRINT_CHAR      = 11    # code for syscall to print a character
PRINT_STRING    = 4     # code for syscall to print a string
BOARD_DIM       = 6     # width/height of the board
SPACE_CHAR      = 32    # the number representing zero in ascii

.data
.align 0

#
#   Stuff used to print the table
#

horiBar:        .asciiz "+-----+-----+\n"
vertBar:        .asciiz "|"
newLine:        .asciiz "\n"

#
#   Stuff explaining what's happening to user
#
intro:          .asciiz "\n**************\n**  SUDOKU  **\n**************\n\n"
iniPuzzle:      .asciiz "Initial Puzzle\n\n"
finalPuzzle:    .asciiz "Final Puzzle\n\n"
badEnd:         .asciiz "ERROR: bad input value, Sudoku terminating\n"
badPuzzle:      .asciiz "Impossible Puzzle"

.text
.align 2

#
#   Global labels in this file
#
.globl  printBoard
.globl  printBoard
.globl  printIntro
.globl  solverErrorMessage
.globl  announcePuzzle
.globl  announceFinalPuzz
.globl  mbError

#
#   External labels used
#
.globl  board


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
FRAMESIZE_4 = 4
printBoard:           
    addi    $sp, $sp, -FRAMESIZE_4      # allocate space on the stack
    sw      $ra, -4+FRAMESIZE_4($sp)    # store the return address to stack

    move    $t0, $zero          # row counter
    move    $t1, $zero          # column counter
    move    $t2, $zero          # horizontal section counter (for middle bar)
    move    $t3, $zero          # vertical section counter (for vertical bars)
    la      $t4, board          # current memory location 

    jal     printHoriBar 

rowLoop:
    jal     printVertBar        

colLoop:
    lb      $a0, 0($t4)             
    bne     $a0, $zero, switchSkip    
    jal     printSpace              # if index is '0', print ' ' instead
    j       endSwitchSkip
switchSkip:                         # jump here if the character isn't '0'
    li      $v0, PRINT_INT
    syscall                         # print the character
endSwitchSkip:
    
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
#   endl:   prints "\n" when called 
#
endl:
    la  $a0, newLine
    li  $v0, PRINT_STRING
    syscall
    jr  $ra


#
#   printSpace: prints ' ' 
#
printSpace:
    li      $v0, PRINT_CHAR
    li      $a0, SPACE_CHAR
    syscall                         # print the space
    jr  $ra

#
#   printIntro: prints the intro message
#
printIntro:
    la  $a0, intro
    li  $v0, PRINT_STRING
    syscall                             # print the intro message
    jr  $ra

#
#   announcePuzzle: labels the first puzzle initial puzzle
#
announcePuzzle:
    la      $a0, iniPuzzle
    li      $v0, PRINT_STRING
    syscall                             # print "Initial Puzzle"
    jr  $ra

#
#   announceFinalPuzz: labels the second puzzle final puzzle 
#
announceFinalPuzz:
    la      $a0, finalPuzzle
    li      $v0, PRINT_STRING
    syscall                             # print "Final Puzzle"
    jr      $ra
#
#   solverErrorMessage: prints a message when the puzzle is impossible
#
solverErrorMessage:
    la      $a0, badPuzzle
    li      $v0, PRINT_STRING
    syscall                             # print error message

    jr      $ra

#
#   mbError: prints an error message when the input is bad
#
mbError:
    la      $a0, badEnd                 
    li      $v0, PRINT_STRING
    syscall                             # print error output
    jr      $ra