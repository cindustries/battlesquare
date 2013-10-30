// Cuboid "ticker" network test (client)
module client;

import std.uuid;
import std.concurrency;
import zmq;
import std.stdio;

struct Message { string abc; UUID what; }

enum numtimes = 4;
enum url = "ipc:///tmp/cdbtestsock";
//enum url = "tcp://127.0.0.1:12344";

void main() {
    // do something
}
