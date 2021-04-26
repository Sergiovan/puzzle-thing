import * as utils from '../utils/utils';
import { KeysOfType } from '../utils/utils';

type AnimationFunction = (x: number) => number;
type AnimationStrings = "linear" | "cube" | "rcube" | "fse";

type AnimationData = {
    from: number, // Begin value
    diff: number, // difference between start and end value
    in_: number, // Time to run in seconds
    animation: AnimationFunction // Function to call for animation
};

type AnimationOf<T extends Object> = {[K in KeysOfType<T, number>]?: AnimationData} | (()=>void) | number;

export class Animator<T extends Object> {
    static fromToIn(from: number, to: number, in_: number, animation: AnimationFunction | AnimationStrings = "linear"): AnimationData {
        function linear(x) { return x; }
        function cube(x) { return x ** 3; }
        function rcube(x) { return (x - 1) ** 3 + 1; }
        function fse(x) { return (math.tan(x * 2.5 - 1.25) + 3) / 6; }
        
        const selection = {
            linear: linear,
            cube: cube,
            rcube: rcube,
            fse: fse
        };

        let panimation: AnimationFunction;

        if (typeof animation === "string") {
            panimation = selection[animation] ?? linear;
        }

        return {from: from, diff: to - from, in_: in_, animation: panimation};
    }

    values: T;
    changes: Array<AnimationOf<T>>;

    step: number = 0;
    elapsed: number = 0;
    started: boolean;
    loop: boolean;
    stopped: boolean = false;
    finished: boolean = false;

    constructor(values: T, changes: Array<AnimationOf<T>>, start: boolean = false, loop: boolean = false) {
        this.values = values;
        this.changes = changes;

        this.started = start;
        this.loop = loop;
    }

    update(dt: utils.DeltaTime) {
        if (this.finished || this.stopped || !this.started) {
            return;
        }

        this.elapsed += dt;
        const change = this.changes[this.step];
        if (typeof change === 'number') {
            if (this.elapsed > change) {
                this.skip(change);
                return this.update(0);
            }
        } else if (typeof change === "function") {
            change();
            this.skip(0);
            return this.update(0);
        } else {
            let count = 0, done = 0, maxelapsed = 0;
            for (let key in change) {
                const value: AnimationData = change[key];
                count += 1;
                const x = math.min(this.elapsed / value.in_, 1);
                if (x === 1) {
                    done += 1;
                    maxelapsed = math.max(maxelapsed, value.in_);
                }
                this.values[key] = value.from + value.diff * value.animation(x)
            }

            if (done === count) {
                this.skip(maxelapsed);
                return this.update(0);
            }
        }
    }

    start() {
        if (!this.finished) {
            this.started = true;
            this.stopped = true;
        }
    }

    stop() {
        if (!this.finished) {
            this.stopped = true;
        }
    }

    terminate(forced: boolean) {
        if (!forced) {
            for (let i = this.step; i < this.changes.length; ++i) {
                const change = this.changes[i];
                if (typeof change === "function") {
                    change();
                } else if (typeof change !== "number") {
                    for (let key in change) {
                        this.values[key] = change[key].from;
                    }
                }
            }
        }
        this.finished = false;
    }

    reset() {
        this.started = false;
        this.stopped = false;
        this.finished = false;
        this.step = 0;
        this.elapsed = 0;
    }

    skip(elapsed: number, forced: boolean = false) {
        this.step += 1;
        const nelapsed = !forced ? this.elapsed - elapsed : 0;
        if (this.step >= this.changes.length) {
            this.reset();
            if (this.loop) {
                this.finished = false;
                this.started = true;
            } else {
                return;
            }
        }

        this.elapsed = nelapsed; // This will be 0 if the animation has already finished
        const change = this.changes[this.step];
        if (typeof change !== "number" && typeof change !== "function") {
            for (let key in change) {
                this.values[key] = change[key].from;
            }
        }

    }
};