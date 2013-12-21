module battlesquare.map;

import battlesquare.sprite;

/+ nay

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

byte[] packMap(TileGridMap map) {
    
    import msgpack;
    import std.array;
    auto packer = packer( appender!(ubyte[])() );
    
    packer.beginArray(4);
    packer.pack(map.tilepx);
    packer.pack(map.numx);
    packer.pack(map.numy);
    packer.beginArray(map.tiles.length);
    
    foreach(Tile tile; map.tiles) {
        packer.packArray(tile.sprite.spriteId);
    }
    
    return packer.stream().data;
}

Map unpackMap(byte[]) {
    
}

+/