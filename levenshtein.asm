###################################
#
# Kevin McCall
#
# Levenshtein Distance
#
###################################

# The largest string a user can input into this program. Picked arbitrarily
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
###########################################
# main:
# 	Main program, gets input from user and calls levenshtein procedure
#
# Register Legend
#   $s0 - stores output of levensthein distance
###########################################
main:
    # prompting and getting the first stirng from the user
    li $v0, 4
    la $a0, prompt1
    syscall

    li $v0, 8
    la $a0, str1
    li $a1, MAX_STRING_SIZE
    syscall

    # prompting and getting the second string from the user
    li $v0, 4
    la $a0, prompt2
    syscall

    li $v0, 8
    la $a0, str2
    li $a1, MAX_STRING_SIZE
    syscall

    # calling levenshtein
    la $a0, str1
    la $a1, str2
    jal levenshtein

    # printing the output of the levenshtein procedure
    move $s0, $v0
    li $v0, 4
    la $a0, prompt4
    syscall
    move $a0, $s0
    li $v0, 1
    syscall

    # exiting
    li $v0, 10
    syscall


###########################################
# main:
# 	Main program, gets input from user and calls levenshtein procedure
#   Based on code from:
#       https://courses.cs.washington.edu/courses/cse378/00au/ctomips2.pdf
# Parameters: A string address
# return: The length of the string
#
# Register Legend
#   $a0 - stores the current index of the string
#   $t0 - stores the current character
###########################################
strlen:
    li $v0, 0 # initialize the count to zero
    loop:
        lbu $t0, 0($a0) # load the next character into t0
        beqz $t0, exitstrlen # check for the null character
        addi $a0, $a0, 1 # increment the string pointer
        addi $v0, $v0, 1 # increment the count
        j loop # return to the top of the loop
    exitstrlen:
    jr $ra



###########################################
# main:
# 	Main program, gets input from user and calls levenshtein procedure
#
# Parameters: string1 and string2 addresses
# return int the levenshtein distance of the two strings
#
#
# Register Legend
#   $a0 -> Address of the first string
#   $a2 -> Address of the second string
#   $s0 -> Address of the first string
#   $s1 -> Address of the second string
#   $s2 -> length of the first string + 1
#   $s3 -> Length of the second string + 1
#   $s4 -> smallest : holds the smallest term from adjacent terms
#   $t0 -> (str1len + 1) * (str2len + 1) : used for storing array on heap
#   $t1 -> j (corresponding to columns and str1 in for loops)
#   $t2 -> i (corresponding to rows and str2 in for loops)
#   $t3 -> temp reg for address calculations
#   $t4 -> temp reg for calculating string things
#   $t5 -> temp reg for holding a character from string 2
###########################################
levenshtein:
    # Storing saved variables and $ra on the stack
    addi $sp, $sp, -24
    sw $s0, 0($sp)
    sw $s1, 4($sp)
    sw $s2, 8($sp)
    sw $s3, 12($sp)
    sw $s4, 16($sp)
    sw $ra, 20($sp)

    # Calculating the lengths of the two strings
    move $s0, $a0
    move $s1, $a1
    jal strlen
    addi $s2, $v0, 1
    move $a0, $s1
    jal strlen
    addi $s3, $v0, 1

    # Reserve space for bottom-up recursive 2d array
    mul $t0, $s2, $s3
    sub $sp, $sp, $t0

    # Initialize first row to be the number of deletions to get to the empty
    # string from string1
    li $t1, 0
    initstr1:
        bge $t1, $s2, exitinitstr1
        # j -> arr[0][j]
        add $t3, $sp, $t1
        sb $t1, 0($t3)
        addi $t1, $t1, 1
        j initstr1
    exitinitstr1:

    # Initialize first column to be the number of insertions to transform the
    # empty string to the full string2
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

    # for (i = 0; i < str2len + 1; i++)
    li $t2, 1
    str2loop:
        bge $t2, $s3, exitstr2loop

        # for (j = 0; j < str1len + 1; j++)
        li $t1, 1
        str1loop:
            bge $t1, $s2, exitstr1loop
            
            # check char at str1
            add $t3, $t1, $s0
            lb $t4, -1($t3)

            # check char at str2
            add $t3, $t2, $s1
            lb $t5, -1($t3)

            # determine if the characters match
            sub $t4, $t4, $t5
            beqz $t4, charequal 
            # characters are not equal, must perform edit distance operation

            # to get index arr[i][j],
            # i * (str1len + 1) + j

            # arr[i][j]
            mul $t3, $s2, $t2
            add $t3, $t3, $sp
            add $t3, $t3, $t1

            # arr[i-1][j]
            sub $t3, $t3, $s2
            lb $s4, 0($t3)

            # arr[i-1][j-1]            
            lb $t4, -1($t3)

            # set value if smaller
            bge $t4, $s4, skipsmallest1
            move $s4, $t4
            skipsmallest1:

            # arr[i][j-1]
            add $t3, $t3, $s2
            lb $t4, -1($t3)

            # set value if smaller
            bge $t4, $s4, skipsmallest2
            move $s4, $t4
            skipsmallest2:

            # add 1 to smallest (The replacement, insertion, or deletion
            # operation must be accounted for)
            addi $s4, $s4, 1
            # arr[i][j]
            sb $s4, 0($t3)

            j charequalexit
            charequal:
            # characters are equal, number of edits is the same as comparing
            # str1[0,j-1] -> str2[0, i-1]
            # load arr[i-1][j-1]
            mul $t3, $s2, $t2
            add $t3, $t3, $sp
            add $t3, $t3, $t1
            sub $t3, $t3, $s2
            lb $s4, -1($t3)

            # set arr[i][j]
            add $t3, $t3, $s2
            sb $s4, 0($t3)

            charequalexit:

            addi $t1, $t1, 1;
            j str1loop
        exitstr1loop:
        
        addi $t2, $t2, 1
        j str2loop

    exitstr2loop:

    # print prompt
    li $v0, 4
    la $a0, prompt3
    syscall
    li $t2, 0
    # for (i = 0; i < str2len + 1; i++)
    iloop:
        bge $t2, $s3, endiloop
        li $t1, 0
        # for (j = 0; j < str1len + 1; j++)
        jloop:
            bge $t1, $s2, endjloop
            
            # get arr[i][j]
            mul $t3, $t2, $s2
            add $t3, $t3, $sp
            add $t3, $t3, $t1

            #print arr[i][j]
            lb $a0, 0($t3)
            li $v0, 1
            syscall
            li $v0, 4
            la $a0, space
            syscall

            add $t1, $t1, 1
            j jloop
        endjloop:

        # print newline
        li $v0, 4
        la $a0, newline
        syscall

        addi $t2, $t2, 1
        j iloop
    endiloop:

    # Store last result in v0
    move $v0, $s4

    # restore stack space for 2d array
    add $sp, $sp, $t0

    # restore saved and $ra variables
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    lw $ra, 20($sp)
    addi $sp, $sp, 24

    jr $ra
