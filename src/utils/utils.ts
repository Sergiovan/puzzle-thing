/* - TYPE TRAITS - */
export type KeysOfType<O, T> = {
    [K in keyof O]: O[K] extends T ? K : never
  }[keyof O];

/* - COORDINATES - */
export type Coordinate = [number, number]; // [x, y]

export function add(this: Coordinate, o: Coordinate) {
    return [this[0] + o[0], this[1] + o[1]];
}

export function sub(this: Coordinate, o: Coordinate) {
    return [this[0] - o[0], this[1] - o[1]];
}

/* - COLORS - */

/* Always in milliseconds */
export type DeltaTime = number;

/* Alpha is optional */
export type Color = [number, number, number, number?];
export const COLORS: {[name: string]: Color} = {
    white: [1, 1, 1, 1]
};

export function file_exists(path: string) {
    return love.filesystem.getInfo(path) !== undefined;
}