#------------------------------------------------------------------------------
# Color Definitions (ANSI 256 color codes)
#------------------------------------------------------------------------------
.include  "./common.s"

.text

#------------------------------------------------------------------------------
# pathFinder:
#
# Args:
#   a0: pointer to the open list
#   a1: pointer to the closed list
#   a2: pointer to the map buffer
#   a3: start cell
#   a4: goal cell
#   a5: pointer to the water array
#   a6: length of the water array
#
# Returns:
#   a0: 1 if a solution path is found, 0 otherwise.
#
# Effect:
#   1. buildMap(water array, length, map buffer)
#   2. drawMap(map buffer, start, goal)
#   3. aStar(openList, closedList, map buffer, start, goal)
#   4. If aStar returns 1, drawSoln(closedList, start, goal)
#------------------------------------------------------------------------------
pathFinder:
    # Save open/closed list pointers on stack
    addi    sp, sp, -8
    sw      a0, 0(sp)
    sw      a1, 4(sp)

    # 1. Build the map
    mv      a0, a5         # pointer to water array
    mv      a1, a6         # length of water array
    # a2 = map buffer pointer
    jal     ra, buildMap

    # 2. Draw the map
    mv      a0, a2         # map buffer
    mv      a1, a3         # start cell
    mv      a2, a4         # goal cell
    jal     ra, drawMap

    # Restore open/closed list pointers
    lw      s0, 0(sp)
    lw      s1, 4(sp)
    addi    sp, sp, 8

    # 3. Run aStar
    mv      a0, s0         # open list pointer
    mv      a1, s1         # closed list pointer
    # a2 = map buffer, a3 = start, a4 = goal remain in registers
    jal     ra, aStar

    # 4. If aStar returns 1 (solution found), call drawSoln
    beqz    a0, pf_end
    mv      a0, s1         # closed list pointer
    mv      a1, a3         # start cell
    mv      a2, a4         # goal cell
    jal     ra, drawSoln

pf_end:

    ret

#------------------------------------------------------------------------------
# aStar:
#
# A simplified "greedy" search that:
#   - Expands neighbors in the order left, right, top, bottom
#   - Skips water cells (isWater returns 1)
#   - Colors expanded cells in GREY
#   - Stops when it reaches the goal
#   - Returns 1 if the goal is reached, 0 otherwise
#
# Args:
#   a0: pointer to open list   (unused in this stub)
#   a1: pointer to closed list (unused)
#   a2: pointer to map buffer
#   a3: start cell
#   a4: goal cell
#
# Returns:
#   a0 = 1 if a path is found, 0 otherwise
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
#
# Args:
#   a0: pointer to the water array
#   a1: length of the water array
#   a2: pointer to the map buffer
#
# Effect:
#   Fills the map buffer with 0 (grass) and sets to 1 if the cell is in the water array.
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
#   a0: pointer to the map buffer
#   a1: start cell number
#   a2: goal cell number
#
# Effect:
#   Draws each cell using GLIR_PrintRect:
#     - If cell index == start, RED
#     - If cell index == goal, YELLOW
#     - If map_buffer[cell] == 1, BLUE
#     - Otherwise, GREEN
#------------------------------------------------------------------------------
drawMap:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      a0, 0(sp)
    sw      a1, 4(sp)
    sw      a2, 8(sp)

    lw      s0, 0(sp)       # s0 = map buffer
    lw      s1, 4(sp)       # s1 = start cell index
    lw      s2, 8(sp)       # s2 = goal cell index

    la      t0, ROWS
    lw      t1, 0(t0)       # t1 = ROWS
    la      t0, COLS
    lw      t2, 0(t0)       # t2 = COLS
    mul     t3, t1, t2      # t3 = total cells

    li      t4, 0           # t4 = current index
drawMap_loop:
    bge     t4, t3, drawMap_done

    rem     t6, t4, t2      # column = index % COLS
    div     t5, t4, t2      # row = index / COLS

    slli    t0, t4, 2       # address = map + index * 4
    add     t0, s0, t0
    lw      a7, 0(t0)       # a7 = cell value

    # Set color based on priority
    beq     t4, s1, dm_set_red
    beq     t4, s2, dm_set_yellow
    li      t0, 1
    beq     a7, t0, dm_set_blue

    la      t0, GREEN
    lw      a4, 0(t0)       # a4 = GREEN
    j       dm_draw

dm_set_red:
    la      t0, RED
    lw      a4, 0(t0)
    j       dm_draw

