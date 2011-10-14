package Komainu::Agent::MySQLQuery;
use strict;
use warnings;
use parent 'Komainu::Agent';
use Parallel::ForkManager;

sub run {
    my ($self, $c) = @_;

    $self->execute($c);
    my $result = $self->over_threshold($c);
    $c->notify($result) if scalar(@$result);
}

sub execute {
    my ($self, $c) = @_;

    my $servers   = $c->get_servers;
    my $password  = $c->config->{password};
    my $workers   = $c->config->{workers}   || 1;
    my $threshold = $c->config->{threshold} || 2;

    my $pm = Parallel::ForkManager->new($workers);

    for my $server (@$servers) {
        $pm->start and next;

        my $dbh = $c->db->dbh;

        my @logs = split /\n/, `mysql -ugame_r -h$server -p$password -e 'SHOW FULL PROCESSLIST'`;
        shift @logs;

        for my $log (@logs) {
            my @items = split /\t/, $log;
            if ($items[5] && $items[5] =~ /^[0-9]*$/ && $items[5] >= $threshold && $items[4] ne 'Sleep') {
                $dbh->do('insert into mysqlquery_threshold (server, log) values (?,?)', undef, $server, $log);
            }
        }
        $pm->finish;
    }

    $pm->wait_all_children;
}

sub over_threshold {
    my ($self, $c) = @_;

    my $dbh = $c->db->dbh;

    my $rows = $dbh->selectall_arrayref(q{
        SELECT server, log
        FROM mysqlquery_threshold
        ORDER BY server
        },
        +{ Slice => +{} },
    );
    $dbh->do('DELETE FROM mysqlquery_threshold');
    $dbh->disconnect;

    $rows;
}

1;

