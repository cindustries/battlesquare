module battlesquare.sdl;

public import derelict.sdl2.sdl;
public import derelict.sdl2.image;
public import battlesquare.vec;

import std.exception;
import std.conv;

// allows us to check SDL return codes more easily
// prints our message, followed by SDL's error on failure
void enforceSdl(bool result, string message, string file = __FILE__, size_t line = __LINE__) {
    enforce(result, message ~ " \"" ~ to!string(SDL_GetError()) ~ "\"!", file, line);
}

void enforceSdl(int returnCode, string message, string file = __FILE__, size_t line = __LINE__) {
    enforceSdl(returnCode == 0, message, file, line);
}

class Renderer {
    private SDL_Renderer* sdlRenderer;
    
    class Texture {
        private SDL_Texture* sdlTexture;
        private this(SDL_Texture* tex) { sdlTexture = tex; }
        public ~this() { SDL_DestroyTexture(sdlTexture);        }
    }
    
    //void setColour()
}

// shameless global locationless utilities
abstract final class Mouse {
    public static @property Vec position() {
        int mousex, mousey;
        SDL_GetMouseState( &mousex, &mousey );
        return Vec(mousex.to!float, mousey.to!float);
    }
}

bool containsPoint(SDL_Rect rect, Vec vec) {
    return (
        vec.x > rect.x &&
        vec.x < rect.x + rect.w &&
        vec.y > rect.y &&
        vec.y < rect.y + rect.h
    );
}