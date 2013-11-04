package BattleSquare::Server::Player;

use Moo;

has username => (
  is => 'ro',
  required => 1,
);

has connected => (
  is => 'ro',
  required => 1,
);

has last_state => (
  is => 'rw',
);

sub add_state {
  my ( $self, $state ) = @_;
  $self->last_state($self);
  return $self;
}

1;
