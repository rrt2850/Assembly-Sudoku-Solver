#-----------------------------------------------------------------------------#
#   File:       checkers.asm
#   Author:     Robert Tetreault (rrt2850)
#   Section:    3
#
#   Description:  
#       This file is full of functions for sudoku.asm to use for checking
#       the numbers on the board
#-----------------------------------------------------------------------------#

ROW_SEC_1       = 2     # if the row is < 2 it's in section 1
ROW_SEC_2       = 4     # if the row is < 4 it's in section 2
COL_SEC_1       = 3     # if the col is < 3 it's in section 1

#
#   Global labels in this file
#
.globl checkRow
.globl checkCol
.globl checkBox

#
#   External functions called
#
.globl getIndex 

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
FRAMESIZE_40 = 40
checkBox:
    addi    $sp, $sp, -FRAMESIZE_40     # allocate stack space
    sw      $ra, -4+FRAMESIZE_40($sp)   # backup all registers used
    sw      $t0, -8+FRAMESIZE_40($sp)
    sw      $t1, -12+FRAMESIZE_40($sp)
    sw      $t2, -16+FRAMESIZE_40($sp)
    sw      $t3, -20+FRAMESIZE_40($sp)
    sw      $t4, -24+FRAMESIZE_40($sp)
    sw      $t5, -28+FRAMESIZE_40($sp)
    sw      $s0, -32+FRAMESIZE_40($sp)
    sw      $s1, -36+FRAMESIZE_40($sp)
    sw      $s2, -40+FRAMESIZE_40($sp)

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
    lw      $s2, -40+FRAMESIZE_40($sp)  # restore all registers used
    lw      $s1, -36+FRAMESIZE_40($sp)
    lw      $s0, -32+FRAMESIZE_40($sp)
    lw      $t5, -28+FRAMESIZE_40($sp)
    lw      $t4, -24+FRAMESIZE_40($sp)
    lw      $t3, -20+FRAMESIZE_40($sp)
    lw      $t2, -16+FRAMESIZE_40($sp)
    lw      $t1, -12+FRAMESIZE_40($sp)  
    lw      $t0, -8+FRAMESIZE_40($sp)   
    lw      $ra, -4+FRAMESIZE_40($sp)   # restore the ra
    addi    $sp, $sp, FRAMESIZE_40      # deallocate stack space
    jr      $ra

