// Defines the possible messages
module protocol;

import std.uuid;
import msgpack;

enum MessageClassClient { // messages that the client sends
    MCHello,
    MCClientStateUpdate,
    MCGoodbye
}
    
enum MessageClassServer { // messages that the server sends
    MCHelloReply,
    MCServerStateUpdate
}

// Client to Server
struct Hello { UUID clientId; }

struct ClientStateUpdate {
    ulong tick;
    float x, y;
}

struct Goodbye { UUID clientId; }


// Server to Client
struct HelloReply { ulong tick; }

struct ServerStateUpdate {
    struct Client {
        float x, y;
        int diff;
    }
    
    ulong tick;
    Client[] clients;
}