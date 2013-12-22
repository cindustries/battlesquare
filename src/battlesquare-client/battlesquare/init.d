module battlesquare.init;

import std.stdio;
import std.string;
import std.conv;
import battlesquare.sdl;
import battlesquare.game;
import battlesquare.basicgame;

// some constants for config
public immutable string SCREEN_TITLE = "BattleSquare";
public immutable int SCREEN_WIDTH = 800;   // 50x40 16px tiles
public immutable int SCREEN_HEIGHT = 640;

void main(string[] args) {
    
    writeln(args);
        
    // load sdl
    DerelictSDL2.load();
    scope(exit) DerelictSDL2.unload();
    DerelictSDL2Image.load();
    scope(exit) DerelictSDL2Image.unload();
    
    // init sdl
    enforceSdl(SDL_Init(0), "Could not initialise SDL!");
    scope(exit) SDL_Quit();
    
    enforceSdl(SDL_VideoInit(null), "Could not initialise SDL video driver!");
    scope(exit) SDL_VideoQuit();
    
    // create window & renderer
    SDL_Window* sdlWindow = null;
    SDL_Surface* sdlWindowSurface = null;
    SDL_Renderer* sdlRenderer = null;
    
    sdlWindow = SDL_CreateWindow(
            toStringz(SCREEN_TITLE),
            SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED,
            SCREEN_WIDTH,
            SCREEN_HEIGHT,
            SDL_WINDOW_BORDERLESS
    );
    enforceSdl(sdlWindow != null, "Could not create SDL window!");
    scope(exit) SDL_DestroyWindow(sdlWindow);
    
    sdlWindowSurface = SDL_GetWindowSurface(sdlWindow);
    enforceSdl(sdlWindowSurface != null, "Could not get window surface!");
    
    sdlRenderer = SDL_CreateRenderer(sdlWindow, -1, SDL_RENDERER_TARGETTEXTURE);
    enforceSdl(sdlRenderer != null, "Could not create SDL renderer!");
    scope(exit) SDL_DestroyRenderer(sdlRenderer);
    
    Renderer renderer = new Renderer(sdlRenderer);
    // now we have a working renderer!
    debug {
        try {
            auto game = to!Game( new BasicGame() );
            runGame(game, renderer);            
        } catch(Exception ex) {
            SDL_ShowSimpleMessageBox(
                SDL_MESSAGEBOX_ERROR,
                "Exception",
                toStringz(to!string(ex)),
                sdlWindow
            );
            throw ex;
        }
        
    } else {
        auto game = to!Game( new BasicGame() );
        runGame(game, sdlRenderer);
    }
       
    
}

void runGame(Game game, Renderer renderer) {
    for(;;) {
        game.update(0); // lol
        game.render(renderer);
        SDL_Delay(1000/60);
    }
}