package Komainu::Agent::Syslog;
use strict;
use warnings;
use parent 'Komainu::Agent';
use Time::Seconds;
use Digest::SHA1 qw(sha1_hex);

sub run {
    my ($self, $c) = @_;

    $self->execute($c);

    if (my $result = $self->over_threshold($c)) {
        $c->notify(
            +{
                logs      => $result,
                count     => scalar(@$result),
                service   => $c->config->{service},
                component => $c->config->{component},
            }
        );
    }
}

sub execute {
    my ($self, $c) = @_;

    my $servers = $c->config->{servers};
    my $dbh     = $c->db->dbh;
    my $date    = $c->config->{yesterday} ? $c->date - ONE_DAY : $c->date;

    for my $filename (@{$c->config->{files}}) {

        my $file = $date->strftime($filename);
        my $remote_exec_cmd = _mk_remote_exec_cmd($c, $file);

        for my $server (@$servers) {

            my @logs = split /\n/, $self->remote_exec($server, $remote_exec_cmd);

            for my $line (@logs) {
                my $digest = sha1_hex($line);
                my $rows = $dbh->selectall_arrayref(
                    q{
                        SELECT id 
                        FROM syslog
                        WHERE
                            role      = ?
                        AND service   = ?
                        AND component = ?
                        AND server    = ?
                        AND digest    = ?
                        AND logged_on = ?
                        AND notifyed  = 1
                    },
                    +{ Slice => +{} },
                    $c->role, $c->config->{service}, $c->config->{component}, $server, $digest, $c->today
                );
                next if scalar @$rows;
                $dbh->do(qq{INSERT INTO syslog (role,service,component,server,digest,log,logged_on,notifyed) VALUES(?,?,?,?,?,?,?,0)}, undef,
                    $c->role, $c->config->{service}, $c->config->{component}, $server, $digest, $line, $c->today,
                );
            }
        }
    }
}

sub _mk_remote_exec_cmd {
    my ($c, $file) = @_;
    my $regexp = $c->config->{regexp};
    "test -e $file && /bin/egrep '$regexp' $file"
}

sub over_threshold {
    my ($self, $c) = @_;

    my $dbh = $c->db->dbh;
    my $rows = $dbh->selectall_arrayref(
        q{
            SELECT service, component, server, log, logged_on
            FROM syslog
            WHERE role = ? AND notifyed = 0
        },
        +{ Slice => +{} },
        $c->role,
    );
    return unless scalar @$rows;

    $dbh->do(q{UPDATE syslog SET notifyed = 1 WHERE role = ? AND notifyed = 0}, undef, $c->role);

    $rows;
}

1;

