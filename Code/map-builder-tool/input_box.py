import pygame as pg
import pygame_textinput as pgt

pg.init()
COLOR_INACTIVE = pg.Color('lightskyblue3')
COLOR_ACTIVE = pg.Color('dodgerblue2')
FONT = pg.font.Font(None, 32)


class InputBox:
    def __init__(self, x, y, w, h, text=''):
        self.rect = pg.Rect(x, y, w, h)
        self.color = COLOR_INACTIVE
        self.active = False
        self.input_manager = pgt.TextInputManager(
            validator=lambda input: len(input) <= 2
            and (input.isnumeric() or input == '')
        )
        self.textinput = pgt.TextInputVisualizer(manager=self.input_manager)

    def handle_keyboard(self, events, screen):
        if self.active:
            self.textinput.update(events)
        return self.textinput.value

    def handle_mouse(self, event, screen):
        if event.type == pg.MOUSEBUTTONDOWN:
            # If the user clicked on the input_box rect.
            if self.rect.collidepoint(event.pos):
                # Toggle the active variable.
                self.active = not self.active
            else:
                self.active = False
            # Change the current color of the input box.
            self.color = COLOR_ACTIVE if self.active else COLOR_INACTIVE

    def draw(self, screen):
        # Blit the rect.
        pg.draw.rect(screen, self.color, self.rect, 2)
        screen.blit(self.textinput.surface, (self.rect.x+5, self.rect.y+5))
