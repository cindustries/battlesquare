// Generic event-based ticker template, kinda hackey, but that's interfacing with C...
module ticker;

interface TickerApplication {
    bool onTick();
}

    
// Dealing with the event loop
import deimos.ev;

private TickerApplication tickerapp;
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
    
    auto result = tickerapp.onTick();        
    if(!result) ev_timer_stop(loop, timer);
    
}
