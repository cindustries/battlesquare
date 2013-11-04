package BattleSquare::InfoRequest;

use Moo;
use Log::Log4perl qw(:easy);
use POE;
use ZMQ::Constants qw(
  ZMQ_REQ
);

use Data::MessagePack;

with 'POEx::ZMQ3::Role::Emitter';

has port => (
  is => 'ro',
  required => 1,
);
 
has ip => (
  is => 'ro',
  required => 1,
);

has query => (
  is => 'ro',
  required => 1,
);

has callback => (
  is => 'ro',
  required => 1,
);

has connect_to => (
  is => 'ro',
  lazy => 1,
  default => sub { 'tcp://'.$_[0]->ip.':'.$_[0]->port },
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
    zmqsock_connect_added
    zmqsock_recv
    zmqsock_created
    zmqsock_closing
  /], ],
}

sub zmqsock_connect_added { INFO("InfoRequest connected to ".$_[ARG1]) }
sub zmqsock_created { DEBUG("InfoRequest created socket type ".$_[ARG1]) }
sub zmqsock_closing { DEBUG("InfoRequest closing") }

sub zmqsock_recv {
  my ( $self, $alias, $data ) = @_[OBJECT, ARG0 .. $#_];
  DEBUG("InfoRequest receive ".length($data));
  $self->callback->($self->messagepack->unpack($data));
  $self->stop;
}

sub start {
  my ( $self ) = @_;
  DEBUG("InfoRequest start");
  $self->zmq->start;
  $self->zmq->create( $self->alias, ZMQ_REQ );
  $self->_start_emitter;
}

sub stop {
  my ( $self ) = @_;
  DEBUG("InfoRequest stop");
  $self->zmq->stop;
  $self->_shutdown_emitter;
}

sub emitter_started {
  my ( $self ) = @_;
  DEBUG("InfoRequest emitter_started ".$self->ip." ".$self->port);
  $poe_kernel->call( $self->zmq->session_id, subscribe => 'all' );
  $self->add_connect( $self->alias, $self->connect_to );
  $self->zmq->write( $self->alias, $self->query );
}

1;
