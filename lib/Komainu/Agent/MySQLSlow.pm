package Komainu::Agent::MySQLSlow;
use strict;
use warnings;
use parent 'App::WatchCat::Agent';
use Path::Class;

sub run {
    my ($self, $c) = @_;

    my $result = $self->execute($c);
    if (scalar(@$result)) {
        $c->notify($result);
    }
}

sub execute {
    my ($self, $c) = @_;

    my $servers        = $c->config->{servers};
    my $password       = $c->config->{password};
    my $slowlogfile    = $c->config->{slowlogfile};
    my $log_dir        = $c->config->{log_dir};
    my $mv_slowlogfile = file($log_dir, $c->date->strftime('mysqld-slow.log.%Y%m%d'));

    die "missing password..." unless $password;

    my @result;
    for my $server (@$servers) {
        eval {
            my $log = $self->remote_exec($server, "test -e $slowlogfile && mysqldumpslow $slowlogfile 2> /dev/null");
            if ( $log !~ /^Count: 1  Time=0.00s \(0s\)  Lock=0.00s \(0s\)  Rows=0.0 \(0\), 0users\@0hosts/ ) {
                push @result, +{server => $server, log => $log};
            }
            $self->remote_exec($server, "test -e $slowlogfile && mkdir -p $log_dir && mv $slowlogfile $mv_slowlogfile && mysqladmin -uroot -p$password flush-logs");
        };
        if ($@) {
            warn sprintf('remote_exec error: server: %s, msg: %s', $server, $@);
        }
    }

    \@result;
}

1;

