// BattleSquare server thing
module server;

import zmq;
import ticker;
import protocol;
import std.stdio, std.conv, std.container, std.uuid;

enum string BIND_URL = "tcp://*:12345";
enum double TICKRATE = 1.0/100.0;

private class ClientState {
    enum State {
        Invalid,
        Initial,
        SaidHello,
        WaitingForUpdates,
        GettingUpdates
    };
    
    this(UUID id) {
        globalId = id;
        state = State.Initial;
    }
    
    State state = State.Invalid;
    
    ulong tick;
    float x, y;
    
    UUID globalId;
    int routerId;
}

final class Server : ServerEventPumper, TickerApplication {
    
    private ulong ticknum;
    ClientState[int] clients;
    
    public bool onTick() {
        this.pumpEvents();
        return true;
    }
    
    override void onHello(int from, Hello msg) {
        clients[from] = new ClientState(msg.clientId);
        clients[from].state = ClientState.State.WaitingForUpdates;
    }
    
    override void onClientStateUpdate(int from, ClientStateUpdate msg) {
        ClientState client = clients[from];
        client.state = ClientState.State.GettingUpdates;
        
        client.tick = msg.tick;
        client.x = msg.x;
        client.y = msg.y;
    }
    
    override void onGoodbye(int from, Goodbye msg) {
        clients.remove(from);
    }
    
}

abstract class ServerEventPumper {
    
    Context zmq;
    Router socket;
    
    public this() {
        zmq = new Context;
        socket = zmq.createRouter();
        socket.bind(BIND_URL);
    }
    
    protected void pumpEvents() {
        // check if we have any messages
        while(socket.canPollIn) {
            auto id = socket.recv!int();
            socket.recvEmpty();
            auto msgclass = socket.recv!MessageClassClient();
            
            final switch(msgclass) {
                case MessageClassClient.MCHello:                onHello(id, socket.recv!Hello()); break;
                case MessageClassClient.MCClientStateUpdate:    onClientStateUpdate(id, socket.recv!ClientStateUpdate()); break;
                case MessageClassClient.MCGoodbye:              onGoodbye(id, socket.recv!Goodbye()); break;
            }
        }
    }
    
    abstract protected void onHello(int from, Hello msg);
    abstract protected void onClientStateUpdate(int from, ClientStateUpdate msg);
    abstract protected void onGoodbye(int from, Goodbye msg);
    
    
    public void destroy() {
        socket.close();
        zmq.destroy();
    }
    
}

void main() {
    
    auto server = new Server;
    scope(exit) server.destroy();
    
    server.runTicker(TICKRATE); // gotta love such hax
    
}
