module battlesquare.basicgame;

import battlesquare.sdl;
import battlesquare.game;
import battlesquare.vec;
import battlesquare.init;
import std.math : sqrt;

class Player {
    string name = "Player";
    Vec pos, dpos;
    
    void addMove(float x, float y) {
        dpos = dpos + Vec(x, y);
    }
    
    void applyMove() {
        if(dpos != Vec.zero) {
            debug trace("Updating ", pos, " with ", dpos); // YAY no more NaNs
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

class Weapon {
    
    void tryShoot(Game game, Player player) {
        
    }
    
}


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
    
    public void render(Renderer rdr) {
        
        // trickery to draw a circle - draw to seperate texture, then copy circle
        Texture windowTexture = rdr.getRenderTarget();
        scope Texture drawTexture = rdr.createTexture(
            SDL_PIXELFORMAT_UNKNOWN, SDL_TEXTUREACCESS_TARGET,
            SCREEN_WIDTH, SCREEN_HEIGHT
        );
        // scope(exit) destroy(drawTexture)
        
        rdr.setRenderTarget(drawTexture);
        
        rdr.setDrawColour(24, 24, 24, 255);
        rdr.clear();
        
        // render bullets
        rdr.setDrawColour(255, 255, 255, 255);
        foreach(bullet; this.bullets) {
            rdr.drawPoint(Vec(bullet.pos.xi, bullet.pos.yi));
        }
        
        // render player1
        enum int PLAYER_SIZE = 24; enum int PLAYER_SIZE_HALF = PLAYER_SIZE/2;
        auto playerRect = Rect(
            Vec( player1.pos.xi - PLAYER_SIZE/2, player1.pos.yi - PLAYER_SIZE/2, ),
            Vec( PLAYER_SIZE, PLAYER_SIZE )
        );
        
        rdr.setDrawColour(0, 255, 0, 255);
        rdr.fillRect( playerRect );
        
        // copy circular area to window
        rdr.setRenderTarget(windowTexture);
        rdr.setDrawColour(0, 0, 0, 0);
        rdr.clear();
        
        foreach(int i; 0 .. SCREEN_HEIGHT/2) {
            // H^2 = X^2 + Y^2
            // Y = Height/2 - i
            // H = k
            // X = sqrt( H^2 - Y^2 )
            immutable real y = to!real( (SCREEN_HEIGHT/2) - i );
            immutable real h = to!real( SCREEN_HEIGHT/2 );
            immutable real x = sqrt( h*h - y*y );
            
            auto row = Rect(
                Vec( (SCREEN_WIDTH/2) - to!int(x), i ),
                Vec( to!int( 2.0 * x ), 1 )
            );
            rdr.copyRect(drawTexture, row, row);
        }
        
        foreach(int i; SCREEN_HEIGHT/2 .. SCREEN_HEIGHT) {
            // Y = (i - Height/2)
            immutable real y = to!real( i - (SCREEN_HEIGHT/2) );
            immutable real h = to!real( SCREEN_HEIGHT/2 );
            immutable real x = sqrt( h*h - y*y );
            
            auto row = Rect(
                Vec( (SCREEN_WIDTH)/2 - to!int(x), i ),
                Vec( to!int( 2.0 * x ), 1 )
            );
            rdr.copyRect(drawTexture, row, row);
        }
               
        rdr.present();
    }
}