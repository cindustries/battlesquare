module clientevent;

import event;
import ticker;
import zmq;
import protocol;

enum string CONNECT_URL = "tcp://localhost:12345";

// TODO seperate out ZMQ from the generic event system
// ideally the ZMQ manager would be a seperate object to the EM altogether

// TODO come up with a config system
class ClientEventManager : EventManager {
        
    Context zmq;
    Dealer socket;
    TickerApplication tickerapp;
    bool doExit = false;
    
    private class Ticker : TickerApplication {
        bool onTick() {
            pumpEvents();
            invoke("onTick");
            return (!doExit);
        }
    }
    
    public this() {
        zmq = new Context;
        socket = zmq.createDealer();
        socket.connect(CONNECT_URL);
        
        tickerapp = new this.Ticker;
    }
    
    public void run(double tickrate) {
        tickerapp.runTicker(tickrate);
    }
    
    import std.traits : hasMember;
    import std.string : chompPrefix;
    protected void sendToServer(T)(T message) 
    if (is(T == struct)) {        
        MessageClassServer msgclass = mixin("MessageClassServer." ~ chompPrefix(T.stringof,"M"));
        socket.sendMore(msgclass);
        socket.send(message);
    }
    
    protected void pumpEvents() {
        
        // check if we have any messages
        while(socket.canPollIn) {
            auto msgclass = socket.recv!MessageClassClient();
            
            final switch(msgclass) {
                foreach(string mem; __traits(allMembers, MessageClassClient)) {
                    mixin("case MessageClassClient." ~ mem ~ ": this.invoke(\"got" ~ mem ~ "\", socket.recv!(M" ~ mem ~ ")()); break;");
                }
            }
        }
    }
    
    public void destroy() {
        socket.close();
        zmq.destroy();
    }
    
}