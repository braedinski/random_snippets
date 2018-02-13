#
# linked_list.asm
# @braedinski / Braeden Thomas Lynden
#
# Please enter some items into the list, terminate the procedure by specifying -1 at the terminal
# (1,2,3,-1)
#
# Printing...
# (1,2,3)
#
# There are currently 3 items in the list
# (4,5,6,7,-1)
#
# Printing...
# (1,2,3,4,5,6,7)
#
# There are currently 7 items in the list
#
#
    .data
list:               .word   0
msg_length_start:   .asciiz "\nThere are currently "
msg_length_end:     .asciiz " items in the list\n\n"
msg_display:        .asciiz "\nPrinting...\n"
msg_input:          .asciiz "\nPlease enter some items into the list, terminate the procedure by specifying -1 at the terminal\n\n"
msg_delete:         .asciiz "Which index of the linked list did you want to delete? (e.g. 0, 1, 2)\n"
msg_menu:           .asciiz "\n\nOptions\n\n1) Insert\n2) Display\n3) Delete\n4) Display Count\n5) Exit\n\n"

    .text
    .globl main
main:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)

    li      $v0, 9
    li      $a0, 8              # We allocate the integer value and the ptr to the next record.
    syscall

    sw      $v0, list

menu:
    la      $a0, msg_menu
    li      $v0, 4
    syscall

    li      $t0, 0
    li      $v0, 5
    syscall

    bgt     $v0, 5, menu
    blt     $v0, 1, menu

    beq     $v0, 1, menu_store
    beq     $v0, 2, menu_display
    beq     $v0, 3, menu_delete
    beq     $v0, 4, menu_length
    beq     $v0, 5, exit

    j       menu

menu_store:
    la      $a0, msg_input
    li      $v0, 4
    syscall

menu_store_loop:
    lw      $a0, list
    jal     store
    nop

    bne     $v0, -1, menu_store_loop

    j       menu

menu_display:
    la      $a0, msg_display
    li      $v0, 4
    syscall

    lw      $a0, list
    jal     display
    nop

    j       menu

menu_length:
    la      $a0, msg_length_start
    li      $v0, 4
    syscall

    lw      $a0, list
    jal     length
    nop

    add     $a0, $zero, $v0
    li      $v0, 1
    syscall

    la      $a0, msg_length_end
    li      $v0, 4
    syscall

    j       menu

menu_delete:
    la      $a0, msg_delete
    li      $v0, 4
    syscall

    li      $v0, 5
    syscall

    add     $a1, $zero, $v0

    lw      $a0, list
    jal     delete
    nop

    j       menu

store:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)

    add     $t0, $zero, $a0

store_loop:
    beqz    $t0, store_add      # while ( current != nullptr );
    lw      $t1, 4($t0)

    add     $t2, $zero, $t0     # This is the previous record that wasn't nullptr.
    add     $t0, $zero, $t1     # current = current->next;
    j       store_loop

store_add:
    li      $v0, 5
    syscall

    beq     $v0, -1, store_exit

    sw      $v0, 0($t2)

    li      $v0, 9
    li      $a0, 8
    syscall

    sw      $v0, 4($t2)         # previous->next = current;

store_exit:
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra
    nop

display:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)

    add     $t0, $zero, $a0

display_loop:
    beqz    $t0, display_exit

    lw      $t1, 0($t0)
    lw      $t2, 4($t0)

    beqz    $t2, display_exit

    add     $t0, $zero, $t2

    li      $v0, 1
    add     $a0, $zero, $t1
    syscall

    li      $v0, 11
    li      $a0, 0xa
    syscall

    j       display_loop

display_exit:
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra
    nop

length:
    sub     $sp, $sp, 8
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)

    add     $t0, $zero, $a0     # $a0 is the address of the head
    xor     $s0, $s0, $s0

length_loop:
    beqz    $t0, length_exit
    lw      $t1, 4($t0)

    beqz    $t1, length_exit

    add     $t0, $zero, $t1
    addi    $s0, $s0, 1         # total++;

    j       length_loop

length_exit:
    add     $v0, $zero, $s0

    lw      $s0, 4($sp)
    lw      $ra, 0($sp)
    add     $sp, $sp, 8

    jr      $ra

delete:
    sub     $sp, $sp, 8
    sw      $ra, 0($sp)
    sw      $s0, 4($sp)
    
    add     $t0, $zero, $a0
    xor     $s0, $s0, $s0       # index = 0;

delete_loop:
    add     $t3, $s0, 1
    bne     $t3, $a1, delete_loop_main
    add     $t2, $zero, $t0     # if ( index + 1 == search_index )

delete_loop_main:
    beqz    $t0, delete_exit    # if ( current == nullptr ) goto exit;

    lw      $t1, 4($t0)         # unsigned long *next = current->next

    beq     $s0, $a1, delete_reorder

    add     $t0, $zero, $t1     # current = next;
    add     $s0, $s0, 1         # index++;

    j       delete_loop


delete_reorder:
    sw      $t1, 4($t2)
    sw      $zero, 0($t0)
    sw      $zero, 4($t0)

delete_exit:
    lw      $s0, 4($sp)
    lw      $ra, 0($sp)
    add     $sp, $sp, 8
    jr      $ra


exit:
    lw      $ra, 0($sp)
    addi    $sp, $sp, 4

    jr      $ra
