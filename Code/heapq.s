#
# CMPUT 229 Public Materials License
# Version 1.0
#
# Copyright 2024 University of Alberta
# Copyright 2024 Zhao Yu Li
#
# This software is distributed to students in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the disclaimer below in the documentation
#    and/or other materials provided with the distribution.
#
# 2. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#-------------------------------
# Lab - PathFinder
#
# Author: Zhao Yu Li
# Date: July 16, 2024
#
# This file contains the RISC-V assembly implementation of different heap
# operations.
#-------------------------------
#
#------------------------------------------------------------------------------
# Lab_PathFinder
#
# Oringal C source code from: https://www.programiz.com/dsa/priority-queue
# Compiled into RISC-V 32 bit using Compiler Explorer (https://godbolt.org/) using RISC-V rv32gc clang 18.1.0 with the -O1 compiler option
# Modified by: Zhao Yu Li
# Date : June 7, 2024
#
#------------------------------------------------------------------------------
.data
SIZE:   .word 0

.text
#------------------------------------------------------------------------------
# heapify:
# Ensures the subtree given by the i'th element in the open list and its
# childrens (if any) satisfies the heap property. If subtree already satisfies
# the heap property, this function does nothing. Otherwise, the function swaps
# the i'th element and the smallest element in the open list in-place, then
# recursively calls itself to ensure what once was the i'th element in the open
# list now satisfies the heap property in its new position.
#
# Args:
#   a0: pointer to the open list
#   a1: pointer to the closed list
#   a2: the number of elements in the open list
#   a3: i, the index of the element in the open list for which we check whether
#       it satisfies the heap property.
#
# Register usage:
#   a4: smallestElemIndex
#   a5-a7: various intermediate calculations
#   t0-t4: various intermediate calculations
#------------------------------------------------------------------------------
heapify:
        li      a6, 1
        li      a7, 12
        beq     a2, a6, heapifyExit
heapifyStart:
# --- insert your solution below this line ---
        slli    t0, a3, 2
        add     t0, t0, a0
        lw      t1, 0(t0)       # t1 <- smallestElem
        mul     a4, t1, a7
        add     a4, a4, a1
        lw      t2, 4(a4)       # t2 <- smallestElem.g
        lw      a5, 8(a4)       # a5 <- smallestElem.h
        slli    t4, a3, 1
        addi    a4, t4, 1       # a4 <- 2 * i + 1 (leftChildIndex)
        add     t2, t2, a5      # t2 <- smallestElem.f

        # Additionally compares the h values if the f values are equal
        # The cell with the smaller h value will have a higher priority
        slli    t2, t2, 16
        add     t2, t2, a5

        # if leftChildIndex >= SIZE. skip checking left child
        bge     a4, a2, .LBB1_5

        slli    a5, a4, 2
        add     a5, a5, a0
        lw      a5, 0(a5)       # a5 <- leftChild
        mul     a5, a5, a7
        add     a5, a5, a1
        lw      t3, 4(a5)       # t3 <- leftChild.g
        lw      a5, 8(a5)       # a5 <- leftChild.h
        add     t3, t3, a5      # t3 <- leftChild.f

        # Additionally compares the h values if the f values are equal
        # The cell with the smaller h value will have a higher priority
        slli    t3, t3, 16
        add     t3, t3, a5

        # if leftChild.f < smallestElem.f jump to .LBB1_4
        blt     t3, t2, .LBB1_4

        # else
        mv      t3, t2          # t3 <- smallestElem.f
        mv      a4, a3          # smallestElemIndex <- i
.LBB1_4:
        mv      t2, t3          # t2 <- leftChild.f
        addi    t4, t4, 2       # t4 <- rightChildIndex

        # if rightChildIndex < SIZE check right child
        blt     t4, a2, .LBB1_6

        # else check whether we need to continue heapifying
        j       checkRootSmallest

.LBB1_5:
        mv      a4, a3          # smallestElemIndex <- i
        addi    t4, t4, 2       # t4 <- rightChildIndex

        #  if rightChildIndex >= SIZE. skip checking right child
        bge     t4, a2, checkRootSmallest

