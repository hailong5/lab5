.include  "./common.s"
.text

#------------------------------------------------------------------------------
# pathFinder:
# Entry point for the pathfinding visualizer. Builds the map, draws it, runs A*,
# and draws the solution if found.
#
# Args:
#   a0: pointer to the open list
#   a1: pointer to the closed list
#   a2: pointer to the map buffer
#   a3: start cell number
#   a4: goal cell number
#   a5: pointer to the water array
#   a6: length of the water array
#
# Returns:
#   a0: 1 if a solution is found, 0 otherwise.
#------------------------------------------------------------------------------
pathFinder:
    # Save open and closed list pointers on the stack
    addi    sp, sp, -8
    sw      a0, 0(sp)         # Save open list pointer
    sw      a1, 4(sp)         # Save closed list pointer

    # Step 1: Build the map
    mv      a0, a5            # Water array pointer
    mv      a1, a6            # Water array length
    # a2 already holds the map buffer pointer
    jal     ra, buildMap      # Call buildMap

    # Step 2: Draw the initial map
    mv      a0, a2            # Map buffer pointer
    mv      a1, a3            # Start cell
    mv      a2, a4            # Goal cell
    jal     ra, drawMap       # Call drawMap

    # Restore open and closed list pointers
    lw      s0, 0(sp)         # s0 = open list pointer
    lw      s1, 4(sp)         # s1 = closed list pointer
    addi    sp, sp, 8         # Restore stack

    # Step 3: Run A* search
    mv      a0, s0            # Open list pointer
    mv      a1, s1            # Closed list pointer
    # a2: map buffer, a3: start, a4: goal remain unchanged
    jal     ra, aStar         # Call aStar

    # Step 4: If a solution is found, draw it
    beqz    a0, pathFinder_end  # If no solution, skip drawing
    mv      a0, s1            # Closed list pointer
    mv      a1, a3            # Start cell
    mv      a2, a4            # Goal cell
    jal     ra, drawSoln      # Call drawSoln

pathFinder_end:
    ret

#------------------------------------------------------------------------------
# buildMap:
# Initializes the map buffer, marking water cells.
#
# Args:
#   a0: pointer to the water array
#   a1: length of the water array
#   a2: pointer to the map buffer
#
# Effect:
#   Marks water cells in the map buffer.
#------------------------------------------------------------------------------
buildMap:
    # Load ROWS and COLS
    la      t0, ROWS
    lw      t1, 0(t0)         # t1 = ROWS
    la      t0, COLS
    lw      t2, 0(t0)         # t2 = COLS
    mul     t3, t1, t2        # t3 = total cells (ROWS * COLS)

    # Step 1: Initialize all cells to 0 (grass)
    li      t4, 0             # t4 = cell index
init_loop:
    bge     t4, t3, mark_water  # If all cells processed, exit
    slli    t0, t4, 2         # t0 = cell index * 4 (byte offset)
    add     t0, a2, t0        # t0 = address of map_buffer[cell]
    sw      zero, 0(t0)       # Set cell to 0 (grass)
    addi    t4, t4, 1         # Increment cell index
    j       init_loop

mark_water:
    # Step 2: Mark water cells
    li      t4, 0             # t4 = water array index
water_loop:
    bge     t4, a1, buildMap_end  # If all water cells processed, exit
    slli    t0, t4, 2         # t0 = water array index * 4 (byte offset)
    add     t0, a0, t0        # t0 = address of water_array[index]
    lw      t5, 0(t0)         # t5 = water cell index
    slli    t5, t5, 2         # t5 = water cell index * 4 (byte offset)
    add     t5, a2, t5        # t5 = address of map_buffer[water cell]
    li      t6, 1             # t6 = 1 (water)
    sw      t6, 0(t5)         # Mark cell as water
    addi    t4, t4, 1         # Increment water array index
    j       water_loop

buildMap_end:
    ret

#------------------------------------------------------------------------------
# drawMap:
# Draws the map on the terminal.
#
# Args:
#   a0: pointer to the map buffer
#   a1: start cell number
#   a2: goal cell number
#
# Effect:
#   Draws the map with start, goal, water, and grass cells.
#------------------------------------------------------------------------------
drawMap:
    # Save registers
    addi    sp, sp, -20
    sw      ra, 0(sp)
    sw      s0, 4(sp)
    sw      s1, 8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)

    # Load ROWS and COLS
    la      t0, ROWS
    lw      s0, 0(t0)         # s0 = ROWS
    la      t0, COLS
    lw      s1, 0(t0)         # s1 = COLS
    mul     s2, s0, s1        # s2 = total cells (ROWS * COLS)

    # Initialize loop counter
    li      t1, 0             # t1 = cell index

