package BattleSquare::Server::Game;

use Moo;
use Log::Log4perl qw(:easy);
use POE;
use ZMQ::Constants qw(
  ZMQ_ROUTER
  ZMQ_IDENTITY
);

use Data::MessagePack;
use Scalar::Util qw( refaddr );
use POSIX qw( floor );
use Time::HiRes qw( time gettimeofday tv_interval );

with 'POEx::ZMQ3::Role::Emitter';

has server => (
  is => 'ro',
  required => 1,
);

has listen_on => (
  is => 'ro',
  lazy => 1,
  default => sub { 'tcp://'.$_[0]->server->ip.':'.($_[0]->server->port+1) },
);

has players => (
  is => 'rw',
  default => sub {[]},
);

has tickdelay => (
  is => 'ro',
  lazy => 1,
  default => sub { 1 / $_[0]->server->tickrate },
);

has start_time => (
  is => 'ro',
  lazy => 1,
  default => sub { time },
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

sub zmqsock_bind_added { INFO("Game listening on ".$_[ARG1]) }
sub zmqsock_created { DEBUG("Game created socket type ".$_[ARG1]) }
sub zmqsock_closing { DEBUG("Game [".$_[ARG0]."] closing") }

sub zmqsock_multipart_recv {
  my ( $from, $envelope, $data ) = @{$_[ARG1]};
  use DDP; p($from); p($envelope); p($data);
}

sub current_tick {
  my ( $self ) = @_;
  my $diff = time - $self->start_time;
  return floor( $diff / $self->tickdelay );
}

sub start {
  my ( $self ) = @_;
  DEBUG("Game start");
  $self->zmq->start;
  $self->zmq->create( $self->alias, ZMQ_ROUTER );
  $self->zmq->set_zmq_sockopt( $self->alias, ZMQ_IDENTITY, 'GAME' );
  $self->_start_emitter;
  $self->start_time;
}

sub stop {
  my ( $self ) = @_;
  DEBUG("Game stop");
  $self->zmq->stop;
  $self->_shutdown_emitter;
}

sub emitter_started {
  my ( $self ) = @_;
  DEBUG("Game emitter_started ".$self->listen_on);
  $poe_kernel->call( $self->zmq->session_id, subscribe => 'all' );
  $self->add_bind( $self->alias, $self->listen_on );
  $self->yield( 'tick' );
}

sub tick {
  my ( $self ) = @_;
  TRACE("tick ".$self->current_tick);
  $self->timer( $self->tickdelay, 'tick' );
}

sub add_player {
  my ( $self, $player ) = @_;
  push @{$self->players}, $player;
  return $self;
}

sub remove_player {
  my ( $self, $player ) = @_;
  $self->players([
    grep {
      refaddr($_) != refaddr($player)
    } @{$self->players}
  ]);
  return $self;
}

1;
