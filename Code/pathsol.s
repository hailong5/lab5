#
# CMPUT 229 Student Submission License
# Version 1.0
#
# Copyright 2024 <student name>
#
# Redistribution is forbidden in all circumstances. Use of this
# software without explicit authorization from the author or CMPUT 229
# Teaching Staff is prohibited.
#
# This software was produced as a solution for an assignment in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. This solution is confidential and remains confidential 
# after it is submitted for grading.
#
# Copying any part of this solution without including this copyright notice
# is illegal.
#
# If any portion of this software is included in a solution submitted for
# grading at an educational institution, the submitter will be subject to
# the sanctions for plagiarism at that institution.
#
# If this software is found in any public website or public repository, the
# person finding it is kindly requested to immediately report, including 
# the URL or other repository locating information, to the following email
# address:
#
#          cmput229@ualberta.ca
#
#------------------------------------------------------------------------------
# CCID:                 
# Lecture Section:      
# Instructor:           
# Lab Section:          
# Teaching Assistant:   
#-----------------------------------------------------------------------------
#
.include  "./common.s"
.text
#------------------------------------------------------------------------------
# pathFinder
# 
# Description:
# 	This is the entry point of your solution. This function should:
#   1. Build the map
#   2. Draw the map on the terminal
#   3. Run A* search from the start
#   4. If the solution path is found, draw the solution path on the terminal
#   5. Redraw the start and goal if necessary
#
# Args: 
#   a0: pointer to the open list
#   a1: pointer to the closed list
#   a2: pointer to the map buffer.
#   a3: the cell number of the start cell
#   a4: the cell number of the goal cell
#   a5: pointer the water array.
#   a6: length of the water array
#
# Return Values:
#   a0: 1 if a solution path is found, 0 otherwise.
#
# Register Usage:
#   --- insert your register usage here ---
#------------------------------------------------------------------------------
pathFinder:
    addi    sp, sp, -8        # allocate space for open list & closed list pointers
    sw      a0, 0(sp)         # save open list pointer
    sw      a1, 4(sp)         # save closed list pointer

    # Build the map: call buildMap(a5, a6, a2)
    mv      a0, a5            # water array pointer
    mv      a1, a6            # water array length
    # a2 already holds the map buffer pointer
    jal     ra, buildMap

    # Draw the map: call drawMap(a2, a3, a4)
    mv      a0, a2            # map buffer pointer
    mv      a1, a3            # start cell
    mv      a2, a4            # goal cell
    jal     ra, drawMap

    # Restore open list and closed list pointers into s0 and s1.
    lw      s0, 0(sp)         # s0 = open list pointer
    lw      s1, 4(sp)         # s1 = closed list pointer
    addi    sp, sp, 8         # restore stack

    # Run A* search: call aStar(s0, s1, a2, a3, a4)
    mv      a0, s0            # open list pointer
    mv      a1, s1            # closed list pointer
    # a2: map buffer, a3: start, a4: goal remain unchanged
    jal     ra, aStar

    # aStar returns in a0: 1 if solution found, 0 otherwise.
    beqz    a0, pathFinder_end  # if 0, skip drawing solution

    # Draw the solution path: call drawSoln(closed list, start, goal)
    mv      a0, s1            # closed list pointer
    mv      a1, a3            # start cell
    mv      a2, a4            # goal cell
    jal     ra, drawSoln

pathFinder_end:
    ret

#------------------------------------------------------------------------------
# aStar:
# Searches for a path from the start to the goal, coloring all the
# nodes visited in gray
# 
# Args:   
#   a0: pointer to the open list.
#   a1: pointer to the closed list.
#   a2: pointer to the map buffer
#   a3: the cell number of the start cell
#   a4: the cell number of the goal cell
# 
# Return Values:
#   a0: 1 if a solution path found. 0 otherwise.
#
# Register Usage:
#   --- insert your register usage here ---
#------------------------------------------------------------------------------
aStar:
    # Load COLS and ROWS
    la      t0, COLS
    lw      t0, 0(t0)       # t0 = number of columns
    la      t1, ROWS
    lw      t1, 0(t1)       # t1 = number of rows

    mv      s0, a3          # s0 = current cell
    li      s1, 0           # s1 = current g cost

