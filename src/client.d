// Cuboid "ticker" network test (client)
module client;

import zmq;
import clientevent;
import protocol;
import std.uuid;

// represents our knowledge of the other players
struct Player {
    float x, y, rot;
}

class Client {
    
    ClientEventManager event;
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
        globalId = randomUUID(); // eventually this will be a PlayerID.net ID or something
        state = State.Initialised;
    }
    
    UUID globalId;
    
    State state;
    ulong tick;
    float x, y, rot;
    
    @event void onTick() {
        tick++;
        
        if(state == State.Initialised) {
            //send a hello request
            MHello helloreq = { this.globalId };
            event.sendToServer(helloreq);
            state = State.WaitingForHelloReply;
            
        } else if(state == State.WaitingForHelloReply) {
            // do we need to do something here?
            // maybe retry after a while            
            
        } else if(state == State.Normal) {
            // send a state update
            MClientStateUpdate state;
            
            state.x = 351;
            state.y = 359;
            state.tick = this.tick;
            event.sendToServer(state);
            
            
        } else if(state == State.Exiting) {
            MGoodbye goodbye = { this.globalId };
            event.sendToServer(goodbye);
            
        }
        
        
        if(state == State.Exiting) {
            event.invoke("exit");
        }
    }
    
    @event void gotHelloReply(MHelloReply msg) {
        state = State.Normal;
    }
    
    @event void gotServerStateUpdate(MServerStateUpdate msg) {
        this.tick = msg.tick;
    }
    
    public void destroy() {
        event.destroy();
    }
}


void main() {
    auto client = new Client;
    scope(exit) client.destroy();
    
    client.run();
}
