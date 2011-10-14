package Komainu::Notify;
use strict;
use warnings;

sub new {
    my ($class, $options) = @_;
    bless $options, $class;
}

sub options { $_[0]->{options} }

1;

