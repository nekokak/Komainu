package Komainu::Agent::AccesslogSummary;
use strict;
use warnings;
use parent 'Komainu::Agent';

sub run {
    my ($self, $c) = @_;

    my $result = $self->over_threshold($c);
    $c->notify($result) if scalar(@$result);
}

sub over_threshold {
    my ($self, $c) = @_;

    my $dbh = $c->db->dbh;
    my $rows = $dbh->selectall_arrayref(
        q{
            SELECT host, status, path, method, server, SUM(count) current_count
            FROM accesslog
            WHERE
                role      = ?
            AND DATE_FORMAT(logged_at, "%Y-%m-%d") = ?
            GROUP BY host, status, path, method, server
        },
        +{ Slice => +{} },
        $c->role, $c->config->{component}, $c->today, # FIXME yesterday
    );

    $rows;
}

1;

