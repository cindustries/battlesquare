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

// TODO : move to a proper event/message system
final class Server : ServerEventPumper, TickerApplication {
    
    private ulong tick;
    ClientState[int] clients;
    
    public bool onTick() {
        this.pumpEvents();
        tick++;
        writeln("Tick - " ~ to!string(tick));
        
        MServerStateUpdate state;
        foreach(int client; clients.keys)
            this.send(client, state);
        
        return (tick < 10);
    }
    
    override void onHello(int from, MHello msg) {
        clients[from] = new ClientState(msg.clientId);
        clients[from].state = ClientState.State.WaitingForUpdates;
    }
    
    override void onClientStateUpdate(int from, MClientStateUpdate msg) {
        ClientState client = clients[from];
        client.state = ClientState.State.GettingUpdates;
        
        client.tick = msg.tick;
        client.x = msg.x;
        client.y = msg.y;
    }
    
    override void onGoodbye(int from, MGoodbye msg) {
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
    
    import std.traits : hasMember;
    import std.string : chompPrefix;
    protected void send(T)(int to, T message) 
    if (is(T == struct)) {        
        MessageClassServer msgclass = mixin("MessageClassServer." ~ chompPrefix(T.stringof, "M"));
        socket.sendMore(to);
        socket.sendEmpty();
        socket.sendMore(msgclass);
        socket.send(message);
    }
    
    protected void pumpEvents() {
        
        // check if we have any messages
        while(socket.canPollIn) {
            auto id = socket.recv!int();
            socket.recvEmpty();
            auto msgclass = socket.recv!MessageClassClient();
            
            final switch(msgclass) {
                foreach(string mem; __traits(allMembers, MessageClassClient)) {
                    assert(__traits(hasMember, ServerEventPumper, mem));
                    mixin("case MessageClassClient." ~ mem ~ ": on" ~ mem ~ "(id, socket.recv!(M" ~ mem ~ ")()); break;");
                }
            }
        }
    }
    
    
    // horray for macros
    mixin(EventMethodGenerator!MessageClassClient);    
    
    public void destroy() {
        socket.close();
        zmq.destroy();
    }
    
}

private template EventMethodGenerator(alias mcenum) if(is(mcenum == enum)) {
    
    string genAllDefs(members...)() {
        string all = "";
        foreach(string mname; members) {
            all = all ~ "abstract protected void on" ~ mname ~ "(int from, M" ~ mname ~ " msg); ";
        }
        return all;
    }
    
    enum string EventMethodGenerator = genAllDefs!(__traits(allMembers, mcenum))();
}

void main() {
        
    auto server = new Server;
    scope(exit) server.destroy();
    
    server.runTicker(TICKRATE); // gotta love such hax
    
}
