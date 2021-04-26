import { DeltaTime } from './utils/utils';
import { game } from './game/game';
import { input } from './input/input'

love.load = (args) => {
    let fps = false;
    for (let arg of args) {
        switch (arg) {
            case '-showfps':
                fps = true;
                break;
        }
    }

    game.show_fps = fps;
    love.mouse.setVisible(false);
    love.window.setTitle("Puzzle thing");
    love.keyboard.setKeyRepeat(true);

    game.init();
};

love.update = (dt: DeltaTime) => {
    input.update(dt);
    game.update(dt);
    input.clear(dt);
};

love.draw = () => {
    game.draw();
};

love.keypressed = (key, scancode, isrepeat) => {
    input.keyboard_button(scancode, true);
};

love.keyreleased = (key, scancode) => {
    input.keyboard_button(scancode, false);
};

love.textinput = (text) => {
    input.add_text_input(text);
};

love.mousepressed = (x, y, button, istouch) => {
    if (button < 1 || button > 3) return;
    input.mouse_button(button, x, y, true);
};

love.mousereleased = (x, y, button, istouch) => {
    if (button < 1 || button > 3) return;
    input.mouse_button(button, x, y, false);
};

love.wheelmoved = (x, y) => {
    input.mouse_update_scroll(x, y);
};

love.focus = (focus) => {
    // TODO
};

love.mousefocus = (focus) => {
    // TODO
};

love.resize = (w, h) => {
    // TODO
};

love.quit = () => {
    return false; // Abort quitting?
};