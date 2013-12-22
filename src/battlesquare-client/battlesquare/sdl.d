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

SDL_Rect rectToSDLRect(Rect rect) {
    SDL_Rect sdlRect;
    sdlRect.x = to!int( rect.pos.x );
    sdlRect.y = to!int( rect.pos.y );
    sdlRect.w = to!int( rect.size.x );
    sdlRect.h = to!int( rect.size.y );
    return sdlRect;
}

SDL_Rect* rectToSDLRectp(Rect rect) {
    SDL_Rect* rectp = new SDL_Rect;
    (*rectp) = rectToSDLRect(rect);
    return rectp;
}

class Renderer {
    private SDL_Renderer* sdlRenderer;
    
    public this(SDL_Renderer* renderer) { // the creator must deal with destroying the raw renderer
        this.sdlRenderer = renderer;
    }
    
    void present() {
        SDL_RenderPresent(sdlRenderer);
    }
    
    class Texture {
        private SDL_Texture* sdlTexture;
        private this(SDL_Texture* tex) { sdlTexture = tex; }
        public ~this() { SDL_DestroyTexture(sdlTexture);        }
    }
    
    Texture createTexture(uint format, int access, int w, int h) {
        SDL_Texture* sdlTexture = SDL_CreateTexture(sdlRenderer, format, access, w, h);
        enforceSdl(sdlTexture != null, "createTexture failed");
        return new this.Texture(sdlTexture);
    }
    
    // Drawing methods
    void setDrawColour(ubyte r, ubyte g, ubyte b, ubyte a) {
        enforceSdl( SDL_SetRenderDrawColor(sdlRenderer, r, g, b, a), "setColour failed" );
    }
    
    void fillRect(Rect rect) {
        enforceSdl( SDL_RenderFillRect(sdlRenderer, rectToSDLRectp(rect)), "fillRect failed" );
    }
    
    void drawPoint(Vec pos) {
        enforceSdl( SDL_RenderDrawPoint(sdlRenderer, pos.x.to!int, pos.y.to!int), "drawPoint failed" );
    }
    
    void clear() {
        enforceSdl( SDL_RenderClear(sdlRenderer), "clear failed" );
    }
    
    void copyRect(Texture texture, Rect source, Rect dest) {
        enforceSdl( SDL_RenderCopy(
            sdlRenderer, texture.sdlTexture,
            rectToSDLRectp(source), rectToSDLRectp(dest)
        ), "copyRect failed" );
    }
    
    
    // Render target management
    Texture getRenderTarget() {
        return new Texture( SDL_GetRenderTarget(sdlRenderer) );
    }
    
    void setRenderTarget(Texture target) {
        enforceSdl( SDL_SetRenderTarget(sdlRenderer, target.sdlTexture), "setRenderTarget failed" );
    }
}

alias Texture = Renderer.Texture;

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