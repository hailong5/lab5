import pygame as pg

pg.init()
FONT = pg.font.Font(None, 32)


class Button:
    def __init__(self, x, y, w, h, text=''):
        self.rect = pg.Rect(x, y, w, h)
        self.text_surface = FONT.render(text, True, (0, 0, 0))
        self.color = pg.Color('lime')

    def draw(self, screen):
        pg.draw.rect(screen, self.color, self.rect, 2)
        screen.blit(self.text_surface, (self.rect.x+5, self.rect.y+5))


class ConfirmButton(Button):
    def handle_mouse(self, event, input1, input2):

        if event.type == pg.MOUSEBUTTONDOWN:
            if event.button == 1:
                if self.rect.collidepoint(event.pos):
                    if len(input1) == 0 or len(input2) == 0:
                        return 0
                    if 2 <= int(input1) <= 32 and 2 <= int(input2) <= 32:
                        return 1
                    else:
                        return 0
        return -1


class GetInputFileButton(Button):
    def handle_mouse(self, event):
        if (event.type == pg.MOUSEBUTTONDOWN and event.button == 1 and
           self.rect.collidepoint(event.pos)):
            return True
        else:
            return False


if __name__ == '__main__':
    button = Button(0, 0, 140, 32, 0, 0)