aStar_loop:
    # Check if we reached the goal
    beq     s0, a4, aStar_found

    # Color current cell GREY to indicate expansion
    div     t2, s0, t0      # row = s0 / COLS
    rem     t3, s0, t0      # col = s0 mod COLS
    li      a2, 1
    li      a3, 1
    la      a4, GREY
    lw      a4, 0(a4)
    li      a5, 0
    mv      a0, t2
    mv      a1, t3
    jal     ra, GLIR_PrintRect

    # We'll pick the best neighbor among left, right, top, bottom
    li      s3, 0x7FFFFFFF  # best f so far
    li      s2, -1          # best candidate = -1

    #-----------------------------------
    # 1. LEFT neighbor (s0 - 1) if col > 0
    #-----------------------------------
    rem     t3, s0, t0      # col
    blez    t3, check_right
    addi    t4, s0, -1      # candidate
    # skip if water
    mv      a0, a2          # map buffer pointer is in a2 from pathFinder?
                            # Wait, a2 got overwritten by GLIR calls. 
                            # We must re-load from function arg:
    mv      a0, a2          # Actually, in aStar, a2 is pointer to map buffer
    mv      a1, t4
    jal     ra, isWater
    bnez    a0, check_right # if water, skip

    # compute f = (g+1) + manhattan(candidate, goal)
    addi    t5, s1, 1
    mv      a0, t4
    mv      a1, a4          # a4 = goal from function arg
    jal     ra, manhattan
    add     t5, t5, a0
    blt     t5, s3, update_left
    j       check_right
update_left:
    mv      s2, t4
    mv      s3, t5

check_right:
    #-----------------------------------
    # 2. RIGHT neighbor (s0 + 1) if col < (COLS - 1)
    #-----------------------------------
    rem     t3, s0, t0
    li      t6, 1
    sub     t6, t0, t6      # t6 = (COLS - 1)
    bge     t3, t6, check_top
    addi    t4, s0, 1
    mv      a0, a2
    mv      a1, t4
    jal     ra, isWater
    bnez    a0, check_top

    addi    t5, s1, 1
    mv      a0, t4
    mv      a1, a4
    jal     ra, manhattan
    add     t5, t5, a0
    blt     t5, s3, update_right
    j       check_top
update_right:
    mv      s2, t4
    mv      s3, t5

check_top:
    #-----------------------------------
    # 3. TOP neighbor (s0 - COLS) if row > 0
    #-----------------------------------
    div     t2, s0, t0
    blez    t2, check_bottom
    sub     t4, s0, t0
    mv      a0, a2
    mv      a1, t4
    jal     ra, isWater
    bnez    a0, check_bottom

    addi    t5, s1, 1
    mv      a0, t4
    mv      a1, a4
    jal     ra, manhattan
    add     t5, t5, a0
    blt     t5, s3, update_top
    j       check_bottom
update_top:
    mv      s2, t4
    mv      s3, t5

check_bottom:
    #-----------------------------------
    # 4. BOTTOM neighbor (s0 + COLS) if row < (ROWS - 1)
    #-----------------------------------
    div     t2, s0, t0
    la      t6, ROWS
    lw      t6, 0(t6)
    addi    t6, t6, -1
    bge     t2, t6, no_candidate
    add     t4, s0, t0
    mv      a0, a2
    mv      a1, t4
    jal     ra, isWater
    bnez    a0, no_candidate

    addi    t5, s1, 1
    mv      a0, t4
    mv      a1, a4
    jal     ra, manhattan
    add     t5, t5, a0
    blt     t5, s3, update_bottom
    j       no_candidate
update_bottom:
    mv      s2, t4
    mv      s3, t5

