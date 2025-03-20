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
# Reads and parses a input file defining a map, the start and the goal. Then
# performs A* search and visualizes the pathfinding process using GLIR.
#-------------------------------
#
.include  "./GLIR.s"
.include  "./heapq.s"

.data
fileBuffer: .space  2048
gridInfo: .space  16
water:  .space  5120
map_buffer:	.space 5120
open_list_buffer:		.space 5120
closed_list_buffer:	.space 16384
fileOpenErrStr:    .asciz "Unable to open the given file!\n"
invalidFileContentsStr: .asciz "Invalid file contents.\n"
buildMapStr:  .asciz  "buildMap - "
isWaterStr: .asciz  "isWater - "
manhattanStr: .asciz  "manhattan - "
almostThereStr: .asciz "[ ] Almost there!\n"
niceJobStr: .asciz  "[x] Nice Job!\n"
solnFoundStr: .asciz  "Solution path found!\n"
solnNotFoundStr:  .asciz "Solution path not found.\n"
invalidRetValueStr: .asciz "Invalid return value from pathFinder.\n"
noArgStr:	.asciz "\nPlease provide path to input file.\n"

.align 2
ROWS:   .word 0
COLS:   .word 0
GREEN:  .word 10
BLUE:   .word 14
YELLOW: .word 11
RED:    .word 9
GREY:   .word 8
PURPLE: .word 13
numWater: .word 0
ter_width:  .word 32
ter_height: .word 32
test_map_buffer:  .space 64
test_map_soln:  .word 0, 0, 0, 0, 1
                      1, 1, 1, 1, 1
                      1, 0, 0, 0, 0
test_water: .word 5, 6, 7, 8, 9, 4, 10
test_water_length:  .word 7

.text
main:
  # Save the address of the program argument
  mv    s0, a1

# Check student's buildMap function
checkBuildMap:
  li    a7, 4
  la    a0, buildMapStr
  ecall

  # Set a map with three rows and five columns
  li    t0, 3
  sw    t0, ROWS, t1
  li    t1, 5
  sw    t0, COLS, t1

  # Call student's buildMap
  la    a0, test_water
  lw    a1, test_water_length
  la    a2, test_map_buffer
  jal   buildMap

  # Loop through each cell to see if student's map matches the solution
  la    a0, test_map_buffer
  la    a1, test_map_soln
  li    t2, 15
  slli  t2, t2, 2
  add   t2, t2, a0

checkBuildMapLoop:
  lw    t0, 0(a0)
  lw    t1, 0(a1)
  bne   t0, t1, checkBuildMapFail
  addi  a0, a0, 4
  addi  a1, a1, 4
  blt   a0, t2, checkBuildMapLoop

checkBuildMapSuccess:
  jal   niceJob
  j     checkIsWater

checkBuildMapFail:
  jal   almostThere

# Check student's isWater function
checkIsWater:
  li    a7, 4
  la    a0, isWaterStr
  ecall

  # Check cell 0, which is not a water cell
  la    t0, test_map_soln
  lw    t1, 0(t0)
  bnez  t1, checkIsWaterFail

  # Check cell 4, which is a water cell
  lw    t1, 16(t0)
  li    t2, 1
  bne   t1, t2, checkIsWaterFail

checkIsWaterSuccess:
  jal   niceJob
  j     checkManhattan

checkIsWaterFail:
  jal   almostThere

# Check student's manhattan function
checkManhattan:
  li    a7, 4
  la    a0, manhattanStr
  ecall

  # Calculate the Manhattan distance between cells 0 and 14 on a map with 3 rows
  # and 5 columns
  li    a0, 0
  li    a1, 14
  jal   manhattan

  li    t0, 6
  bne   t0, a0, checkManhattanFail

checkManhattanSuccess:
  jal   niceJob
  j     readMapSpec

checkManhattanFail:
  jal   almostThere