.LBB1_6:
        slli    a5, t4, 2
        add     a5, a5, a0
        lw      a5, 0(a5)       # a5 <- rightChild
        mul     a5, a5, a7
        add     a5, a5, a1
        lw      t3, 4(a5)       # t3 <- rightChild.g
        lw      a5, 8(a5)       # a5 <- rightChild.h
        add     t3, a5, t3      # a5 <- rightChild.f

        # Additionally compares the h values if the f values are equal
        # The cell with the smaller h value will have a higher priority
        slli    t3, t3, 16
        add     a5, t3, a5

        # if rightChild.f < smallestElem.f update smallestElem
        blt     a5, t2, .LBB1_8

        # else
        mv      t4, a4          # t4 <- smallestElemIndex
.LBB1_8:
        mv      a4, t4          # smallestElemIndex <- rightChildIndex

# --- insert your solution above this line ---
checkRootSmallest:
        # if i == smallestElemIndex return
        beq     a4, a3, heapifyExit

        slli    t0, a3, 2
        add     t0, t0, a0
        lw      t1, 0(t0)   # t1 <- openList[i]
        slli    a3, a4, 2
        add     a3, a3, a0
        lw      a5, 0(a3)   # a5 <- openList[smallestElemIndex]

        # swap openList[i] and openList[smallestElemIndex]
        sw      t1, 0(a3)
        sw      a5, 0(t0)

        # Asumming that the values in register a0, a1, and a2 were not
        # overwritten, we can can simply do i <- smallestElemIndex ...
        mv      a3, a4

        # and go back to heapifyStart
        # This is equivalent to
        # Heapify(openList, closedList, size, smallestElemIndex)
        bne     a2, a6, heapifyStart
heapifyExit:
        ret

#------------------------------------------------------------------------------
# insert
# Inserts the grid with integer representation given by a2. Maintains the heap
# property based on the f values of the grids.
#
# Args:
#   a0: pointer to the open list
#   a1: pointer to the closed list
#   a2: the cell number of the cell to insert
#
# Register Usage:
#   s0: stores a0
#   s1: i
#   s2: stores a1
#   s3: upper 20 bits of the address of the label SIZE. Used to load the value
#       of SIZE more efficiently
#   s4: a constant used in the loop condition
#------------------------------------------------------------------------------
insert:
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)
        sw      s4, 8(sp)
        lui     a3, %hi(SIZE)
        lw      a4, %lo(SIZE)(a3)   # a4 <- SIZE
        mv      s0, a0

        # if SIZE == 0 simply insert the element and return
        beqz    a4, .LBB2_4
        mv      s2, a1
        slli    a4, a4, 2
        add     a4, a4, s0
        sw      a2, 0(a4)           # openList[SIZE] <- a2
        lw      a1, %lo(SIZE)(a3)
        addi    a0, a1, 1           # SIZE++
        sw      a0, SIZE, t0

        # if SIZE <= 0 return
        blez    a1, .LBB2_5
        srli    a0, a0, 1
        addi    s1, a0, 1           # i <- SIZE / 2 + 1
        lui     s3, %hi(SIZE)
        li      s4, 1               # s4 <- 1
.LBB2_3:
        lw      a2, %lo(SIZE)(s3)
        addi    a3, s1, -2
        mv      a0, s0
        mv      a1, s2
        call    heapify             # heapify(openList, closedList, SIZE, i - 2)
        addi    s1, s1, -1          # i--
        blt     s4, s1, .LBB2_3     # continue looping if i > 1
        j       .LBB2_5
.LBB2_4:
        sw      a2, 0(s0)           # openList[0] <- a2
        lw      a0, %lo(SIZE)(a3)
        addi    a0, a0, 1           # SIZE++
        sw      a0, SIZE, t0
.LBB2_5:
        lw      ra, 28(sp)
        lw      s0, 24(sp)
        lw      s1, 20(sp)
        lw      s2, 16(sp)
        lw      s3, 12(sp)
        lw      s4, 8(sp)
        addi    sp, sp, 32
        ret

