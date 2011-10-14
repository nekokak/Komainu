use t::Utils;
use Test::More;
use Komainu::Agent::DeployLog;
use Mock;

my $mysqld = init_db;
my $mock = Mock->new(+{mysqld => $mysqld, deploy_mode => 'start', service => 'sandbox', component => 'api2'});
my $dbh = $mock->db->dbh;
$dbh->do('SET TIMESTAMP = 1302447600');


my $agent = Komainu::Agent::DeployLog->new;

{
    $agent->logged($mock);
    $mock->{deploy_mode} = 'end';
    $agent->logged($mock);

    my $rows = $dbh->selectall_arrayref('select * from deploy_log');
    note explain $rows;
    is_deeply $rows, [
        [
            '1',
            'sandbox',
            'api2',
            '1302447600',
            '1302447600',
        ],
    ];
}

{
    $mock->{deploy_mode} = 'start';
    $agent->logged($mock);

    my $rows = $dbh->selectall_arrayref('select * from deploy_log');
    note explain $rows;
    is_deeply $rows, [
        [
            '1',
            'sandbox',
            'api2',
            '1302447600',
            '1302447600',
        ],
        [
            '2',
            'sandbox',
            'api2',
            '1302447600',
            undef,
        ],
    ];
}

{
    $agent->logged($mock);
    $mock->{deploy_mode} = 'end';
    $agent->logged($mock);

    my $rows = $dbh->selectall_arrayref('select * from deploy_log');
    note explain $rows;
    is_deeply $rows, [
        [
            '1',
            'sandbox',
            'api2',
            '1302447600',
            '1302447600',
        ],
        [
            '2',
            'sandbox',
            'api2',
            '1302447600',
            undef,
        ],
        [
            '3',
            'sandbox',
            'api2',
            '1302447600',
            '1302447600',
        ],
    ];
}

done_testing;

