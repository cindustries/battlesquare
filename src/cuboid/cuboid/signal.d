module cuboid.signal;

import std.container;
import std.conv : to;
import core.vararg;
import std.traits;

@trusted:

public interface Signal {
    public void registerCallback(A)(A fun);
    public void emit(A...)(A args);
}

private class SignalImlp(T...) : Signal {
    
    alias CallbackT = void delegate(T);
    enum TypeInfo argsType = typeid(T);
    
    private CallbackT[] callbacks;
    
    
    public void registerCallback(A)(A fun) if(
            typeid(ParameterTypeTuple!A) == argsType &&
            typeid(ReturnType!A) == typeid(void)
    ) {
        this.callbacks ~= fun;
    }
    
    public void emit(A...)(A args) if(
        typeid(ParameterTypeTuple!A) == argsType
    ) {
        foreach(cb; this.callbacks) {
            cb(args);
        }
    }
    
}

unittest {
    Signal sig = to!Signal( new SignalImlp!(string, int)() );
    
    bool test1 = false;
    int  test2 = 123;
    
    bool test3 = false;
    int test4 = 321;
    
    sig.registerCallback(
        delegate(bool a, int b) {
            test1 = a;
            test2 = b + 1;
        }
    );
    
    sig.registerCallback(
        delegate(bool a, int b) {
            test3 = a;
            test4 = b + 1;
        }
    );
    
    sig.emit(true, 1336);
    
    assert(test1 == true);
    assert(test2 == 1337);
    assert(test3 == true);
    assert(test4 == 1337);
}


public class SignalManager {
    
    private Signal[string] named;
    
    public Signal createAnonymous(T...)() {
        return to!Signal( new SignalImlp!T() );
    }
    
    public Signal createNamed(T...)(string name) {
        Signal sig = createAnonymous!T();
        this.named[name] = sig;
        return sig;
    }
    
    public Signal getNamed(string name) {
        return this.named[name];
    }
}

unittest {
    auto sigman = new SignalManager();
    auto sig = sigman.createNamed("mySignal");
    
    assert(sigman.getNamed("mySignal") is sig);
}