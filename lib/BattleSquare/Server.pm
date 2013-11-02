package BattleSquare::Server;

use Moo;
use MooX::Options protect_argv => 0;

use POE;
use DDP;
use ZMQ::Constants qw(
  ZMQ_ROUTER
  ZMQ_IDENTITY
  ZMQ_SNDMORE
);

use POSIX qw( floor );
use Time::HiRes qw( time gettimeofday tv_interval );
use Log::Log4perl qw(:easy);

with 'POEx::ZMQ3::Role::Emitter';

option port => (
  is => 'ro',
  lazy => 1,
  default => sub { 12345 },
  format => 'i',
  short => 'p',
  order => 5,
  documentation => "The port the server runs on (Default: 12345)",
);
 
option ip => (
  is => 'ro',
  lazy => 1,
  default => sub { '*' },
  format => 's',
  short => 'i',
  order => 4,
  documentation => "The IP the server is listening on (by default on all)",
);

option maxplayers => (
  is => 'ro',
  lazy => 1,
  default => sub { 64 },
  format => 'i',
  short => 'm',
  order => 1,
  documentation => "Maximum players on the server (Default: 64)",
);

option debug => (
  is => 'ro',
  lazy => 1,
  order => 98,
  default => sub { 0 },
  documentation => "Show debug information",
);

option trace => (
  is => 'ro',
  lazy => 1,
  order => 99,
  default => sub { 0 },
  documentation => "Show trace information (includes debug)",
);

option gridsize => (
  is => 'ro',
  lazy => 1,
  default => sub { "800x600" },
  format => 's',
  short => 'g',
  order => 2,
  documentation => "Size of the gamefield (Default: 800x600)",
);

has players => (
  is => 'ro',
  lazy => 1,
  default => sub {{}},
);

option tickrate => (
  is => 'ro',
  lazy => 1,
  format => 'i',
  default => sub { 100 },
  short => 't',
  order => 3,
  documentation => "The tickrate of the server (Default: 100)",
);

before options_usage => sub {
  print <<__EOF__;
_______________________________________________________________
  ____        _   _   _      ____                         
 | __ )  __ _| |_| |_| | ___/ ___|  __ _ _   _  __ _ _ __ ___
 |  _ \\ / _` | __| __| |/ _ \\___ \\ / _` | | | |/ _` | '__/ _ \\
 | |_) | (_| | |_| |_| |  __/___) | (_| | |_| | (_| | | |  __/
 |____/ \\__,_|\\__|\\__|_|\\___|____/ \\__, |\\__,_|\\__,_|_|  \\___|
_____________________________________ |_| _____________________ 

by conflict industries                 http://battlesquare.org/

__EOF__
};

has tickdelay => (
  is => 'ro',
  lazy => 1,
  default => sub { 1 / $_[0]->tickrate },
);

has start_time => (
  is => 'ro',
  lazy => 1,
  default => sub { time },
);

sub current_tick {
  my ( $self ) = @_;
  my $diff = time - $self->start_time;
  return floor( $diff / $self->tickdelay );
}

has listen_on => (
  is => 'ro',
  default => sub { 'tcp://'.$_[0]->ip.':'.$_[0]->port },
);

sub build_defined_states {
  my ($self) = @_;
  [ $self => [qw/
    emitter_started
    zmqsock_bind_added
    zmqsock_multipart_recv
    zmqsock_created
    zmqsock_closing
    tick
  /], ],
}

sub BUILD {
  my ( $self ) = @_;
  $self->start;
  $self->start_time;
  Log::Log4perl->easy_init(
    $self->trace
      ? $TRACE
      : $self->debug
        ? $DEBUG
        : $INFO
  );
}

sub zmqsock_bind_added { INFO("Listening to ".$_[ARG1]) }
sub zmqsock_created { DEBUG("Created socket type ".$_[ARG1]) }
sub zmqsock_closing { DEBUG("[".$_[ARG0]."] closing") }

sub zmqsock_multipart_recv {
  my ( $from, $envelope, $data ) = @{$_[ARG1]};
  if ($data eq 'needtick') {
    TRACE("need tick");
  } else {
    my $diff = $_[0]->current_tick - $data;
    TRACE("have diff: ".sprintf("%10d",$diff)) if $diff;
  }
  $_[0]->zmq->write( $_[0]->alias, $from, ZMQ_SNDMORE );
  $_[0]->zmq->write( $_[0]->alias, '', ZMQ_SNDMORE );
  $_[0]->zmq->write( $_[0]->alias, $_[0]->current_tick );
}

sub start {
  my ( $self ) = @_;
  $self->zmq->start;
  $self->zmq->create( $self->alias, ZMQ_ROUTER );
  $self->zmq->set_zmq_sockopt( $self->alias, ZMQ_IDENTITY, 'SERVER' );
  $self->_start_emitter;
}

sub stop {
  my ( $self ) = @_;
  $self->zmq->stop;
  $self->_shutdown_emitter;
}

sub emitter_started {
  my ( $self ) = @_;
  $poe_kernel->call( $self->zmq->session_id, subscribe => 'all' );
  $self->add_bind( $self->alias, $self->listen_on );
  $poe_kernel->delay( tick => 1 );
}

sub tick {
  my ( $self ) = @_;
  TRACE("tick ".$self->current_tick) ;
  $poe_kernel->delay( tick => $self->tickdelay );
}

sub run { $poe_kernel->run }

1;
