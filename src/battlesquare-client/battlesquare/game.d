module battlesquare.game;
// game

import std.stdio;
import std.exception;
import std.conv;
import std.string;
import battlesquare.sdl;
import battlesquare.sprite;
import battlesquare.map;

struct Vec {
    float x = 0;
    float y = 0;
    
    static public Vec zero = Vec(0.0, 0.0);
    
    Vec opUnary(string op)() if(op == "-") { return zero - this; }
    Vec opBinary(string op)(Vec b) if(op == "+") { return Vec( this.x + b.x, this.y + b.y ); }
    Vec opBinary(string op)(Vec b) if(op == "-") { return Vec( this.x - b.x, this.y - b.y ); }
    
    string toString() { return "(" ~ x.to!string ~ ", " ~ y.to!string ~ ")"; }
}

class Player {
    string name = "Player";
    Vec pos, dpos, lastdpos;
    
    void addMove(float x, float y) {
        dpos = dpos + Vec(x, y);
    }
    
    void applyMove() {
        debug writeln("Applying move ", dpos, " to ", pos);
        lastdpos = dpos;
        pos = pos + dpos;
        dpos = Vec.zero;
    }
}

class Bullet {
    Vec pos;
    Vec dpos;
    
    void applyMove() {
        pos = pos + dpos;
    }
}


class Game {
    
    private Player player1;
    private Bullet[] bullets;
    
    private bool[SDL_Keycode] isKeyDown;
    
    public this() {
        player1 = new Player();
        player1.pos = Vec(100, 100);
    }

    public void update() {
        SDL_Event event;    
        while(SDL_PollEvent(&event)) {
            switch(event.type) {
                case SDL_QUIT: assert(false, "TODO: Make a better way to exit.");
                
                case SDL_KEYDOWN: 
                    auto key = event.key.keysym.sym;
                    isKeyDown[key] = true;
                    break;
                    
                case SDL_KEYUP:
                    auto key = event.key.keysym.sym;
                    isKeyDown[key] = false;
                    break;            
                    
                default:
                    writeln("Unhandled event", event.type);
                    break;
            }
        }
        
        // update the bullets' positions
        foreach(bullet; this.bullets) {
            bullet.applyMove();
        }
        
        // check for vertical movement
        if(isKeyDown.get(SDLK_DOWN, false) == true) {
            player1.addMove(0, 1);
        }
        else if(isKeyDown.get(SDLK_UP, false) == true) {
            player1.addMove(0, -1);
        }
        
        // check for horizontal movement
        if(isKeyDown.get(SDLK_LEFT, false) == true) {
            player1.addMove(-1, 0);
        }
        else if(isKeyDown.get(SDLK_RIGHT, false) == true) {
            player1.addMove(1, 0);
        }
        
        player1.applyMove();
    }
    
    public void render(SDL_Renderer* rdr) {
        SDL_SetRenderDrawColor(rdr, 0, 0, 0, 255);
        SDL_RenderClear(rdr);
        
        // render bullets
        SDL_SetRenderDrawColor(rdr, 255, 255, 255, 255);
        foreach(bullet; this.bullets) {
            SDL_RenderDrawPoint(rdr, bullet.pos.x.to!int, bullet.pos.y.to!int);
        }
        
        // render player1
        enum int PLAYER_SIZE = 24; enum int PLAYER_SIZE_HALF = PLAYER_SIZE/2;
        auto rect = SDL_Rect(
            cast(int)(player1.pos.x) - PLAYER_SIZE_HALF,
            cast(int)(player1.pos.y) - PLAYER_SIZE_HALF,
            PLAYER_SIZE,
            PLAYER_SIZE
        );
        
        SDL_SetRenderDrawColor(rdr, 0, 255, 0, 255);
        SDL_RenderFillRect(rdr, &rect);
        
        SDL_RenderDrawPoint(rdr, 10, 10);
        
        SDL_RenderPresent(rdr);
    }
}