# Read the map specification from the file specified by the program argument
readMapSpec:
  # Print the program argument
  # li    a7, 4
  # lw    a0, 0(s0)
  # ecall

  # li    a7, 11
  # li    a0, 10
  # ecall

  #  Print error message if no program argument was provided
  beqz s0, noArg

  # Open the file with path specified by the program argument
  li    a7, 1024
  lw    a0, 0(s0)
  li    a1, 0
  ecall

  # Check that we have open the file without errors
  blez  a0, fileOpenError

  # Read the file content into a buffer
  li    a7, 63
  la    a1, fileBuffer
  li    a2, 2048
  ecall

  # Close the file
  li    a7, 57
  ecall

  # Kill '\r'
  la		a0, fileBuffer
  jal	_kill_cr

  # Print the content of the file
  # li    a7, 4
  # la    a0, fileBuffer
  # ecall

  la    s0, fileBuffer
  li    s1, 10      # s1 <- ASCII for newline
  li    s2, 32      # s2 <- ASCII for whitespace
  li    s3, 2       # s3 <- Stopping condition for readInfoLoop
  li    s4, 0       # s4 <- What we have read so far in ASCII representation
  la    s5, gridInfo  # s5 <- the address of the array used to store information about the cell
  addi  s6, s5, 8   # s6 <- where the pointer of gridInfo should be after reading the rows and the column
  li    s8, 0       # line <- 0
  li    s9, 2       # s9 <- minimum number of rows and columns
  li    s10, 32     # s10 <- maximum number of rows and columns

# Read rows, columns, start and goal from the input file
readInfoLoop:
  lb    s7, 0(s0)

  # We have reached the end of the file too early
  beqz  s7, invalidFileContent

  # If the character we read is a whitespace or a newline, we can convert
  # what we read so far into an interger and store it appropriately
  beq   s7, s1, _callstrToInt
  beq   s7, s2, _callstrToInt
  slli  s4, s4, 8
  add   s4, s7, s4
  j     _readInfoLoopNext

_callstrToInt:
  mv    a0, s4
  jal   strToInt
  mv    s4, zero

_checkValidInput:
  # Check 2 <= rows, cols <= 32
  # OR
  # Check 0 <= start, goal <= rows * cols
  blt   a0, s9, invalidFileContent
  bgt   a0, s10, invalidFileContent

_storeToGridInfo:
  sw    a0, 0(s5)
  addi  s5, s5, 4

_checkFileContent:
  bne   s7, s1, _readInfoLoopNext
  bne   s5, s6, invalidFileContent
  j     _readNextLine

_readInfoLoopNext:
  addi  s0, s0, 1   # increment file buffer pointer
  j     readInfoLoop

_readNextLine:
  addi  s8, s8, 1   # line++
  addi  s0, s0, 1   # increment file buffer pointer
  beq   s8, s3, checkSameStartGoal  # break if line == 2
  addi  s6, s6, 8   # s6 <- where the pointer of gridInfo should be after reading the start and the goal
  li    s9, 0       # s9 <- Smallest possible integer representation
  lw    t0, -8(s5)  # load rows into t0
  lw    t1, -4(s5)  # load cols into t1
  mul   s10, t0, t1
  addi  s10, s10, -1 # s10 <- largest possible integer representation
  j     readInfoLoop    # Continue if line < 2

# Checks if the start cell is the same as the goal cell
checkSameStartGoal:
  la    t0, gridInfo
  lw    s8, 8(t0)
  lw    s11, 12(t0)
  beq   s8, s11, invalidFileContent
readWaterLoopSetup:
  la    s5, water
  mv    s6, s5
  li    s4, 0

readWaterLoop:
  lb    s7, 0(s0)

  # We have reached the end of the file
  beqz  s7, _readWaterLoopExit

  # If the character we read is a whitespace or a null, we can convert
  # what we read so far into an interger and store it appropriately
  beq   s7, s1, _callstrToInt1
  beq   s7, s2, _callstrToInt1
  slli  s4, s4, 8
  add   s4, s7, s4
  j     _readWaterLoopNext

_callstrToInt1:
  beqz  s4, _readWaterLoopNext
  mv    a0, s4
  jal   strToInt
  mv    s4, zero

_checkValidInput1:
  # Check 0 <= water <= rows * cols
  blt   a0, s9, invalidFileContent
  bgt   a0, s10, invalidFileContent

  # Check whether water == start or water == goal
  beq   a0, s8, invalidFileContent
  beq   a0, s11, invalidFileContent

_storeToGridInfo1:
  sw    a0, 0(s5)
  addi  s5, s5, 4

  beqz  s7, _readWaterLoopExit

_readWaterLoopNext:
  addi  s0, s0, 1
  j     readWaterLoop

