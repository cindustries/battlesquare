package BattleSquare::Server;

use Moo;
use MooX::Options protect_argv => 0;

use POE;
use Log::Log4perl qw(:easy);
use Data::UUID;

use BattleSquare::Server::Info;
use BattleSquare::Server::Game;
use BattleSquare::Server::Player;

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

has data_uuid => (
  is => 'ro',
  lazy => 1,
  default => sub { Data::UUID->new },
);

has sessions => (
  is => 'ro',
  lazy => 1,
  default => sub {{}},
);

sub login {
  my ( $self, $username ) = @_;
  return "server full" unless (scalar values %{$self->sessions}) <= $self->maxplayers;
  return "username exist" if grep { $_->username eq $username } values %{$self->sessions};
  my $player = BattleSquare::Server::Player->new(
    username => $username,
    connected => $self->game->current_tick,
  );
  my $uuid = $self->data_uuid->create_str;
  $self->sessions->{$uuid} = $player;
  return $uuid;
}

sub logout {
  my ( $self, $uuid ) = @_;
  delete $self->sessions->{$uuid} if exists $self->sessions->{$uuid};
  return "logout";
}

has info => (
  is => 'ro',
  lazy => 1,
  default => sub {
    return BattleSquare::Server::Info->new(
      server => $_[0],
    );
  },
);

has game => (
  is => 'ro',
  lazy => 1,
  default => sub {
    return BattleSquare::Server::Game->new(
      server => $_[0],
    );
  },
);

sub BUILD {
  my ( $self ) = @_;
  Log::Log4perl->easy_init(
    $self->trace
      ? $TRACE
      : $self->debug
        ? $DEBUG
        : $INFO
  );
  DEBUG("Server BUILD");
  $self->info->start;
  $self->game->start;
}

sub run {
  DEBUG("Server run");
  $poe_kernel->run;
}

1;
