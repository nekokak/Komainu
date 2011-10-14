package Komainu::Agent;
use strict;
use warnings;
use Net::SSH qw/ssh_cmd/;

sub new { bless {}, +shift }

sub remote_exec {
    my ($self, $host, $cmd) = @_;
    ssh_cmd($host, $cmd);
}

1;

