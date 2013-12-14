module battlesquare.init;

import std.stdio;
import std.string;
import std.conv;
import battlesquare.sdl;
import battlesquare.game;


void main(string[] args) {
    
    writeln(args);
        
    // load sdl
    DerelictSDL2.load();
    scope(exit) DerelictSDL2.unload();
    DerelictSDL2Image.load();
    scope(exit) DerelictSDL2Image.load();
    
    // init sdl
    enforceSdl(SDL_Init(0), "Could not initialise SDL!");
    scope(exit) SDL_Quit();
    
    enforceSdl(SDL_VideoInit(null), "Could not initialise SDL video driver!");
    scope(exit) SDL_VideoQuit();
    
    // create window & renderer
    SDL_Window* sdlWindow = null;
    SDL_Renderer* sdlRenderer = null;
    
    sdlWindow = SDL_CreateWindow(
            toStringz(SCREEN_TITLE),
            SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED,
            SCREEN_WIDTH,
            SCREEN_HEIGHT,
            0
    );
    enforceSdl(sdlWindow != null, "Could not create SDL window!");
    scope(exit) SDL_DestroyWindow(sdlWindow);
    
    sdlRenderer = SDL_CreateRenderer(sdlWindow, -1, SDL_RENDERER_ACCELERATED);
    enforceSdl(sdlRenderer != null, "Could not create SDL renderer!");
    scope(exit) SDL_DestroyRenderer(sdlRenderer);
    
    // now we have a working renderer!
    auto game = new Game(sdlRenderer);
    game.run(args[1].to!uint);
       
    
}