module battlesquare.game;
// game

import std.stdio;
import std.exception;
import std.conv;
import std.string;
import std.math;
import battlesquare.sdl;
import battlesquare.sprite;
import battlesquare.map;

struct Vec {
    private float _x = 0, _y = 0;
    public @property float x() { return _x; }
    public @property float y() { return _y; }
    
    static public immutable Vec zero = immutable(Vec)(0.0f, 0.0f);
    
    Vec opUnary(string op)() if(op == "-") { return zero - this; }
    Vec opBinary(string op, T : float)(T val) if(op == "*") { return Vec(x*val.to!float, y*val.to!float); }
    Vec opBinary(string op)(Vec b) if(op == "+") { return Vec( this.x + b.x, this.y + b.y ); }
    Vec opBinary(string op)(Vec b) if(op == "-") { return Vec( this.x - b.x, this.y - b.y ); }
    @property float magnitude() { return sqrt( x*x + y*y ); }
    @property Vec normalised() { return Vec( x/this.magnitude, y/this.magnitude ); }
    
    string toString() { return "(" ~ x.to!string ~ ", " ~ y.to!string ~ ")"; }
}

class Player {
    string name = "Player";
    Vec pos, dpos;
    
    void addMove(float x, float y) {
        dpos = dpos + Vec(x, y);
    }
    
    void applyMove() {
        if(dpos != Vec.zero) {
            pos = pos + dpos;
            dpos = Vec.zero;
        }
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
    private uint lastShootTime;
    
    private bool[SDL_Keycode] isKeyDown;
    private bool isMouseDown;
    
    enum SHOOT_DELAY = 100; // min milliseconds between shots
    public void tryShoot(Vec pos, Vec direction) {
        if(SDL_GetTicks() - lastShootTime >= SHOOT_DELAY) {
            auto bullet = new Bullet;
            bullet.pos = pos;
            bullet.dpos = direction.normalised * 10;
            bullets ~= bullet;
            
            lastShootTime = SDL_GetTicks();
        }
    }
    
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
                    
                case SDL_MOUSEBUTTONDOWN:
                    isMouseDown = true;
                    break;
                    
                case SDL_MOUSEBUTTONUP:
                    isMouseDown = false;
                    break;
                    
                default:
                    //debug writeln("Unhandled event", event.type);
                    break;
            }
        }
        
        // check if we are shooting (or atleast, attempting to)
        if(isMouseDown == true) {
            int mousex, mousey;
            SDL_GetMouseState( &mousex, &mousey );
            tryShoot( player1.pos, Vec(mousex.to!float, mousey.to!float) - player1.pos );
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
