module battlesquare.vec;

import std.conv : to;
import std.math : sqrt;

struct Vec {
    
    private float _x = 0, _y = 0;
    public @property float x() { return _x; }
    public @property float y() { return _y; }
    public @property int xi() { return x.to!int; }
    public @property int yi() { return y.to!int; }
    
    static public immutable Vec zero = immutable(Vec)(0.0f, 0.0f);
    
    Vec opUnary(string op)() if(op == "-") {
        return zero - this;
    }
    
    Vec opBinary(string op, T : float)(T val) if(op == "*") {
        return Vec(x*val.to!float, y*val.to!float);
    }
    
    Vec opBinary(string op)(Vec b) if(op == "+") {
        return Vec( this.x + b.x, this.y + b.y ); 
    }
    
    Vec opBinary(string op)(Vec b) if(op == "-") {
        return Vec( this.x - b.x, this.y - b.y );
    }
    
    @property float magnitude() { return sqrt( x*x + y*y ); }
    @property Vec normalised() { return Vec( x/this.magnitude, y/this.magnitude ); }
    
    string toString() { return "(" ~ x.to!string ~ ", " ~ y.to!string ~ ")"; }
}

struct Rect {
    private Vec _pos, _size;
    
    public @property Vec pos() { return _pos; }
    public @property Vec size() { return _size; }
}