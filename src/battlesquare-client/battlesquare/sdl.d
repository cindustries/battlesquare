module battlesquare.sdl;

public import derelict.sdl2.sdl;
public import derelict.sdl2.image;

import std.exception;
import std.conv;

// allows us to check SDL return codes more easily
// prints our message, followed by SDL's error on failure
void enforceSdl(bool result, string message) {
    enforce(result, message ~ " \"" ~ to!string(SDL_GetError()) ~ "\"!" );
}

void enforceSdl(int returnCode, string message) {
    enforceSdl(returnCode == 0, message);
}