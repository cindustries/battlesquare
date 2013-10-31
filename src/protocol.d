// Defines the possible messages
module protocol;

import std.uuid;
public import std.uuid : UUID;
import msgpack;

enum MessageClassClient { // messages that the client sends
    Hello,
    ClientStateUpdate,
    Goodbye
}
    
enum MessageClassServer { // messages that the server sends
    HelloReply,
    ServerStateUpdate
}

// Client to Server
struct MHello { UUID clientId; }

struct MClientStateUpdate {
    ulong tick;
    float x, y;
}

struct MGoodbye { UUID clientId; }


// Server to Client
struct MHelloReply { ulong tick; }

struct MServerStateUpdate {
    struct Client {
        float x, y;
        int diff;
    }
    
    ulong tick;
    Client[] clients;
}