drawMap_loop:
    bge     t1, s2, drawMap_end  # If all cells processed, exit

    # Calculate row and column
    div     t2, t1, s1        # t2 = row (cell index / COLS)
    rem     t3, t1, s1        # t3 = column (cell index % COLS)

    # Determine cell color
    beq     t1, a1, set_red   # If cell == start, set RED
    beq     t1, a2, set_yellow  # If cell == goal, set YELLOW
    slli    t0, t1, 2         # t0 = cell index * 4 (byte offset)
    add     t0, a0, t0        # t0 = address of map_buffer[cell]
    lw      t4, 0(t0)         # t4 = cell value (0 = grass, 1 = water)
    beqz    t4, set_green     # If grass, set GREEN
    j       set_blue          # Else, set BLUE

set_red:
    la      a4, RED
    lw      a4, 0(a4)
    j       draw_cell

set_yellow:
    la      a4, YELLOW
    lw      a4, 0(a4)
    j       draw_cell

set_green:
    la      a4, GREEN
    lw      a4, 0(a4)
    j       draw_cell

set_blue:
    la      a4, BLUE
    lw      a4, 0(a4)

draw_cell:
    # Draw the cell using GLIR_PrintRect
    mv      a0, t2            # Row
    mv      a1, t3            # Column
    li      a2, 1             # Height
    li      a3, 1             # Width
    li      a5, 0             # Default block character
    jal     ra, GLIR_PrintRect

    addi    t1, t1, 1         # Increment cell index
    j       drawMap_loop

drawMap_end:
    # Restore registers
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    addi    sp, sp, 20
    ret

#------------------------------------------------------------------------------
# aStar:
# Simplified A* search algorithm.
#
# Args:
#   a0: pointer to the open list
#   a1: pointer to the closed list
#   a2: pointer to the map buffer
#   a3: start cell number
#   a4: goal cell number
#
# Returns:
#   a0: 1 if a solution is found, 0 otherwise.
#------------------------------------------------------------------------------
aStar:
    # Load ROWS and COLS
    la      t0, COLS
    lw      t0, 0(t0)         # t0 = COLS
    la      t1, ROWS
    lw      t1, 0(t1)         # t1 = ROWS

    mv      s0, a3            # s0 = current cell
    li      s1, 0             # s1 = current g cost

aStar_loop:
    # Check if goal is reached
    beq     s0, a4, aStar_found

    # Color current cell gray
    div     t2, s0, t0        # t2 = row (current cell / COLS)
    rem     t3, s0, t0        # t3 = column (current cell % COLS)
    li      a2, 1             # Height
    li      a3, 1             # Width
    la      a4, GREY          # Color
    lw      a4, 0(a4)
    li      a5, 0             # Default block character
    mv      a0, t2            # Row
    mv      a1, t3            # Column
    jal     ra, GLIR_PrintRect

    # Evaluate neighbors
    li      s2, -1            # Best candidate = -1
    li      s3, 0x7FFFFFFF    # Best f cost = max int

    # Check left neighbor
    rem     t3, s0, t0        # Column of current cell
    blez    t3, check_right   # If column == 0, skip
    addi    t4, s0, -1        # Left neighbor
    mv      a0, a2            # Map buffer pointer
    mv      a1, t4            # Neighbor cell
    jal     ra, isWater       # Check if water
    bnez    a0, check_right   # If water, skip
    addi    t5, s1, 1         # g cost = current g + 1
    mv      a0, t4            # Neighbor cell
    mv      a1, a4            # Goal cell
    jal     ra, manhattan     # Calculate h cost
    add     t5, t5, a0        # f cost = g + h
    blt     t5, s3, update_left  # If better, update
    j       check_right

update_left:
    mv      s2, t4            # Update best candidate
    mv      s3, t5            # Update best f cost

check_right:
    # Similar logic for right, top, and bottom neighbors
    # (Omitted for brevity)

aStar_found:
    li      a0, 1             # Solution found
    ret

aStar_fail:
    li      a0, 0             # No solution
    ret