dm_set_yellow:
    la      t0, YELLOW
    lw      a4, 0(t0)
    j       dm_draw

dm_set_blue:
    la      t0, BLUE
    lw      a4, 0(t0)

dm_draw:
    mv      a0, t5          # row position
    mv      a1, t6          # column position
    li      a2, 1           # height
    li      a3, 1           # width
    li      a5, 0           # string: 0 = use default full block
    jal     ra, GLIR_PrintRect

    addi    t4, t4, 1
    j       drawMap_loop

drawMap_done:
    lw      ra, 12(sp)
    addi    sp, sp, 16
    ret
#------------------------------------------------------------------------------
# isWater:
#
# Args:
#   a0: pointer to map buffer
#   a1: cell number
#
# Returns:
#   a0 = 1 if water, 0 otherwise
#------------------------------------------------------------------------------
isWater:
    slli    t0, a1, 2
    add     t0, a0, t0
    lw      a0, 0(t0)
    ret

#------------------------------------------------------------------------------
# manhattan:
#
# Args:
#   a0: cell A
#   a1: cell B
#
# Returns:
#   a0 = Manhattan distance between A and B
#------------------------------------------------------------------------------
manhattan:
    la      t0, COLS
    lw      t0, 0(t0)

    div     t1, a0, t0    # rowA
    rem     t2, a0, t0    # colA
    div     t3, a1, t0    # rowB
    rem     t4, a1, t0    # colB

    sub     t5, t1, t3    # rowA - rowB
    bltz    t5, manh_absr
    j       manh_rowDone
manh_absr:
    sub     t5, zero, t5
manh_rowDone:

    sub     t6, t2, t4    # colA - colB
    bltz    t6, manh_absC
    j       manh_colDone
manh_absC:
    sub     t6, zero, t6
manh_colDone:

    add     a0, t5, t6
    ret

#------------------------------------------------------------------------------
# drawSoln:
#
# Args:
#   a0: pointer to closed list (unused in this stub)
#   a1: start cell
#   a2: goal cell
#
# Effect:
#   Draws a simple 2-segment path from start to goal in PURPLE,
#   then redraws the start in RED and the goal in YELLOW.
#------------------------------------------------------------------------------
drawSoln:
    # Load COLS
    la      t0, COLS
    lw      t0, 0(t0)

    # convert start cell to (row, col)
    div     t2, a1, t0
    rem     t3, a1, t0

    # convert goal cell to (row, col)
    div     t4, a2, t0
    rem     t5, a2, t0

    # 1. horizontal line from (start row, start col) to (start row, goal col)
    blt     t3, t5, ds_h_ok
    mv      t6, t3
    mv      t3, t5
    mv      t5, t6
ds_h_ok:
    mv      t6, t3
ds_h_loop:
    ble     t6, t5, ds_h_draw
    j       ds_h_done
ds_h_draw:
    mv      a0, t2
    mv      a1, t6
    li      a2, 1
    li      a3, 1
    la      a4, PURPLE
    lw      a4, 0(a4)
    li      a5, 0
    jal     ra, GLIR_PrintRect
    addi    t6, t6, 1
    j       ds_h_loop
ds_h_done:

    # 2. vertical line from (start row, goal col) to (goal row, goal col)
    blt     t2, t4, ds_v_ok
    mv      t6, t4
    mv      t4, t2
    mv      t2, t6
ds_v_ok:
    mv      t6, t2
ds_v_loop:
    ble     t6, t4, ds_v_draw
    j       ds_v_done
ds_v_draw:
    mv      a0, t6
    mv      a1, t5
    li      a2, 1
    li      a3, 1
    la      a4, PURPLE
    lw      a4, 0(a4)
    li      a5, 0
    jal     ra, GLIR_PrintRect
    addi    t6, t6, 1
    j       ds_v_loop
ds_v_done:

    # Redraw start in RED
    la      a4, RED
    lw      a4, 0(a4)
    div     t2, a1, t0   # a1 = start cell
    rem     t3, a1, t0
    mv      a0, t2
    mv      a1, t3
    li      a2, 1
    li      a3, 1
    li      a5, 0
    jal     ra, GLIR_PrintRect

    # Redraw goal in YELLOW
    la      a4, YELLOW
    lw      a4, 0(a4)
    div     t2, a2, t0   # a2 = goal cell
    rem     t3, a2, t0
    mv      a0, t2
    mv      a1, t3
    li      a2, 1
    li      a3, 1
    li      a5, 0
    jal     ra, GLIR_PrintRect

    ret
