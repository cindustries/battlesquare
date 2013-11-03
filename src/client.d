// Cuboid "ticker" network test (client)
module client;

import zmq;
import clientevent;
import protocol;
import std.uuid;
import std.conv : to;
import std.stdio;

// represents our knowledge of the other players
struct Player {
    float x, y, rot;
}

class Client {
    
    ClientEventManager event;
    ClientMessenger message;
    
    public void run() {
        event.register("onTick", &this.onTick);
        event.register("gotHelloReply", &this.gotHelloReply);
        event.register("gotServerStateUpdate", &this.gotServerStateUpdate);
        event.run(0.01);
    }
    
    enum State {
        Invalid,
        Initialised,
        WaitingForHelloReply,
        Normal,
        Exiting
    }
    
    this() {
        event = new ClientEventManager;
        message = new ClientMessenger(event);
        
        globalId = randomUUID(); // eventually this will be a PlayerID.net ID or something
        state = State.Initialised;
    }
    
    UUID globalId;
    
    State state;
    ulong serverTick;   // updated when we get a tick-stamped state update
    float x, y, rot;
    
    @event void onTick(ulong tick) {
        writeln("Tick " ~ to!string(tick));
        
        if(state == State.Initialised) {
            //send a hello request
            MHello helloreq = { this.globalId };
            message.sendToServer(helloreq);
            
            state = State.WaitingForHelloReply;
            
        } else if(state == State.WaitingForHelloReply) {
            // do we need to do something here?
            // maybe retry after a while            
            
        } else if(state == State.Normal) {
            // send a state update
            MClientStateUpdate state;
            
            state.x = 351;
            state.y = 359;
            state.tick = this.serverTick;
            message.sendToServer(state);
            
        } else if(state == State.Exiting) {
            MGoodbye goodbye = { this.globalId };
            message.sendToServer(goodbye);
            
        }
        
        
        if(state == State.Exiting) {
            event.invoke("exit");
        }
    }
    
    @event void gotHelloReply(MHelloReply msg) {
        state = State.Normal;
    }
    
    @event void gotServerStateUpdate(MServerStateUpdate msg) {
        serverTick = msg.tick;
    }
    
    public void destroy() {
        message.destroy();
        event.destroy();        
    }
}


void main() {
    auto client = new Client;
    scope(exit) client.destroy();
    
    client.run();
}