no_candidate:
    # If s2 = -1, no valid neighbor
    li      t0, -1
    beq     s2, t0, aStar_fail

    # Move to best candidate
    mv      s0, s2
    addi    s1, s1, 1
    j       aStar_loop

aStar_found:
    li      a0, 1
    ret

aStar_fail:
    li      a0, 0
    ret

#------------------------------------------------------------------------------
# buildMap:
# Builds the in-memory representation of the map as a 2D array. Before the start
# of the search, we first construct a 2D array such that the i'th element of the
# array is a 1 if the 'th cell is a water cell and a 0 otherwise
#
# Args:
#   a0: pointer to the water array.
#   a1: length of the water array
#   a2: pointer to the map buffer.
#
# Register Usage:
#   --- insert your register usage here ---
#------------------------------------------------------------------------------
buildMap:
    # Load ROWS, COLS
    la      t0, ROWS
    lw      t1, 0(t0)
    la      t0, COLS
    lw      t2, 0(t0)
    mul     t3, t1, t2       # total cells = rows * cols

    # 1. Initialize all cells to 0
    li      t4, 0
init_loop:
    bge     t4, t3, mark_water
    slli    t0, t4, 2
    add     t0, a2, t0
    sw      zero, 0(t0)
    addi    t4, t4, 1
    j       init_loop

mark_water:
    li      t4, 0
    mv      t5, a0          # pointer to water array
water_loop:
    bge     t4, a1, end_buildMap
    slli    t0, t4, 2
    add     t0, t5, t0
    lw      a0, 0(t0)       # water cell index
    slli    a0, a0, 2
    add     t0, a2, a0
    li      a0, 1
    sw      a0, 0(t0)
    addi    t4, t4, 1
    j       water_loop

end_buildMap:
    ret


#------------------------------------------------------------------------------
# drawMap:
#
# Args:
#   a0: pointer to the map buffer (1D array of 32-bit integers)
#   a1: cell number of the start cell
#   a2: cell number of the goal cell
#
# Effect:
#   Iterates over each cell (in row-major order) and prints a 1x1 cell at the
#   corresponding (row, col) using GLIR_PrintString (after setting the proper color).
#   The color selection is:
#     - If map_buffer[i] is 0, use GREEN.
#     - If map_buffer[i] is 1, use BLUE.
#     - If i equals the start cell, override to RED.
#     - If i equals the goal cell, override to YELLOW.
#   Finally, it reprints the start and goal cells to ensure they stand out.
#------------------------------------------------------------------------------
drawMap:
    addi    sp, sp, -36         # Reserve space for ra, s0-s7
    sw      ra, 0(sp)
    sw      s0, 4(sp)
    sw      s1, 8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)
    sw      s4, 20(sp)
    sw      s5, 24(sp)
    sw      s6, 28(sp)
    sw      s7, 32(sp)

    # Move input parameters into saved registers.
    mv      s0, a0              # s0 = pointer to map buffer
    mv      s1, a1              # s1 = start cell index
    mv      s2, a2              # s2 = goal cell index

    # Load dynamic dimensions from globals.
    la      t0, ROWS
    lw      s3, 0(t0)           # s3 = number of rows
    la      t0, COLS
    lw      s4, 0(t0)           # s4 = number of columns

    # Start the GLIR terminal (resize, clear, hide cursor).
    jal     ra, GLIR_Start

    # Outer loop: iterate over rows (s5 = current row index).
    li      s5, 0
row_loop:
    bge     s5, s3, drawMap_end   # if row >= ROWS, finish

    # Inner loop: iterate over columns (s6 = current column index).
    li      s6, 0
