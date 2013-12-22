module battlesquare.basicgame;

import battlesquare.sdl;
import battlesquare.game;
import battlesquare.vec;
import battlesquare.init;

import std.math : sqrt;

// this should probably be made a fair bit nicer
final class BasicGame : Game {
    
    private Player player1;
    private Bullet[] bullets;
    private uint lastShootTime;
    
    private Button[] buttons;
    
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
            
            debug trace("Spawned bullet ", bullets.length);
        }
    }
    
    public this() {
        player1 = new Player();
        player1.pos = Vec(255, 255);
    }

    public void update(real delta) {
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
                    debug trace("Unhandled event", event.type);
                    break;
            }
        }
        
        // check if we are pressing buttons
        foreach(button; buttons) {
            if(button.isBeingPressed && isMouseDown == false) {
                button.release();
            }
            else if(!button.isBeingPressed && isMouseDown == true && button.rect.containsPoint( Mouse.position() )) {
                button.press();
            }
        }
        
        // shoot stuff
        if(isMouseDown == true) {            
            tryShoot( player1.pos, Mouse.position() - player1.pos );
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
        
        // trickery to draw a circle - draw to seperate texture, then copy circle
        SDL_Texture* windowTexture = SDL_GetRenderTarget(rdr);
        SDL_Texture* drawTexture = SDL_CreateTexture(rdr, SDL_PIXELFORMAT_UNKNOWN,
                                                     SDL_TEXTUREACCESS_TARGET,
                                                     SCREEN_WIDTH, SCREEN_HEIGHT);
        scope(exit) SDL_DestroyTexture(drawTexture);
        enforceSdl( SDL_SetRenderTarget(rdr, drawTexture), "Failed set draw target");
        
        enforceSdl( SDL_SetRenderDrawColor(rdr, 24, 24, 24, 255), "set colour" );
        enforceSdl( SDL_RenderClear(rdr), "render clear" );
        
        // render bullets
        enforceSdl( SDL_SetRenderDrawColor(rdr, 255, 255, 255, 255), "set colour" );
        foreach(bullet; this.bullets) {
            enforceSdl( SDL_RenderDrawPoint(rdr, bullet.pos.x.to!int, bullet.pos.y.to!int), "draw point (bullet)" );
        }
        
        // render player1
        enum int PLAYER_SIZE = 24; enum int PLAYER_SIZE_HALF = PLAYER_SIZE/2;
        auto rect = SDL_Rect(
            cast(int)(player1.pos.x) - PLAYER_SIZE_HALF,
            cast(int)(player1.pos.y) - PLAYER_SIZE_HALF,
            PLAYER_SIZE,
            PLAYER_SIZE
        );
        
        enforceSdl( SDL_SetRenderDrawColor(rdr, 0, 255, 0, 255), "set colour" );
        enforceSdl( SDL_RenderFillRect(rdr, &rect), "draw rect" );
        
        // copy circular area to window
        enforceSdl( SDL_SetRenderTarget(rdr, windowTexture), "set render target" );
        //enforceSdl( SDL_SetTextureBlendMode(windowTexture, SDL_BLENDMODE_BLEND), "set texture blend mode" );
        enforceSdl( SDL_SetRenderDrawBlendMode(rdr, SDL_BLENDMODE_BLEND), "set render blend mode" );
        enforceSdl( SDL_SetRenderDrawColor(rdr, 0, 0, 0, 0), "set colour" );
        enforceSdl( SDL_RenderClear(rdr), "clear window texture" );
        
        foreach(int i; 0 .. SCREEN_HEIGHT/2) {
            // H^2 = X^2 + Y^2
            // Y = Height/2 - i
            // H = k
            // X = sqrt( H^2 - Y^2 )
            immutable real y = to!real( (SCREEN_HEIGHT/2) - i );
            immutable real h = to!real( SCREEN_HEIGHT/2 );
            immutable real x = sqrt( h*h - y*y );
            
            SDL_Rect row;
            row.x = (SCREEN_WIDTH/2) - to!int(x);
            row.y = i;
            row.w = to!int( 2.0 * x );
            row.h = 1;
            enforceSdl( SDL_RenderCopy(rdr, drawTexture, &row, &row), "copy row" );
        }
        
        foreach(int i; SCREEN_HEIGHT/2 .. SCREEN_HEIGHT) {
            // Y = (i - Height/2)
            immutable real y = to!real( i - (SCREEN_HEIGHT/2) );
            immutable real h = to!real( SCREEN_HEIGHT/2 );
            immutable real x = sqrt( h*h - y*y );
            
            SDL_Rect row;
            row.x = (SCREEN_WIDTH)/2 - to!int(x);
            row.y = i;
            row.w = to!int( 2.0 * x );
            row.h = 1;
            enforceSdl( SDL_RenderCopy(rdr, drawTexture, &row, &row), "copy row" );
        }
               
        SDL_RenderPresent(rdr);
    }
}