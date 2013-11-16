// Cuboid "ticker" network test (client)
module battlesquare.client;

import cuboid.zmq;
import battlesquare.clientevent;
import battlesquare.protocol;
import std.uuid;
import std.conv : to;
import std.stdio;

// represents our knowledge of the other players
class Player {
    float x, y, rot;
}

class Client {
    
    ClientEventManager event;
    ClientMessenger message;
    
    public void run() {
        event.register("onTick", &this.onTick);
        event.register("gotServerStateUpdate", &this.gotServerStateUpdate);
        event.run(0.01);
    }
    
    // possible states our client can be in
    enum State { Invalid, Normal, Exiting }
    
    this() {
        event = new ClientEventManager;
        message = new ClientMessenger(event);
        
        state = State.Normal;
    }
    
    State state;
    ulong serverTick;   // updated when we get a tick-stamped state update
    Player thisPlayer = new Player;
    
    @event void onTick(ulong tick) {
        writeln("Tick " ~ to!string(tick));
        
        // send a state update
        MClientStateUpdate stateUpdate;
        
        stateUpdate.x = thisPlayer.x;
        stateUpdate.y = thisPlayer.y;
        stateUpdate.tick = this.serverTick;
        message.sendToServer(stateUpdate);
        
        
        if(state == State.Exiting) {
            event.invoke("exit");
        }
    }
    
    @event void gotServerStateUpdate(MServerStateUpdate msg) {
        serverTick = msg.tick;
        // do something about the other clients
    }
    
    public void destroy() {
        message.destroy();
        event.destroy();        
        super.destroy();
    }
}

version(unittest) {
    void main() { writeln("All tests passed! Aparrantly..."); }
} else {


void main() {
    
    auto client = new Client;
    scope(exit) client.destroy();
    
    client.run();
}

}
