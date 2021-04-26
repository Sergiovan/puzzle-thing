import { COLORS } from '../utils/utils';
import * as utils from '../utils/utils';
import { GameObject } from '../game/game_object';

export const font_size = 36;
export const font_size_small = 16;
export const font_size_large = 60;

const default_color = COLORS.white;

const default_font = love.graphics.newFont(font_size);
const default_font_small = love.graphics.newFont(font_size_small);

const console_font_path = 'res/fonts/console_font.ttf';
const game_font_path = 'res/fonts/game_font.ttf';

export const fonts = {
    default: default_font,
    default_small: default_font_small,

    console: utils.file_exists(console_font_path) ? 
             love.graphics.newFont(console_font_path, font_size_small, 'normal') : 
             default_font_small,
    game: utils.file_exists(game_font_path) ? 
          love.graphics.newFont(game_font_path, font_size, 'normal') :
          default_font,
    game_small: utils.file_exists(game_font_path) ?
                love.graphics.newFont(game_font_path, font_size_small, 'normal') : 
                default_font_small
};

export class GUI extends GameObject {
      // Nothing yet...
};