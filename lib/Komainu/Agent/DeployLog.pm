package Komainu::Agent::DeployLog;
use strict;
use warnings;
use parent 'Komainu::Agent';

sub logged {
    my ($self , $c) = @_;

    my $dbh       = $c->db->dbh;
    my $mode      = $c->{deploy_mode};
    my $service   = $c->{service};
    my $component = $c->{component};

    if ($mode eq 'start') {
        $dbh->do('INSERT INTO deploy_log (service, component, started_at) VALUES (?,?,UNIX_TIMESTAMP())', undef, $service, $component);
    } else {
        my $row = $dbh->selectrow_arrayref(
            'SELECT id FROM deploy_log WHERE service = ? AND component = ? AND ended_at IS NULL ORDER BY id DESC LIMIT 1',
            undef,
            $service, $component
        );
        $dbh->do('UPDATE deploy_log set ended_at = UNIX_TIMESTAMP() WHERE id = ?', undef, $row->[0]);
    }
}

1;

