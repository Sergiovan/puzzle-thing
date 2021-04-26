import { Coordinate, DeltaTime } from '../utils/utils';

type MouseState = [boolean, boolean, boolean];

class InputControl {
    mouse_position: Coordinate; // Position of the mouse
    mouse_movement: Coordinate = [0, 0]; // Movement of the mouse since last update
    mouse_press_pos: [Coordinate, Coordinate, Coordinate] = [[0, 0], [0, 0], [0, 0]]; // Locations of pressing for the 3 main buttons
    mouse_down: MouseState = [false, false, false]; // Mouse button held
    mouse_press: MouseState = [false, false, false]; // Mouse button pressed down this update
    mouse_release: MouseState = [false, false, false]; // Mouse button released this update
    mouse_scroll: Coordinate = [0, 0]; // Mouse scroll [x, y]

    text_input: string = ""; // Text input since last update
    keyboard_down: {[key: string]: boolean} = {}; // Keyboards currently held
    keyboard_press: {[key: string]: boolean} = {}; // Keys pressed this update
    keyboard_release: {[key: string]: boolean} = {}; // Keys released this update

    mouse_moved: boolean = false; // Mouse moved this update
    key_pressed: boolean = false; // Any key pressed this update
    key_released: boolean = false; // Any key released this update

    constructor() {
        this.mouse_position = love.mouse.getPosition();
    }

    update(_: DeltaTime) {
        const [mx, my] = love.mouse.getPosition();
        this.mouse_movement[0] = mx - this.mouse_position[0];
        this.mouse_movement[1] = my - this.mouse_position[1];

        [...this.mouse_movement] = [mx, my];
        this.mouse_moved = (this.mouse_movement[0] || this.mouse_movement[1]) !== 0;
    }

    clear(_: DeltaTime) {
        [...this.mouse_press] = [...this.mouse_release] = [false, false, false];

        for (let key in this.keyboard_press) {
            this.keyboard_press[key] = false;
        }

        for (let key in this.keyboard_release) {
            this.keyboard_release[key] = false;
        }

        this.text_input = "";
        this.key_pressed = this.key_released = false;
        this.mouse_scroll[0] = this.mouse_scroll[1] = 0;
    }

    mouse_button(button: number, x: number, y: number, press: boolean) {
        button--; // Lua is 1-indexed
        this.mouse_down[button] = press;
        const c = press ? this.mouse_press : this.mouse_release;
        c[button] = true;
        [...this.mouse_press_pos[button]] = [press ? x : 0, press ? y : 0];
    }

    mouse_update_scroll(x: number, y: number) {
        this.mouse_scroll[0] += x;
        this.mouse_scroll[1] += y;
    }

    keyboard_button(keycode: string, press: boolean) {
        this.keyboard_down[keycode] = press;
        const c = press ? this.keyboard_press : this.keyboard_release;
        c[keycode] = true;
        press ? this.key_pressed : this.key_released = true;
    }

    add_text_input(text: string) {
        this.text_input += text;
    }
}

export const input = new InputControl();
