str1len=8
str2len=5

.data
    str1: .asciiz "fortnite"
    str2: .asciiz "fortn"

    newline: .asciiz "\n"
    space: .asciiz "_"

.text
.globl main
main:
    la $a0, str1
    la $a1, str2

    jal levenshtein

    move $a0, $v0
    li $v0, 1
    syscall

    li $v0, 10
    syscall

# $a0 -> str1
# $a2 -> str2
#
# $s0 -> str1
# $s1 -> str2
# $s2 -> str1len + 1
# $s3 -> str2len + 1
# $s4 -> smallest
# $t0 -> (str1len + 1) * (str2len + 1) : used for storing array on heap
# $t1 -> j
# $t2 -> i
# $t3 -> temp reg for address calculations
# $t4 -> temp reg for calculating string stuff
# $t5 -> temp reg for calculating string stuff
levenshtein:
    addi $sp, $sp, -20
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    # TODO do the saving registers jazz

    move $s0, $a0
    move $s1, $a1
    li $s2, str1len
    addi $s2, $s2, 1
    li $s3, str2len
    addi $s3, $s3, 1

    mul $t0, $s2, $s3
    sub $sp, $sp, $t0

    li $t1, 0
    initstr1:
        bge $t1, $s2, exitinitstr1
        # j -> arr[0][j]
        add $t3, $sp, $t1
        sb $t1, 0($t3)
        addi $t1, $t1, 1
        j initstr1
    exitinitstr1:

    li $t2, 0
    initstr2:
        bge $t2, $s3, exitinitstr2
        # i * (strlen + 1) -> arr[i][0]
        mul $t3, $t2, $s2
        add $t3, $t3, $sp
        sb $t2, 0($t3)
        addi $t2, $t2, 1
        j initstr2
    exitinitstr2:

    li $t2, 1
    str2loop:
        bge $t2, $s3, exitstr2loop

        li $t1, 1
        str1loop:
            bge $t1, $s2, exitstr1loop
            
            # check char at str1
            add $t3, $t1, $s0
            addi $t3, $t3, -1
            # TODO do a negative offset because it is cool
            lb $t4, 0($t3)

            # check char at str2
            add $t3, $t2, $s1
            addi $t3, $t3, -1
            lb $t5, 0($t3)

            # determine if both strings contain the same character
            sub $t4, $t4, $t5
            beqz $t4, charequal 
            # characters are not equal
            # i * (str1len + 1) + j -> arr[i][j]
            
            # arr[i-1][j]
            mul $t3, $s2, $t2
            add $t3, $t3, $sp
            sub $t3, $t3, $s2
            add $t3, $t3, $t1
            lb $s4, 0($t3)

            # arr[i-1][j-1]            
            addi $t3, $t3, -1
            lb $t4, 0($t3)

            bge $t4, $s4, skipsmallest1
            #set smallest
            move $s4, $t4
            skipsmallest1:

            # arr[i][j-1]
            add $t3, $t3, $s2
            lb $t4, 0($t3)

            bge $t4, $s4, skipsmallest2
            # set smallest 
            move $s4, $t4
            skipsmallest2:

            # add 1 to smallest (replacement, insertion, or deletion operation)
            addi $s4, $s4, 1
            # arr[i][j]
            addi $t3, $t3, 1
            sb $s4, 0($t3)

            j charequalexit
            charequal:
            # load arr[i-1][j-1]
            mul $t3, $s2, $t2
            add $t3, $t3, $sp
            sub $t3, $t3, $s2
            add $t3, $t3, $t1
            addi $t3, $t3, -1
            lb $s4, 0($t3)

            add $t3, $t3, $t2
            addi $t3, $t3, 1
            sb $s4, 0($t3)

            charequalexit:

            addi $t1, $t1, 1;
            j str1loop
        exitstr1loop:
        
        addi $t2, $t2, 1
        j str2loop

    exitstr2loop:

    li $t6, 0
    iloop:
        bge $t6, $s3, endiloop
        li $t7, 0
        jloop:
            bge $t7, $s2, endjloop
            
            mul $t5, $t6, $s2
            add $t5, $t5, $sp
            add $t5, $t5, $t7

            lb $a0, 0($t5)
            li $v0, 1
            syscall
            li $v0, 4
            la $a0, space
            syscall

            add $t7, $t7, 1
            j jloop
        endjloop:

        li $v0, 4
        la $a0, newline
        syscall

        addi $t6, $t6, 1
        j iloop
    endiloop:

    add $sp, $sp, $t0

    move $v0, $s4

    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    addi $sp, $sp, 20

    jr $ra
