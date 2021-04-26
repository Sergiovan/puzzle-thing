import { Color, COLORS } from "../utils/utils";
import { GUI, fonts } from "./gui";

export class Label extends GUI {
    text: string;
    font: Font;
    color: Color;
    _text: Text;

    constructor(x: number, y: number, text: string, font: Font = fonts.game, color: Color = COLORS.white) {
        const txt = love.graphics.newText(font, text);
        super(x, y, txt.getWidth(), txt.getHeight());
        this.text = text;
        this.font = font;
        this.color = color;
        this._text = txt;
    }

    draw() {
        love.graphics.setColor(this.color);
        love.graphics.draw(this._text, this.x, this.y);
    }

    set_text(text: string) {
        this.text = text;
        this._text.clear();
        this._text.add(this.text);
    }
};