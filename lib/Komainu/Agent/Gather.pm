package Komainu::Agent::Gather;
use strict;
use warnings;
use parent 'Komainu::Agent';
use Time::Seconds;

sub run {
    my ($self, $c) = @_;

    my $log = $self->process($c);
    if (scalar(@$log)) {
        $c->notify(
            +{
                logs      => $log,
                service   => $c->config->{service},
                component => $c->config->{component},
            }
        );
    }
}

sub process {
    my ($self, $c) = @_;

    my $servers = $c->config->{servers};
    my $regexp  = $c->config->{regexp};
    my $date    = $c->config->{yesterday} ? $c->date - ONE_DAY : $c->date;

    my @log;
    for my $filename (@{$c->config->{files}}) {

        my $file = $date->strftime($filename);
        my $remote_exec_cmd = _mk_remote_exec_cmd($regexp, $file);

        for my $server (@$servers) {
            my $data = $self->remote_exec($server, $remote_exec_cmd);
            next unless $data;
            push @log, +{
                server => $server,
                data   => $data,
            };
        }
    }
    \@log;
}

sub _mk_remote_exec_cmd {
    my ($regexp, $file) = @_;
    "test -e $file && /bin/egrep '$regexp' $file"
}

1;