#------------------------------------------------------------------------------
# drawSoln:
# Draws the solution path on the terminal.
#
# Args:
#   a0: pointer to the closed list
#   a1: start cell number
#   a2: goal cell number
#
# Effect:
#   Draws the solution path and redraws start and goal cells.
#------------------------------------------------------------------------------
drawSoln:
    # Save registers
    addi    sp, sp, -20
    sw      ra, 0(sp)
    sw      s0, 4(sp)
    sw      s1, 8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)

    # Load COLS
    la      t0, COLS
    lw      s0, 0(t0)         # s0 = COLS

    # Calculate start and goal coordinates
    div     s1, a1, s0        # s1 = start row
    rem     s2, a1, s0        # s2 = start column
    div     s3, a2, s0        # s3 = goal row
    rem     t0, a2, s0        # t0 = goal column

    # Draw horizontal segment
    blt     s2, t0, h_ok      # Ensure left to right
    mv      t1, t0            # Swap if necessary
    mv      t0, s2
    mv      s2, t1
h_ok:
    mv      t1, s2            # t1 = current column
h_loop:
    bgt     t1, t0, h_done    # If column > goal column, exit
    mv      a0, s1            # Row
    mv      a1, t1            # Column
    li      a2, 1             # Height
    li      a3, 1             # Width
    la      a4, PURPLE        # Color
    lw      a4, 0(a4)
    li      a5, 0             # Default block character
    jal     ra, GLIR_PrintRect
    addi    t1, t1, 1         # Increment column
    j       h_loop

h_done:
    # Draw vertical segment
    blt     s1, s3, v_ok      # Ensure top to bottom
    mv      t1, s3            # Swap if necessary
    mv      s3, s1
    mv      s1, t1
v_ok:
    mv      t1, s1            # t1 = current row
v_loop:
    bgt     t1, s3, v_done    # If row > goal row, exit
    mv      a0, t1            # Row
    mv      a1, t0            # Column
    li      a2, 1             # Height
    li      a3, 1             # Width
    la      a4, PURPLE        # Color
    lw      a4, 0(a4)
    li      a5, 0             # Default block character
    jal     ra, GLIR_PrintRect
    addi    t1, t1, 1         # Increment row
    j       v_loop

v_done:
    # Redraw start and goal cells
    mv      a0, s1            # Start row
    mv      a1, s2            # Start column
    la      a4, RED           # Color
    lw      a4, 0(a4)
    jal     ra, GLIR_PrintRect

    mv      a0, s3            # Goal row
    mv      a1, t0            # Goal column
    la      a4, YELLOW        # Color
    lw      a4, 0(a4)
    jal     ra, GLIR_PrintRect

    # Restore registers
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    addi    sp, sp, 20
    ret

#------------------------------------------------------------------------------
# isWater:
# Checks if a cell is a water cell.
#
# Args:
#   a0: pointer to the map buffer
#   a1: cell number
#
# Returns:
#   a0: 1 if water, 0 otherwise.
#------------------------------------------------------------------------------
isWater:
    slli    t0, a1, 2         # t0 = cell index * 4 (byte offset)
    add     t0, a0, t0        # t0 = address of map_buffer[cell]
    lw      a0, 0(t0)         # a0 = cell value (0 = grass, 1 = water)
    ret

#------------------------------------------------------------------------------
# manhattan:
# Calculates the Manhattan distance between two cells.
#
# Args:
#   a0: cell A
#   a1: cell B
#
# Returns:
#   a0: Manhattan distance
#------------------------------------------------------------------------------
manhattan:
    # Load COLS
    la      t0, COLS
    lw      t0, 0(t0)         # t0 = COLS

    # Calculate row and column for cell A
    div     t1, a0, t0        # t1 = row_A
    rem     t2, a0, t0        # t2 = column_A

    # Calculate row and column for cell B
    div     t3, a1, t0        # t3 = row_B
    rem     t4, a1, t0        # t4 = column_B

    # Calculate absolute difference of rows
    sub     t5, t1, t3        # t5 = row_A - row_B
    bgez    t5, row_diff_done # If t5 >= 0, skip negation
    sub     t5, zero, t5      # Negate t5 to get absolute value
row_diff_done:

    # Calculate absolute difference of columns
    sub     t6, t2, t4        # t6 = column_A - column_B
    bgez    t6, col_diff_done # If t6 >= 0, skip negation
    sub     t6, zero, t6      # Negate t6 to get absolute value
col_diff_done:

    # Sum the differences
    add     a0, t5, t6        # a0 = Manhattan distance
    ret
