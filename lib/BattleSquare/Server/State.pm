package BattleSquare::Server::State;

use Moo;

has tick => (
  is => 'ro',
  required => 1,
);

has x => (
  is => 'ro',
  required => 1,
);

has y => (
  is => 'ro',
  required => 1,
);

has weapon => (
  is => 'ro',
  required => 1,
);

has rotation => (
  is => 'ro',
  required => 1,
);

1;
