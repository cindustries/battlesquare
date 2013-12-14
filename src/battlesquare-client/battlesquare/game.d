module battlesquare.game;
// game

import std.stdio;
import std.exception;
import std.conv;
import std.string;
import battlesquare.sdl;
import battlesquare.sprite;

// some constants for config
immutable string SCREEN_TITLE = "BattleSquare";
immutable int SCREEN_WIDTH = 800;   // 50x40 16px tiles
immutable int SCREEN_HEIGHT = 640;

class Game {
    
    private SDL_Renderer* sdlRenderer;

    public this(SDL_Renderer* renderer) {
        this.sdlRenderer = renderer;
    }
    
    public void run(int dispid) {
        // Load resources
        auto spritesheet = new SpriteSheet(
            "assets/iconset.png", this.sdlRenderer,
            12, 9,
            16, 16,
            1, 1,
            0, 5
        );
        
        auto sprite0 = spritesheet.getSprite(dispid);
        
        SDL_RenderClear(sdlRenderer);
        sprite0.render( SDL_Rect(0, 0, 32, 32) );
        SDL_RenderPresent(sdlRenderer);
        
        SDL_Delay(1000);
    }
}