#------------------------------------------------------------------------------
# popMin:
# Removes the grid with the least f value from the open list and returns its
# integer representation. Maintains the heap property based on the f values of
# the grids.
#
# Args:
#   a0: pointer to the open list
#   a1: pointer to the closed list
#
# Return:
#   a0: The cell number of the cell with the least f value in the
#       open list
#
# Register Usage:
#   s0: stores a0
#   s1: i
#   s2: stores the upper 20 bits of the address of the label SIZE. Used to load
#       the value of SIZE efficiently
#   s3: stores a1
#   s4: a constant used in the loop condition
#   s5: stores the grid with the least f value temporarily before moving it to
#       a0 as the return value
#------------------------------------------------------------------------------
popMin:
        addi    sp, sp, -36
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)
        sw      s4, 8(sp)
        sw      s5, 32(sp)

        lui     s2, %hi(SIZE)
        lw      a2, %lo(SIZE)(s2)   # a2 <- SIZE
        mv      s0, a0
        slli    a2, a2, 2
        add     a2, a2, a0
        lw      a0, 0(a0)           # a0 <- openList[0]
        mv      s5, a0              # s5 <- openList[0]
        lw      a3, -4(a2)          # a3 <- openList[SIZE - 1]
        sw      a0, -4(a2)          # openList[SIZE - 1] <- a0
        sw      a3, 0(s0)           # openList[0] <- a3
        lw      a2, %lo(SIZE)(s2)   # a2 <- SIZE
        mv      s3, a1
        addi    a0, a2, -1          # SIZE -= 1
        li      a1, 3
        sw      a0, SIZE, t0

        # if SIZE before modification is less than 3, then it would be less than
        # 2 after modification. In this case, there is no need to heapufy
        blt     a2, a1, .LBB3_3
        srli    a1, a0, 31
        add     a0, a0, a1
        srai    a0, a0, 1
        addi    s1, a0, 1           # i <- SIZE /2 + 1
        li      s4, 1               # s4 <- 1
.LBB3_2:
        lw      a2, %lo(SIZE)(s2)
        addi    a3, s1, -2
        mv      a0, s0
        mv      a1, s3
        call    heapify             # heapify(openList, closedList, SIZE, i - 2)
        addi    s1, s1, -1          # i--
        blt     s4, s1, .LBB3_2     # continue looping if i > 1
.LBB3_3:
        mv      a0, s5              # return the smallest element
        lw      ra, 28(sp)
        lw      s0, 24(sp)
        lw      s1, 20(sp)
        lw      s2, 16(sp)
        lw      s3, 12(sp)
        lw      s4, 8(sp)
        lw      s5, 32(sp)
        addi    sp, sp, 36
        ret

#------------------------------------------------------------------------------
# minHeap:
#`Transforms the array given by a1 into a heap in place based on the f values
# of the grids.
#
# Args:
#   a0: pointer to the open list
#   a1: pointer to the closed list
#
# Register Usage:
#   s0: i
#   s1: stores a0
#   s2: stores the upper 32 bits of the address of the label SIZE. Used to load
#       the value of SIZE efficiently
#   s3: stores a1
#   s4: a constant used in the loop condition
#------------------------------------------------------------------------------
minHeap:
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)
        sw      s3, 12(sp)
        sw      s4, 8(sp)
        lui     s2, %hi(SIZE)
        lw      a3, %lo(SIZE)(s2)
        mv      s3, a1
        mv      s1, a0

        lw      a0, %lo(SIZE)(s2)   # a0 <- SIZE
        li      a1, 2
        blt     a0, a1, .LBB0_8     # if SIZE < 2 then we don't need to heapify
        srli    a0, a0, 1
        addi    s0, a0, 1           # i <- SIZE / 2 + 1
        lui     s2, %hi(SIZE)
        li      s4, 1               # s4 <- 1
.LBB0_7:
        lw      a2, %lo(SIZE)(s2)
        addi    a3, s0, -2
        mv      a0, s1
        mv      a1, s3
        call    heapify             # heapify(openList, closedList, SIZE, i - 2)
        addi    s0, s0, -1          # i--
        blt     s4, s0, .LBB0_7     # continue looping if i > 1
.LBB0_8:
        lw      ra, 28(sp)
        lw      s0, 24(sp)
        lw      s1, 20(sp)
        lw      s2, 16(sp)
        lw      s3, 12(sp)
        lw      s4, 8(sp)
        addi    sp, sp, 32
        ret