_readWaterLoopExit:
  sub   t0, s5, s6
  srli  t0, t0, 2
  addi  s10, s10, -1
  bgt  t0, s10, invalidFileContent
  sw    t0, numWater, t1

  # Provide rows and columns as global variables to the students
  la    s0, gridInfo
  lw    t1, 0(s0)
  sw    t1, ROWS, t2
  lw    t1, 4(s0)
  sw    t1, COLS, t2

  # Start the GLIR terminal
  lw    a0, ROWS
  lw    a1, COLS
  jal   GLIR_Start

  # Call the student's solution
  la    a0, open_list_buffer
  la    a1, closed_list_buffer
  la    a2, map_buffer
  lw    a3, 8(s0)
  lw    a4, 12(s0)
  la    a5, water
  lw    a6, numWater
  jal   pathFinder

  # Save the return argument from pathFinder
  mv    s0, a0

  # End the GLIR terminal
  jal   GLIR_End

  # Print solution found or solution not found depending on the return value
  # from pathFinder
  beqz  s0, printSolnNotFound
  li    t0, 1
  beq   s0, t0, printSolnFound

invalidRetValue:
  li    a7, 4
  la    a0, invalidRetValueStr
  ecall
  j     jumpToExit

printSolnFound:
  li    a7, 4
  la    a0, solnFoundStr
  ecall
  j     jumpToExit

printSolnNotFound:
  li    a7, 4
  la    a0, solnNotFoundStr
  ecall
jumpToExit:
  j     exit
#----------------------------------------------------------------------------------------------
# strToInt
# Parses an ascii string representing an interger into that integer. Note that instead of a
# string, this function takes in the bytes representing the integer stored in a register. As
# such only 4 digit numbers maybe parsed using this function.
#
# Inputs:
#    a0: The ascii representation of the number
#
# Returns:
#     a0: The parsed integer.
#----------------------------------------------------------------------------------------------
strToInt:
    li    a1, 0            # Used to store intermediate results.
    li    t0, 0            # Amount of bits to shift right.
    li    t1, 1            # Used to store the place value of our current digit.
    li    t2, 24            # Used to store the constant 24
    li    t3, 10            # Used to store the constant 10
    li    t4, 0xFF        # Bitmask to extract the lower 8 bits.

_strToIntLoop:
    srl    t6, a0, t0        # t6 <- a0 shifted by number of bits required to get the next 8 bits to the lower
                    # part of the register.
    and    t5, t6, t4        # t5 <- Lower 8 bits of t6
    beqz    t5, _strToIntLoopEnd    # No more ascii representation of digits to convert.
    addi    t5, t5, -48        # Adjustment for ascii to integer values.
    mul    t5, t5, t1        # Multiply the number we just parsed by its placeholder value in the number.
    add    a1, a1, t5        # Add the number we just parsed to our intermediate result.

    addi    t0, t0, 8        # Increment the number of shift to get the next ascii character.
    mul    t1, t1, t3        # Multiply our current placeholder value by 10 for the next iteration.
    ble    t0, t2, _strToIntLoop    # Ensures that we run the loop at most 4 times. An ascii character takes 1 byte and since a word is
                    # 4 bytes, we can have at most 4 characters in a register.

_strToIntLoopEnd:
    mv    a0, a1
    ret

# -----------------------------------------------------------------------------
# kill_cr:
#
# Convert DOS-style line terminators to UNIX-style ones. The conversion is
# performed in place.
#
# Args:
#   a0: Pointer to a string
#
# Register Usage:
#	t0: Copy-to pointer
#	t1: Loader char
#	t6: 0x0d (for comparison)
# -----------------------------------------------------------------------------
_kill_cr:
  mv      t0, a0
  addi    t6, zero, 0x0d          # t6 <- '\r'
_kill_cr_loop:
  lbu     t1, 0(a0)               # Read the next character
  sb      t1, 0(t0)               # Copy the charcater
  beqz    t1, _kill_cr_exit       # Exit if 0x00
  addi    a0, a0, 1               # Move to the next character
  beq     t1, t6, _kill_cr_loop
  addi    t0, t0, 1               # Skip the '\r'
  j       _kill_cr_loop
_kill_cr_exit:
  ret

noArg:
	la	a0, noArgStr
	li	a7,4
	ecall
	j		exit

invalidFileContent:
    la    a0, invalidFileContentsStr
    li    a7, 4
    ecall
    j    exit

fileOpenError:
    la    a0, fileOpenErrStr
    li    a7, 4
    ecall

exit:
    li    a7, 10
    ecall

almostThere:
  addi  sp, sp, -4
  sw    ra, 0(sp)

  la    a0, almostThereStr
  jal   printTestResult

  lw    ra, 0(sp)
  addi  sp, sp, 4
  ret

niceJob:
  addi  sp, sp, -4
  sw    ra, 0(sp)

  la    a0, niceJobStr
  jal   printTestResult

  lw    ra, 0(sp)
  addi  sp, sp, 4
  ret

printTestResult:
    addi sp, sp, -4
    sw ra, 0(sp)

    li a7, 4
    ecall

    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra
