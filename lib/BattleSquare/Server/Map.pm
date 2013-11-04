package BattleSquare::Server::Map;

use Moo;

has x => (
  is => 'ro',
  required => 1,
);

has y => (
  is => 'ro',
  required => 1,
);

1;
