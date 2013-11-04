package BattleSquare::Server::Info;

use Moo;
use Log::Log4perl qw(:easy);
use POE;
use ZMQ::Constants qw(
  ZMQ_REP
  ZMQ_IDENTITY
);

use Data::MessagePack;
use POSIX qw( floor );

with 'POEx::ZMQ3::Role::Emitter';

has server => (
  is => 'ro',
  required => 1,
);

has listen_on => (
  is => 'ro',
  lazy => 1,
  default => sub { 'tcp://'.$_[0]->server->ip.':'.$_[0]->server->port },
);

has messagepack => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $mp = Data::MessagePack->new;
    $mp->canonical->utf8->prefer_integer;
    return $mp;
  },
);

sub build_defined_states {
  my ($self) = @_;
  [ $self => [qw/
    emitter_started
    zmqsock_bind_added
    zmqsock_recv
    zmqsock_created
    zmqsock_closing
  /], ],
}

sub zmqsock_bind_added { INFO("Info listening on ".$_[ARG1]) }
sub zmqsock_created { DEBUG("Info created socket type ".$_[ARG1]) }
sub zmqsock_closing { DEBUG("Info [".$_[ARG0]."] closing") }

sub zmqsock_recv {
  my ( $self, $alias, $data ) = @_[OBJECT, ARG0 .. $#_];
  DEBUG("Info receive '".$data."'");
  my $return = 'unknown';
  my @args = split(/ +/,$data);
  if (scalar @args == 1 and $args[0] eq 'info') {
    my $current_tick = $self->server->game->current_tick;
    $return = {
      tick => $current_tick,
      seconds => floor( $current_tick * $self->server->tickrate ),
      maxplayers => $self->server->maxplayers,
      tickrate => $self->server->tickrate,
      players => [
        map { $_->public_info }
        sort { $a->kills <=> $b->kills || $b->deaths <=> $a->deaths }
        @{$self->server->game->players}
      ],
      gridsize => $self->server->gridsize,
    };
  } elsif (scalar @args == 2 and $args[0] eq 'login') {
    $return = $self->server->login($args[1]);
  } elsif (scalar @args == 2 and $args[0] eq 'logout') {
    $return = $self->server->logout($args[1]);
  } elsif (scalar @args > 2 and $args[0] eq 'admin') {
    if ($self->server->adminpw && $self->server->adminpw eq $args[1]) {
      if (scalar @args == 3 and $args[2] eq 'sessions') {
        $return = {
          map { $_, $self->server->sessions->{$_}->username }
          keys %{$self->server->sessions}
        };
      }
    } else {
      $return = 'failed';
    }
  }
  $self->zmq->write( $_[0]->alias, $self->messagepack->pack($return) );
}

sub start {
  my ( $self ) = @_;
  DEBUG("Info start");
  $self->zmq->start;
  $self->zmq->create( $self->alias, ZMQ_REP );
  $self->zmq->set_zmq_sockopt( $self->alias, ZMQ_IDENTITY, 'INFO' );
  $self->_start_emitter;
}

sub stop {
  my ( $self ) = @_;
  DEBUG("Info stop");
  $self->zmq->stop;
  $self->_shutdown_emitter;
}

sub emitter_started {
  my ( $self ) = @_;
  DEBUG("Info emitter_started ".$self->listen_on);
  $poe_kernel->call( $self->zmq->session_id, subscribe => 'all' );
  $self->add_bind( $self->alias, $self->listen_on );
}

1;
