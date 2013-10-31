// Cuboid "ticker" network test (client)
module client;

import zmq;
import ticker;
import protocol;
import std.uuid;

enum string CONNECT_URL = "tcp://localhost:12345";

class Client : ClientEventPumper, TickerApplication {
    
    enum State {
        Invalid,
        Initialised,
        WaitingForHelloReply,
        Normal,
        Exiting
    }
    
    this() {
        globalId = randomUUID(); // eventually this will be a PlayerID.net ID or something
        state = State.Initialised;
    }
    
    UUID globalId;
    
    State state;
    ulong tick;
    
    bool onTick() {
        tick++;
        pumpEvents();
        
        if(state == State.Initialised) {
            //send a hello request
            MHello helloreq = { this.globalId };
            this.send(helloreq);
            
        } else if(state == State.WaitingForHelloReply) {
            // do we need to do something here?
            // maybe retry after a while            
            
        } else if(state == State.Normal) {
            // send a state update
            MClientStateUpdate state;
            
            state.x = 351;
            state.y = 359;
            state.tick = this.tick;
            this.send(state);
            
            
        } else if(state == State.Exiting) {
            MGoodbye goodbye = { this.globalId };
            this.send(goodbye);
            
        }
        
        
        return (state != State.Exiting);
    }
    
    override void onHelloReply(MHelloReply msg) {
        
    }
    
    override void onServerStateUpdate(MServerStateUpdate msg) {
        this.tick = msg.tick;
    }
}


abstract class ClientEventPumper {
        
    Context zmq;
    Dealer socket;
    
    public this() {
        zmq = new Context;
        socket = zmq.createDealer();
        socket.connect(CONNECT_URL);
    }
    
    import std.traits : hasMember;
    import std.string : chompPrefix;
    protected void send(T)(T message) 
    if (is(T == struct)) {        
        MessageClassClient msgclass = mixin("MessageClassClient." ~ chompPrefix(T.stringof,"M"));
        socket.sendMore(msgclass);
        socket.send(message);
    }
    
    protected void pumpEvents() {
        
        // check if we have any messages
        while(socket.canPollIn) {
            auto msgclass = socket.recv!MessageClassServer();
            
            final switch(msgclass) {
                foreach(string mem; __traits(allMembers, MessageClassServer)) {
                    assert(__traits(hasMember, ClientEventPumper, mem));
                    mixin("case MessageClassServer." ~ mem ~ ": this.on" ~ mem ~ "(socket.recv!(M" ~ mem ~ ")()); break;");
                }
            }
        }
    }
    
    
    // horray for macros
    mixin(EventMethodGenerator!MessageClassServer);    
    
    public void destroy() {
        socket.close();
        zmq.destroy();
    }
    
}

private template EventMethodGenerator(alias mcenum) if(is(mcenum == enum)) {
    
    string genAllDefs(members...)() {
        string all = "";
        foreach(string mname; members) {
            all = all ~ "abstract protected void on" ~ mname ~ "(M" ~ mname ~ " msg); ";
        }
        return all;
    }
    
    enum string EventMethodGenerator = genAllDefs!(__traits(allMembers, mcenum))();
}


void main() {
    auto client = new Client;
    scope(exit) client.destroy();
    
    client.runTicker(0.01);
}
