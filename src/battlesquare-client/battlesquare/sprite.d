module battlesquare.sprite;

import std.string;
import std.exception : enforce;
import std.conv : to;
public import battlesquare.sdl;

class SpriteSheet {
    private uint numSpriteCols, numSpriteRows;
    private uint spriteWidth, spriteHeight;
    private uint spriteXOffset, spriteYOffset;
    private uint sheetXOffset, sheetYOffset;
    private SDL_Texture* texture;
    private SDL_Renderer* renderer;
    
    public SDL_Renderer* getRenderer() { return this.renderer; }
    
    public this(string path, SDL_Renderer* renderer,
                uint numSpriteCols, uint numSpriteRows,
                uint spriteWidth, uint spriteHeight,
                uint spriteXOffset = 0, uint spriteYOffset = 0,
                uint sheetXOffset = 0, uint sheetYOffset = 0
            )
    in { assert(renderer != null); }
    body {
        this.renderer = renderer;
        
        SDL_Surface* surface = IMG_Load( toStringz(path) );
        enforce(surface != null, "Failed to load image " ~ path ~ "! " ~ to!string(IMG_GetError()) );
        scope(exit) SDL_FreeSurface(surface);
        
        this.texture = SDL_CreateTextureFromSurface(renderer, surface);
        enforceSdl(this.texture != null, "Couldn't convert spritesheet to texture!");
        
        this.numSpriteCols = numSpriteCols;
        this.numSpriteRows = numSpriteRows;
        this.spriteWidth = spriteWidth;
        this.spriteHeight = spriteHeight;
        this.spriteXOffset = spriteXOffset;
        this.spriteYOffset = spriteYOffset;
        this.sheetXOffset = sheetXOffset;
        this.sheetYOffset = sheetYOffset;
    }
    
    public Sprite getSprite(uint id) {
        enforce(id >= 0 && id < (numSpriteCols * numSpriteRows), "Sprite id out of bounds!");
        
        SDL_Rect rect;            
        rect.x = (id % numSpriteCols) * (spriteWidth + spriteXOffset) + sheetXOffset;
        rect.y = (id / numSpriteCols) * (spriteHeight + spriteYOffset) + sheetYOffset;
        rect.w = spriteWidth;
        rect.h = spriteHeight;
        
        return new Sprite(this, rect);
    }
}

class Sprite {
    private SpriteSheet sheet;
    private SDL_Rect area;
    
    private this(SpriteSheet sheet, SDL_Rect area) {
        this.sheet = sheet;
        this.area = area;
    }
    
    public void render(SDL_Rect whereto) {
        enforceSdl( SDL_RenderCopy(sheet.renderer, sheet.texture, &area, &whereto), "Could not render sprite!");
    }
}