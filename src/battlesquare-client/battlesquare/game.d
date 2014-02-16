module battlesquare.game;
// game

import std.stdio;
import std.exception;
import std.conv;
import std.string;
import std.math;
import battlesquare.sdl;
import battlesquare.init;
import battlesquare.vec;

void trace(T...)(T args) {
    debug { writeln(args); } // whole thing should be optimised away in release mode
}

interface Game {
    void render(Renderer renderer);
    void update(real delta); // delta - difference in time, in ms, since last call
}

class Button {
    private void delegate() callback;
    public SDL_Rect rect;
    public string text;
    private bool _isBeingPressed;
    public @property bool isBeingPressed() { return _isBeingPressed; }
    
    public void press() {
        if(this.isBeingPressed == false) { // you can't press a button when it's pressed, silly!
            this._isBeingPressed = true;
            this.callback();
        }
    }
    
    public void release() {
        this._isBeingPressed = false;
    }
    
    public this(string text, SDL_Rect where, void delegate() callback) {
        this.text = text;
        this.rect = where;
        this.callback = callback;        
    }
}
