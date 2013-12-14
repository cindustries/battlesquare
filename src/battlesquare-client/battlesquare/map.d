module battlesquare.map;

import battlesquare.sprite;

interface Map {
    public void render();
}

class TileGridMap : Map {
private:
    SDL_Renderer* renderer;
    uint tilepx;
    uint numx, numy;
    
    Tile[] tiles;

public:
    struct Tile {
        Sprite sprite;
    }
    
    this(SDL_Renderer* renderer, uint tilepx, uint numx, uint numy) {
        this.renderer = renderer;
        this.tilepx = tilepx;
        this.numx = numx;
        this.numy = numy;
        this.tiles = new Tile[](numx * numy);
    }
    
    void setTile(uint x, uint y, Tile tile) {
        tiles[y*numx + x] = tile;
    }
    
    Tile getTile(uint x, uint y) {
        return tiles[y*numx + x];
    }
    
    void render() {
        foreach(uint y; 0 .. this.numy) {
            foreach(uint x; 0 .. this.numx) {
                auto tile = this.getTile(x, y);
                if(tile.sprite !is null) {
                    tile.sprite.render(SDL_Rect(x*tilepx, y*tilepx, tilepx, tilepx));
                }
            }
        }
    }
    
}