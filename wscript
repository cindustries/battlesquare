
all_includes = [
    'src/battlesquare-client',
    'src/cuboid',
    'src/deimos-ev',
    'src/deimos-zmq',
    'src/DerelictSDL2',
    'src/DerelictUtil',
    'src/msgpack'
]

def options(opt):
    opt.load('compiler_d')
  
  
def configure(conf):
    conf.load('compiler_d')


def build(bld):
    
    bld.stlib(
        source = bld.path.find_node('src/DerelictUtil').ant_glob('**/*.d'),
        includes = all_includes,
        target = 'DerelictUtil',
    )
    
    bld.stlib(
        source = bld.path.find_node('src/DerelictSDL2').ant_glob('**/*.d'),
        includes = all_includes,
        target = 'DerelictSDL2',
        use = 'DerelictUtil',
    )
    
    
    bld.stlib(
        source = 'src/msgpack/msgpack.d',
        target = 'msgpackd',
    )
    
    bld.stlib(
        source = 'src/deimos-ev/deimos/ev.d',
        target = 'evd',
        lib = 'ev',
    )
    
    bld.stlib(
        source = bld.path.find_node('src/cuboid').ant_glob('**/*.d'),
        includes = all_includes,
        
        target = 'cuboid',
        use = ['msgpackd'], 
        lib = ['zmq'],
        dflags = ['-g', '-unittest'],
    )
        
    bld.program(
        
        source = bld.path.find_node('src/battlesquare-client').ant_glob('**/*.d'),
        
        target = 'battlesquare-client',
        use = ['cuboid', 'DerelictSDL2', 'zmqd', 'msgpackd', 'evd'],
        includes = all_includes,
        lib = ['zmq', 'ev'],
        dflags = ['-g', '-unittest'],
    )
