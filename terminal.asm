#
# task_2.s
# This program uses device I/O registers to read/write data from/to the terminal.
# The 'write' procedure is a generic implementation of syscall #4 (print_str)
# The 'bin_to_ascii' procedure converts decimal to ASCII for writing to the terminal.
#
    .data
    .align 2

buffer:         .space 16       # 16 bytes of space (word-boundary aligned)
output_buffer:  .space 32
size:           .word  16
delimiter:      .ascii "."
msg_input:      .asciiz "Input: "
msg_num_chars:  .asciiz "\t\tCount: "
msg_exiting:    .asciiz "Terminating...\n"
newline:        .asciiz "\n"

    .text
    .globl main

main:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)

    li      $s0, 0xffff     # $t0 = 0x0000ffff
    sll     $s0, $s0, 16    # $t0 = 0xffff0000

main_loop:
    add     $a0, $zero, $s0 # (io_address) 0xffff0000
    la      $a1, buffer     # (buffer)
    lw      $a2, size       # (size)

    jal     read            # read(io_address, buffer, size);
    nop

    add     $s1, $zero, $v1 # hard_exit ?
    add     $s2, $zero, $v0 # chars;

    beq    $s2, $zero, no_input_exit

# "Output: "
    add     $a0, $zero, $s0
    la      $a1, msg_input
    li      $a2, 8

    jal     write
    nop

# "{stdin}"
    add     $a0, $zero, $s0
    la      $a1, buffer
    add     $a2, $zero, $v0 # The number of chars we read returned by 'read' in $v0

    jal     write           # write(io_address, buffer, size);
    nop

# "Count: "
    add     $a0, $zero, $s0
    la      $a1, msg_num_chars
    addiu   $a2, $zero, 8

    jal     write           # write(io_address, buffer, size);
    nop

    add     $a0, $zero, $s2
    la      $a1, output_buffer

# bin_to_ascii
    jal     bin_to_ascii
    nop

# "{count}"
    add     $a0, $zero, $s0
    la      $a1, output_buffer
    addu    $a2, $zero, $v0

    jal     write           # write(io_address, buffer, size);
    nop

    #beq     $s1, 1, hard_exit
    #nop

# "\n"
    add     $a0, $zero, $s0
    la      $a1, newline
    addiu   $a2, 2

    jal     write           # write(io_address, buffer, size);
    nop

    j       main_loop

hard_exit:
    j       exit

no_input_exit:
    add     $a0, $zero, $s0
    la      $a1, msg_exiting
    addiu   $a2, $zero, 16

    jal     write           # write(io_address, buffer, size);
    nop

    j       exit

read:
    sub     $sp, $sp, 8
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)     # We need to store $s0 on the stack because it's callee save.

    li      $t0, 0          # We reset the 'chars' counter to zero.
    la      $t1, buffer
    lbu     $t2, delimiter  # If this char is encountered, we exit()
    addu    $t3, $zero, $a1 # We make a copy of the ptr to 'buffer'

read_loop:
    lw      $t4, 0($a0)
    andi    $t4, $t4, 0x0000001
    beq     $t4, $zero, read_loop

    lw      $t4, 4($a0)
    sb      $t4, 0($t3)     # buffer[idx++] = $t4

    beq     $t4, $t2, read_hard_exit

    addiu   $t3, $t3, 1
    addiu   $t0, $t0, 1

    beq     $t0, $a2, read_exit
    bne     $t0, $a1, read_loop

read_exit:
    add     $v0, $zero, $t0 # The number of chars read or exit (-1)

    lw      $s0, 4($sp)
    lw      $ra, 0($sp)

    addiu   $sp, $sp, 8

    jr      $ra
    nop

read_hard_exit:
    addi   $v1, $zero, 1  # The user wants to quit the program.
    j      read_exit

write:
    sub     $sp, $sp, 12
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    sw      $s1, 8($sp)

    li      $t0, 0
    addu    $t1, $zero, $a1

write_loop:
    lw      $t2, 8($a0)             # Is device ready?
    andi    $t2, $t2, 0x00000001    # ...
    beq     $t2, $zero, write_loop  # Not ready, poll.

    lbu     $t3, 0($t1)             # load that character into $s0
    addiu   $t1, $t1, 1             # buffer + offset

    sw      $t3, 12($a0)            # save $s0 to data register

    addiu   $t0, $t0, 1             # increment counter
    bne     $t0, $a2, write_loop    # loop it.

write_exit:
    lw      $s1, 8($sp)
    lw      $s0, 4($sp)
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 12

    jr      $ra
    nop

bin_to_ascii:                       # bin_to_ascii(number, output_buffer) : ascii = $v0
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)

    add     $t0, $zero, $a0
    add     $t1, $zero, $a1
    li      $t3, 0

bin_to_ascii_loop:                  # bin_to_ascii_loop()
    div     $t0, $t0, 10

    mfhi    $t2
    addiu   $t2, $t2, 0x30          # [0x30 - 0x39] = 0 - 9

    sub     $sp, $sp, 1
    sb      $t2, 0($sp)

    addiu   $t3, $t3, 1             # We'll pop off the stack to reverse.
    addiu   $t1, $t1, 1

    bgt     $t0, $zero, bin_to_ascii_loop

    sub     $t1, $t1, $t3
    add     $v0, $zero, $t3

bin_to_ascii_reverse:
    beq     $t3, $zero, bin_to_ascii_exit

    lb      $t4, 0($sp)
    sb      $t4, 0($t1)

    addiu   $sp, $sp, 1
    addiu   $t1, $t1, 1
    sub     $t3, $t3, 1
    j       bin_to_ascii_reverse

bin_to_ascii_exit:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4

    jr      $ra
    nop

exit:
    lw      $ra, 0($sp)
    addiu   $sp, $sp, 4
    jr      $ra
    nop
