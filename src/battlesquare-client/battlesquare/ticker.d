// Generic event-based ticker template, kinda hackey, but that's interfacing with C...
module battlesquare.ticker;

interface TickerApplication {
    bool onTick(ulong tick);
}

    
// Dealing with the event loop
import deimos.ev;

private TickerApplication tickerapp;
private ulong tickNum = 0;
void runTicker(TickerApplication app, double tickrate) {
    
    tickerapp = app;
    
    // initialise event loop, setup tick timer
    ev_loop_t* loop = ev_default_loop(0);
    
    ev_timer tick_watcher;
    ev_timer_init(&tick_watcher, &tick_callback, tickrate, tickrate);
    ev_timer_start(loop, &tick_watcher);
    ev_timer_again(loop, &tick_watcher);
    
    ev_run(loop, 0);
}

extern(C) private void tick_callback(ev_loop_t* loop, ev_timer* timer, int value) {        
    
    auto result = tickerapp.onTick(++tickNum);        
    if(!result) ev_timer_stop(loop, timer);
    
}