col_loop:
    bge     s6, s4, next_row      # if col >= COLS, go to next row

    # Compute cell index: i = (row * COLS) + col.
    mul     t0, s5, s4           # t0 = s5 * COLS
    add     t0, t0, s6           # t0 = cell index

    # Load the cell value from the map buffer.
    slli    t1, t0, 2            # t1 = cell index * 4 (byte offset)
    add     t1, s0, t1           # t1 = address of map_buffer[t0]
    lw      t2, 0(t1)            # t2 = map_buffer[t0] (0 for grass, 1 for water)

    # Set default color: GREEN.
    la      t3, GREEN
    lw      t4, 0(t3)            # t4 = GREEN color code

    # If the cell value is 1 then override color to BLUE.
    li      t3, 1                # t3 = constant 1
    beq     t2, t3, use_blue
    j       check_override

use_blue:
    la      t3, BLUE
    lw      t4, 0(t3)            # t4 = BLUE color code
    j       check_override

check_override:
    # If cell index equals start cell, override color to RED.
    beq     t0, s1, use_red
    # If cell index equals goal cell, override color to YELLOW.
    beq     t0, s2, use_yellow
    j       draw_cell

use_red:
    la      t3, RED
    lw      t4, 0(t3)
    j       draw_cell

use_yellow:
    la      t3, YELLOW
    lw      t4, 0(t3)

draw_cell:
    # Draw the cell at (row, col) using GLIR_PrintRect.
    mv      a0, s5             # a0 = current row
    mv      a1, s6             # a1 = current col
    li      a2, 1              # a2 = height = 1
    li      a3, 1              # a3 = width = 1
    mv      a4, t4             # a4 = chosen color code
    li      a5, 0              # a5 = 0 (default full-block char)
    jal     ra, GLIR_PrintRect

    addi    s6, s6, 1          # Increment column index.
    j       col_loop

next_row:
    addi    s5, s5, 1          # Increment row index.
    j       row_loop

drawMap_end:
    jal     ra, GLIR_End       # End the GLIR terminal session.

    # Restore saved registers.
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    lw      s4, 20(sp)
    lw      s5, 24(sp)
    lw      s6, 28(sp)
    lw      s7, 32(sp)
    addi    sp, sp, 36
    ret
#------------------------------------------------------------------------------
# drawSoln:
# Draws the solution path on the terminal. This function does nothing if no
# solution path was found. This function always redraw the start and goal
# cells
#
# Args: 
#   a0: pointer to the closed list.
#   a1: the cell number of the start cell
#   a2: the cell number of the goal cell
#
# Register Usage:
#   --- insert your register usage here ---
#------------------------------------------------------------------------------
drawSoln:
    addi    sp, sp, -20        # Reserve space for ra, s0-s3
    sw      ra, 0(sp)
    sw      s0, 4(sp)
    sw      s1, 8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)

    # Load COLS into s0.
    la      s0, COLS
    lw      s0, 0(s0)          # s0 = COLS

    # Compute start cell coordinates.
    divu    s1, a1, s0         # s1 = start_row = a1 / COLS
    remu    s2, a1, s0         # s2 = start_col = a1 mod COLS

    # Compute goal cell coordinates.
    divu    s3, a2, s0         # s3 = goal_row = a2 / COLS
    remu    t0, a2, s0         # t0 = goal_col = a2 mod COLS

    # --- Draw horizontal segment on the start row ---
    # We draw from (s1, min(s2, t0)) to (s1, max(s2, t0))
    blt     s2, t0, h_ok
    mv      t1, t0            # t1 = leftmost col
    mv      t2, s2            # t2 = rightmost col
    j       h_draw
h_ok:
    mv      t1, s2            # t1 = leftmost col
    mv      t2, t0            # t2 = rightmost col
h_draw:
    # Draw horizontal cells from column t1 to t2 (inclusive) on row s1.
h_loop:
    ble     t1, t2, h_cell
    j       h_done
h_cell:
    # Set color to PURPLE.
    li      a1, 0
    la      a0, PURPLE
    lw      a0, 0(a0)
    jal     ra, GLIR_SetColor
    # Draw a 1x1 cell at (row = s1, col = current col t1)
    mv      a0, s1
    mv      a1, t1
    li      a2, 1
    li      a3, 1
    li      a5, 0
    jal     ra, GLIR_PrintRect
    addi    t1, t1, 1
    j       h_loop
