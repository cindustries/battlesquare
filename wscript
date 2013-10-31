def options(opt):
    opt.load('compiler_d')
  
  
def configure(conf):
    conf.load('compiler_d')
  
def build(bld):

    bld.stlib(
        source=[
            'import/derelict/util/exception.d',
            'import/derelict/util/loader.d',
            'import/derelict/util/sharedlib.d',
            'import/derelict/util/system.d',
            'import/derelict/util/wintypes.d',
            'import/derelict/util/xtypes.d'
        ],
        includes=['./import'],
        target='DerelictUtil'
    )

    bld.stlib(
        source=[
            'import/derelict/sdl2/functions.d',
            'import/derelict/sdl2/image.d',
            'import/derelict/sdl2/mixer.d',
            'import/derelict/sdl2/net.d',
            'import/derelict/sdl2/sdl.d',
            'import/derelict/sdl2/ttf.d',
            'import/derelict/sdl2/types.d'
        ],
        includes=['./import'],
        target='DerelictSDL2',
        use='DerelictUtil'
    )


    bld.stlib(
        source='import/msgpack.d',
        target='msgpackd'
    )
    
    bld.stlib(
        source=['src/zmq.d'],
        target='zmqd',
        use='msgpackd', includes=['./src','./import'], lib=['zmq'],
        dflags=['-g']
    )
    
    bld.stlib(
        source='/import/deimos/ev.d',
        target='evd',
        lib='ev'
    )
    
    bld.program(
        source=[
            'src/server.d',
            'src/ticker.d',
            'src/protocol.d'
        ],
        target='server',
        use=['evd', 'DerelictSDL2', 'zmqd', 'msgpackd'],
        includes=['./src','./import'], lib=['zmq', 'ev'],
        dflags=['-g']
    )
    
    bld.program(
        source=[
            'src/client.d',
            'src/ticker.d',
            'src/protocol.d'
        ],
        target='client',
        use=['evd', 'DerelictSDL2', 'zmqd', 'msgpackd'],
        includes=['./src','./import'], lib=['zmq', 'ev'],
        dflags=['-g']
    )