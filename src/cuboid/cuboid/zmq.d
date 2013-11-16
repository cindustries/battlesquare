// A quick-n-simple ZMQ wrapper using msgpack for serialisation
module cuboid.zmq;

import deimos.zmq.zmq;
import msgpack;
import std.string;
import std.conv;
import std.stdio;
import std.container;
import std.exception;

enum PACK_FIELD_NAMES = true;

public class Context {
    
    private void* context;
    private auto sockets = make!(SList!Socket);    // keep track of all the sockets, so we can close them on destroy.
    
    
    this() {
        context = zmq_ctx_new();
    }
    
    public void destroy() {
        foreach(Socket s; sockets)
            s.close();
        
        zmq_ctx_destroy(context);
        super.destroy();
    }
    
    public Router createRouter() {
        auto r = new this.Router;
        sockets.insert(r);
        return r;
    }
    
    public Dealer createDealer() {
        auto d = new this.Dealer;
        sockets.insert(d);
        return d;
    }    
    
    private class Socket {
        private void* _socket;
        bool closed = false;
        @property protected void* socket() { return this._socket; }
        
        protected this(int type) {
            this._socket = zmq_socket(context, type);
            checkzmq(this.socket != null, "creating socket");
        }
        
        public void connect(string url) {
            int rc = zmq_connect(this.socket, url.toStringz);
            checkzmq(rc == 0, "connect");
        }
        
        public void bind(string url) {
            int rc = zmq_bind(this.socket, url.toStringz);
            checkzmq(rc == 0, "bind");
        }
        
        
        // Methods to receive data - getting a ubyte[] returns the raw data
        public T recv(T)() if(is(T == ubyte[])) {
            zmq_msg_t message;
            zmq_msg_init(&message);
            scope(exit) { zmq_msg_close(&message); }
            
            zmq_msg_recv(&message, this.socket(), 0);
            
            ubyte[] buffer = (cast(ubyte*) zmq_msg_data(&message))[0 .. zmq_msg_size(&message)];
            return buffer;            
        }
        
        public T recv(T)() if(!is(T == ubyte[])) {
            T what;
            msgpack.unpack( this.recv!(ubyte[])(), what );
            return what;
        }
        
        public void recvEmpty() {
            auto buf = this.recv!(ubyte[])();
            if(buf.length > 0)
                throw new ZMQException("Attempted to receive empty, but got non-empty message.");
        }

        // Methods to send data - if sending a ubyte[], it is treated as raw data
        public void send(T)(T what)     { this.sendGeneric!(T, 0)(what); }
        public void sendMore(T)(T what) { this.sendGeneric!(T, ZMQ_SNDMORE)(what); }
        public void sendEmpty()         { ubyte[] b = []; this.sendGeneric!(ubyte[], 0)(b); }
        
        private void sendGeneric(T, int flags)(T buffer) if (is(T == ubyte[])) {
            zmq_msg_t message;
            zmq_msg_init_data(&message, buffer.ptr, buffer.length, null, null);
            scope(exit) { zmq_msg_close(&message); }
            
            zmq_msg_send(&message, this.socket(), flags);
        }
        
        private void sendGeneric(T, int flags)(T what) if (!is(T == ubyte[])) {
            return sendGeneric!(ubyte[], flags)(msgpack.pack(what));            
        }
        
        // Some options of the socket - TODO implement more/setting options
        private T getOption(T)(int option) {
            T value;
            size_t size = value.sizeof;
            auto ret = zmq_getsockopt(socket, option, &value, &size);
            checkzmq(ret == 0, "get socket option");
            return value;
        }
        
        private void setOption(T)(int option, T value) {
            // TODO
        }
        
        @property public bool receiveMore()     { return (this.getOption!int(ZMQ_RCVMORE) != 0); }
        @property public bool canPollIn()       { return (this.getOption!int(ZMQ_EVENTS) & ZMQ_POLLIN) == ZMQ_POLLIN; }
        @property public bool canPollOut()      { return (this.getOption!int(ZMQ_EVENTS) & ZMQ_POLLOUT) == ZMQ_POLLOUT; }
        
        
        // Closing of the socket - very important!
        public void close() {
            if(closed) return;
            
            int zero = 0;
            zmq_setsockopt(this.socket, ZMQ_LINGER, &zero, zero.sizeof);
            
            zmq_close(_socket);
            _socket = null;
        }
        
    }
    

    public final class Dealer : Socket {
        private this() { super(ZMQ_DEALER); }
    }

    public final class Router : Socket {
        private this() { super(ZMQ_ROUTER); }
    }
    
}

alias Dealer = Context.Dealer;
alias Router = Context.Router;

private void checkzmq(lazy bool success, string action) {
    debug {
        if(!success) {
            //throw new ZMQException("ZMQ " ~ action ~ " failed for some reason");
            throw new ZMQException("[zmq] " ~ action ~ " failed with: " ~ to!string(zmq_strerror(zmq_errno())));        
        }
    }
    
}

public class ZMQException : Exception {
    this(string msg) { super(msg); }
}