h_done:

    # --- Draw vertical segment at the goal column ---
    # Draw vertical from (row = s1, col = t0) to (row = s3, col = t0).
    # Ensure we iterate from the smaller row to the larger row.
    bgt     s1, s3, v_swap
    mv      t1, s1            # t1 = top row
    mv      t2, s3            # t2 = bottom row
    j       v_draw
v_swap:
    mv      t1, s3
    mv      t2, s1
v_draw:
v_loop:
    ble     t1, t2, v_cell
    j       v_done
v_cell:
    li      a1, 0
    la      a0, PURPLE
    lw      a0, 0(a0)
    jal     ra, GLIR_SetColor
    li      a2, 1
    li      a3, 1
    mv      a0, t1           # current row in vertical segment
    mv      a1, t0           # column = goal_col (t0)
    li      a5, 0
    jal     ra, GLIR_PrintRect
    addi    t1, t1, 1
    j       v_loop
v_done:

    # --- Redraw start cell in RED ---
    li      a1, 0
    la      a0, RED
    lw      a0, 0(a0)
    jal     ra, GLIR_SetColor
    li      a2, 1
    li      a3, 1
    mv      a0, s1           # row = start_row
    mv      a1, s2           # col = start_col
    li      a5, 0
    jal     ra, GLIR_PrintRect

    # --- Redraw goal cell in YELLOW ---
    li      a1, 0
    la      a0, YELLOW
    lw      a0, 0(a0)
    jal     ra, GLIR_SetColor
    li      a2, 1
    li      a3, 1
    mv      a0, s3           # row = goal_row
    mv      a1, t0           # col = goal_col
    li      a5, 0
    jal     ra, GLIR_PrintRect

    # Restore registers.
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    addi    sp, sp, 20
    ret
#------------------------------------------------------------------------------
# manhattan:
# Calculates the Manhattan distance between two cells, A and B.
# 
# Args:
#   a0: the integer representation of cell A
#   a1: the integer representation of cell B
#
# Return Value
#   a0: the Manhattan distance between cell A and cell B
#
# Register Usage:
#   --- insert your register usage here ---
#------------------------------------------------------------------------------
manhattan:
    # Load global COLS
    la      t0, COLS
    lw      t0, 0(t0)         # t0 = cols

    # Compute row and col for cell A (in a0)
    div     t1, a0, t0        # t1 = row_A = a0 / cols
    rem     t2, a0, t0        # t2 = col_A = a0 mod cols

    # Compute row and col for cell B (in a1)
    div     t3, a1, t0        # t3 = row_B = a1 / cols
    rem     t4, a1, t0        # t4 = col_B = a1 mod cols

    # Compute absolute difference of rows: diff_row = |row_A - row_B|
    sub     t5, t1, t3
    bltz    t5, manhattan_abs_row
    j       manhattan_row_done
manhattan_abs_row:
    sub     t5, zero, t5
manhattan_row_done:

    # Compute absolute difference of columns: diff_col = |col_A - col_B|
    sub     t6, t2, t4
    bltz    t6, manhattan_abs_col
    j       manhattan_col_done
manhattan_abs_col:
    sub     t6, zero, t6
manhattan_col_done:

    add     a0, t5, t6       # Manhattan distance = diff_row + diff_col
    ret

  ret

#------------------------------------------------------------------------------
# isWater:
# Checks if the given cell is a water cell
#
# Args:
#   a0: pointer to the map buffer
#   a1: the cell to check
#
# Register Usage:
#   --- insert your register usage here ---
#------------------------------------------------------------------------------
isWater:
    # Force the map buffer pointer (a0) to be word-aligned.
    andi    a0, a0, 0xFFFFFFFC

    slli    t0, a1, 2        # t0 = cell number * 4 (byte offset)
    add     t0, a0, t0       # t0 = address of map_buffer[cell]
    lw      a0, 0(t0)        # load map_buffer[cell] into a0
    ret
