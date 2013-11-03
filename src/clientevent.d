module clientevent;

import event;
import ticker;
import zmq;
import protocol;

enum string CONNECT_URL = "tcp://localhost:12345";

// TODO come up with a config system
class ClientEventManager : EventManager {
        
    TickerApplication tickerapp;
    bool doExit = false;
    
    private class Ticker : TickerApplication {
        bool onTick(ulong tick) {
            invoke("onTick", tick);
            return (!doExit);
        }
    }
    
    public this() {
        tickerapp = new this.Ticker;
    }
    
    public void run(double tickrate) {
        this.register("exit", (){ doExit = true; }); // allow us to actually leave the loop
        tickerapp.runTicker(tickrate);
    }
    
}

class ClientMessenger {
    
    private EventManager event;
    private Context zmq;
    private Dealer socket;
    
    public this(EventManager eventManager) {
        event = eventManager;
        event.register("onTick", &this.onTick);
        
        zmq = new Context;
        socket = zmq.createDealer();
        socket.connect(CONNECT_URL);
    }
    
    void onTick(ulong tick) {
        this.pumpEvents();
    }
    
    import std.string : chompPrefix;
    protected void sendToServer(T)(T message) 
    if (is(T == struct)) {        
        //MessageClassServer msgclass = mixin("MessageClassServer." ~ chompPrefix(T.stringof,"M"));
        //socket.sendMore(msgclass);
        socket.send(message);
    }
    
    protected void pumpEvents() {
        
        // check if we have any messages
        while(socket.canPollIn) {
            //auto msgclass = socket.recv!MessageClassClient();
            
            //final switch(msgclass) {
            //    foreach(string mem; __traits(allMembers, MessageClassClient)) {
            //        mixin("case MessageClassClient." ~ mem ~ ": this.event.invoke(\"got" ~ mem ~ "\", socket.recv!(M" ~ mem ~ ")()); break;");
            //    }
            //}
            event.invoke("gotServerStateUpdate", socket.recv!(MServerStateUpdate)());
        }
    }
    
    public void destroy() {
        socket.close();
        zmq.destroy();
        super.destroy();
    }
}