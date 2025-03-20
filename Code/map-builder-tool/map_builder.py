import os
import pygame
from tkinter import messagebox
from input_box import InputBox
from button import ConfirmButton, GetInputFileButton

VISUALIZE = True
WIN_HEIGHT = 700
WIN_WIDTH = 640       # Change to reduse or increse the size of Window
GRID_ROWS = 32
GRID_COLS = 32
BOX_WIDTH = 20
FONT = pygame.font.Font(None, 24)
pygame.key.set_repeat(200, 25)
win = pygame.display.set_mode((WIN_WIDTH, WIN_HEIGHT))
pygame.display.set_caption("Lab 5 Map Builder")
clock = pygame.time.Clock()

RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
PURPLE = (128, 0, 128)
ORANGE = (255, 165, 0)
GREY = (128, 128, 128)


class Cube:
    def __init__(self, row, col, width, total_rows, int_rep):
        self.row = row
        self.col = col
        self.width = width
        self.total_rows = total_rows
        self.x = row * width
        self.y = col * width
        self.color = GREEN
        self.neighbours = []
        self.int_rep = int_rep

    def getPos(self):
        return self.row, self.col

    def isStart(self):
        return self.color == RED

    def isEnd(self):
        return self.color == ORANGE

    def isWall(self):
        return self.color == BLUE

    def reset(self):
        self.color = GREEN

    def setWall(self):
        self.color = BLUE

    def setEnd(self):
        self.color = ORANGE

    def setStart(self):
        self.color = RED

    def draw(self, win):
        pygame.draw.rect(win, self.color, (
            self.y, self.x, self.width, self.width))

    def __lt__(self, value):
        return False


def setGrid(rows, cols):
    grid = []
    gap = BOX_WIDTH
    for i in range(rows):
        grid.append([])
        for j in range(cols):
            cube = Cube(i, j, gap, rows, j+i*cols)
            grid[i].append(cube)
    return grid


def drawGrid(win, rows, cols):
    gap = BOX_WIDTH
    for i in range(0, rows+1):
        pygame.draw.line(win, GREY, (0, i * gap), (cols * gap, i * gap))
    for i in range(0, cols+1):
        pygame.draw.line(win, GREY, (i * gap, 0), (i * gap, rows * gap))


def draw(win, grid, rows, cols):
    # win.fill(GREEN)

    for row in grid:
        for cub in row:
            cub.draw(win)

    drawGrid(win, rows, cols)
    # pygame.display.update()


def getClickedPos(pos):
    x, y = pos
    gap = BOX_WIDTH
    rows = y // gap
    col = x // gap
    return rows, col


def getInputFile(rows, cols, grid):
    start, goal = -1, -1
    water_array = []

    for row in grid:
        for cube in row:
            if cube.isStart():
                start = cube.int_rep
            elif cube.isEnd():
                goal = cube.int_rep
            elif cube.isWall():
                water_array.append(cube.int_rep)
    if start == -1:
        print("Start grid not set")
        return
    elif goal == -1:
        print("Goal grid not set")
        return

    file_num = 0
    while True:
        if not os.path.exists(f"../map-spec-{file_num}.txt"):
            break
        else:
            file_num += 1
    with open(f"../map-spec-{file_num}.txt", "w") as input_file:
        input_file.write(f"{rows} {cols}\n")
        input_file.write(f"{start} {goal}\n")
        input_file.write(f"{str(water_array).strip('[]').replace(',', '')}\n")

    print("Input file written to {}".format(
        os.path.abspath(f"../map-spec-{file_num}.txt")))

    return


def main(win, width, height):
    pygame.init()
    GRID_ROWS = 32
    GRID_COLS = 32
    input_box1 = InputBox(5, 660, 140, 32, str(GRID_ROWS))
    input_box2 = InputBox(165, 660, 140, 32, str(GRID_COLS))
    input_boxes = [input_box1, input_box2]
    inputs = ['', '']
    confirm_button = ConfirmButton(325, 660, 140, 32, 'CONFIRM')
    get_input_file_button = GetInputFileButton(485, 660, 150, 32,
                                               "Get Input File")
    grid = setGrid(GRID_ROWS, GRID_COLS)

    run = True
    started = False

    start = None
    end = None

    while run:
        win.fill(WHITE)
        win.blit(FONT.render("Grid Rows", True, (0, 0, 0)), (10, 642))
        win.blit(FONT.render("Grid Columns", True, (0, 0, 0)), (170, 642))
        events = pygame.event.get()

        draw(win, grid, GRID_ROWS, GRID_COLS)
        for i in range(len(input_boxes)):
            input_so_far = input_boxes[i].handle_keyboard(events, win)
            inputs[i] = input_so_far
        for event in events:
            if event.type == pygame.QUIT:
                run = False

            for box in input_boxes:
                box.handle_mouse(event, win)

            get_input_file = get_input_file_button.handle_mouse(
                    event)
            if get_input_file:
                getInputFile(GRID_ROWS, GRID_COLS, grid)

            result = confirm_button.handle_mouse(
                        event, inputs[0], inputs[1])

            if result == 1:
                GRID_COLS = int(inputs[1])
                GRID_ROWS = int(inputs[0])
                start = None
                end = None
                grid = setGrid(GRID_ROWS, GRID_COLS)
                print("Grid resized sucessfully")
            elif result == 0:
                print("Please double check your values. "
                      "2 ≤ Grid Rows, Grid Columns ≤ 32")

            if started:
                continue

            elif pygame.mouse.get_pressed()[0]:
                pos = pygame.mouse.get_pos()
                row, col = getClickedPos(pos)

                if row >= GRID_ROWS or col >= GRID_COLS:
                    continue

                cube = grid[row][col]
                if not start and cube != end:
                    start = cube
                    cube.setStart()
                    cube.draw(win)
                elif not end and cube != start:
                    end = cube
                    cube.setEnd()
                    cube.draw(win)
                elif cube != end and cube != start:
                    cube.setWall()
                    cube.draw(win)

            elif pygame.mouse.get_pressed()[2]:
                pos = pygame.mouse.get_pos()
                row, col = getClickedPos(pos)

                if row >= GRID_ROWS or col >= GRID_COLS:
                    continue

                cube = grid[row][col]
                if cube == start:
                    start = None
                elif cube == end:
                    end = None
                cube.reset()
                cube.draw(win)
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_c:
                    start = None
                    end = None
                    grid = setGrid(GRID_ROWS, GRID_COLS)

        for box in input_boxes:
            box.draw(win)
        confirm_button.draw(win)
        get_input_file_button.draw(win)
        pygame.display.update()
        clock.tick(30)


messagebox.showinfo("Information", "Default grid size is 32 x 32\n"
                    "PRESS\nLEFT CLICK    - To place START/"
                    "END point and Draw water cells\nRIGHT CLICK - Remove "
                    "START/END and water cells \n"
                    "C\t      - To Clear Screen\n")
main(win, WIN_WIDTH, WIN_HEIGHT)
