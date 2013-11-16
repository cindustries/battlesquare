// Defines the possible messages
module battlesquare.protocol;

public import std.uuid : UUID;

enum MessageClassClient { // messages that the client recognises
    ServerStateUpdate
}

enum MessageClassServer { // messages that the server recognises
    ClientStateUpdate,
}


// Client's input messages

struct MServerStateUpdate {
    struct Client {
        float x, y, rot;
        int diff;
    }
    
    ulong tick;
    Client[] clients;
}


// Server's input messages

struct MClientStateUpdate {
    ulong tick;
    float x, y, rot;
}