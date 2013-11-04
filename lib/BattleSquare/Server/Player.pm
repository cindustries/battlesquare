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

has kills => (
  is => 'rw',
  lazy => 1,
  default => sub { 0 },
);
sub add_kill { $_[0]->kills($_[0]->kills+1) }

has deaths => (
  is => 'rw',
  lazy => 1,
  default => sub { 0 },
);
sub add_deaths { $_[0]->deaths($_[0]->deaths+1) }

sub add_state {
  my ( $self, $state ) = @_;
  $self->last_state($self);
  return $self;
}

sub public_info {
  my ( $self ) = @_;
  return {
    username => $self->username,
    connected => $self->connected,
    kills => $self->kills,
    deaths => $self->deaths,
  };
}

1;
