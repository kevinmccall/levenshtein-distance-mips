MAX_STRING_SIZE = 100

.data
    str1: .space MAX_STRING_SIZE
    str2: .space MAX_STRING_SIZE

    newline: .asciiz "\n"
    space: .asciiz " "

    prompt1: .asciiz "Enter string #1 to be compared: "
    prompt2: .asciiz "Enter string #2: "
    prompt3: .asciiz "Bottom-up recursion table:\n"
    prompt4: .asciiz "Total Levenshtein distance: "

.text
.globl main
main:
    li $v0, 4
    la $a0, prompt1
    syscall

    li $v0, 8
    la $a0, str1
    li $a1, MAX_STRING_SIZE
    syscall

    li $v0, 4
    la $a0, prompt2
    syscall

    li $v0, 8
    la $a0, str2
    li $a1, MAX_STRING_SIZE
    syscall

    la $a0, str1
    la $a1, str2

    jal levenshtein

    move $s1, $v0

    li $v0, 4
    la $a0, prompt4
    syscall

    move $a0, $s1
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

strlen:
    li $v0, 0 # initialize the count to zero
    loop:
        lbu $t1, 0($a0) # load the next character into t1
        beqz $t1, exitstrlen # check for the null character
        addi $a0, $a0, 1 # increment the string pointer
        addi $v0, $v0, 1 # increment the count
        j loop # return to the top of the loop
    exitstrlen:
    jr $ra


levenshtein:
    addi $sp, $sp, -20
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    move $s0, $a0
    move $s1, $a1
    jal strlen
    addi $s2, $v0, 1
    move $a0, $s1
    jal strlen
    addi $s3, $v0, 1

    lw $ra, 0($sp)
    addi $sp, $sp, 4

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
            lb $t4, -1($t3)

            # check char at str2
            add $t3, $t2, $s1
            lb $t5, -1($t3)

            # determine if both strings contain the same character
            sub $t4, $t4, $t5
            beqz $t4, charequal 
            # characters are not equal
            # i * (str1len + 1) + j -> arr[i][j]
            
            # arr[i][j]
            mul $t3, $s2, $t2
            add $t3, $t3, $sp
            add $t3, $t3, $t1

            # arr[i-1][j]
            sub $t3, $t3, $s2
            lb $s4, 0($t3)

            # arr[i-1][j-1]            
            lb $t4, -1($t3)

            bge $t4, $s4, skipsmallest1
            #set smallest
            move $s4, $t4
            skipsmallest1:

            # arr[i][j-1]
            add $t3, $t3, $s2
            lb $t4, -1($t3)

            bge $t4, $s4, skipsmallest2
            # set smallest 
            move $s4, $t4
            skipsmallest2:

            # add 1 to smallest (replacement, insertion, or deletion operation)
            addi $s4, $s4, 1
            # arr[i][j]
            sb $s4, 0($t3)

            j charequalexit
            charequal:
            # load arr[i-1][j-1]
            mul $t3, $s2, $t2
            add $t3, $t3, $sp
            add $t3, $t3, $t1

            sub $t3, $t3, $s2
            lb $s4, -1($t3)

            add $t3, $t3, $s2
            sb $s4, 0($t3)

            charequalexit:

            addi $t1, $t1, 1;
            j str1loop
        exitstr1loop:
        
        addi $t2, $t2, 1
        j str2loop

    exitstr2loop:

    li $v0, 4
    la $a0, prompt3
    syscall
    li $t2, 0
    iloop:
        bge $t2, $s3, endiloop
        li $t1, 0
        jloop:
            bge $t1, $s2, endjloop
            
            mul $t3, $t2, $s2
            add $t3, $t3, $sp
            add $t3, $t3, $t1

            lb $a0, 0($t3)
            li $v0, 1
            syscall
            li $v0, 4
            la $a0, space
            syscall

            add $t1, $t1, 1
            j jloop
        endjloop:

        li $v0, 4
        la $a0, newline
        syscall

        addi $t2, $t2, 1
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
