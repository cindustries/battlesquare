// An event system
module battlesquare.event;

import std.conv : to;
import std.traits : ParameterTypeTuple;
import std.container;
import std.typecons;
import std.functional : toDelegate;

class EventManager {
    
    private SList!(DelegateContainer)[string] handlers;
    
    private struct DelegateContainer {
        string name;
        string paramsType;
        void delegate() dg;
    }
    
    public void invokeTuple(T)(string name, T args) {
        return this.invoke(name, args.expand);
    }
    
    public void invoke(T...)(string name, T args) {
        if(name in handlers) {
            foreach(handler; handlers[name]) {
                if(handler.paramsType == T.stringof) {
                    // woot, found a handler - call it!
                    (cast(void delegate(T)) handler.dg)(args);
                }
            }
        }
    }
    
    public void register(T)(string name, T dg) if(!is(T == delegate)) {
        this.register(name, toDelegate(dg));
    }
    
    public void register(T)(string name, T dg) if(is(T == delegate)) {
        DelegateContainer container = { name, ParameterTypeTuple!(T).stringof, cast(void delegate()) dg };
        if(name in handlers) {
            auto list = handlers[name];
            list.insert(container);
            handlers[name] = list;
        } else {
            auto list = make!(SList!DelegateContainer);
            list.insert(container);
            handlers[name] = list;
        }
    }
    
}

unittest {
    import std.stdio;
    import std.typecons;
    auto em = new EventManager;
    
    em.register("print", (string thing) { writeln(thing); });
    em.invoke("print", "hello");
    em.invokeTuple("print", tuple("helloTuple"));
    
    em.register("something", () { writeln("A something"); });
    em.invoke("something");
    
}
