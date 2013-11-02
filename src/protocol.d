// Defines the possible messages
module protocol;

public import std.uuid : UUID;

enum MessageClassClient { // messages that the client recognises
    HelloReply,
    ServerStateUpdate
}

enum MessageClassServer { // messages that the server recognises
    Hello,
    ClientStateUpdate,
    Goodbye
}


// Client's input messages
struct MHelloReply { ulong tick; }

struct MServerStateUpdate {
    struct Client {
        float x, y;
        int diff;
    }
    
    ulong tick;
    Client[] clients;
}


// Server's input messages
struct MHello { UUID clientId; }

struct MClientStateUpdate {
    ulong tick;
    float x, y;
}

struct MGoodbye { UUID clientId; }