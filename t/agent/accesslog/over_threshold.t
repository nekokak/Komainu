use t::Utils;
use Test::More;
use Test::Mock::Guard qw/mock_guard/;
use Komainu::Agent::Accesslog;
use Komainu::Agent;
use Mock;

my $mysqld = init_db;
my $mock = Mock->new(+{
    mysqld => $mysqld,
    config => +{
        role      => 'test_role',
        service   => 'service',
        component => 'api2',
    }
});
my $dbh = $mock->db->dbh;

my $rows = [
    [
        '1',
        'test_role',
        'service',
        'api2',
        'example.com',
        'host1',
        '500',
        '/path/to',
        'GET',
        '2011-07-07 00:53:20',
        '1'
    ],
    [
        '2',
        'test_role',
        'service',
        'api2',
        'example.com',
        'host2',
        '500',
        '/path/to',
        'GET',
        '2011-07-07 00:53:20',
        '2'
    ],
];
$dbh->do('insert into accesslog (id,role,service,component,host,server,status,path,method,logged_at,count) values (?,?,?,?,?,?,?,?,?,?,?)', undef, @{$_}) for @$rows;
$dbh->commit;

my $agent = Komainu::Agent::Accesslog->new;

{
    my $rows = $agent->over_threshold($mock);
    note explain $rows;
    is_deeply $rows, [
        {
            'current_count' => '1',
            'host'          => 'example.com',
            'method'        => 'GET',
            'old_count'     => 0,
            'path'          => '/path/to',
            'server'        => 'host1',
            'status'        => '500',
            'digest'        => '',
        },
        {
            'current_count' => '2',
            'host'          => 'example.com',
            'method'        => 'GET',
            'old_count'     => 0,
            'path'          => '/path/to',
            'server'        => 'host2',
            'status'        => '500',
            'digest'        => '',
        }
    ];
}

$rows = [
    [
        '3',
        'test_role',
        'service',
        'api2',
        'example.com',
        'host1',
        '500',
        '/path/to',
        'GET',
        '2011-07-07 00:58:20',
        '1'
    ],
    [
        '4',
        'test_role',
        'service',
        'api2',
        'example.com',
        'host2',
        '500',
        '/path/to',
        'GET',
        '2011-07-07 00:58:20',
        '2'
    ],
];

$dbh->do('insert into accesslog (id,role,service,component,host,server,status,path,method,logged_at,count) values (?,?,?,?,?,?,?,?,?,?,?)', undef, @{$_}) for @$rows;

{
    my $rows = $agent->over_threshold($mock);
    note explain $rows;
    is_deeply $rows, [
        {
            'current_count' => '1',
            'host'          => 'example.com',
            'method'        => 'GET',
            'old_count'     => 3,
            'path'          => '/path/to',
            'server'        => 'host1',
            'status'        => '500',
            'digest'        => '',
        },
        {
            'current_count' => '2',
            'host'          => 'example.com',
            'method'        => 'GET',
            'old_count'     => 3,
            'path'          => '/path/to',
            'server'        => 'host2',
            'status'        => '500',
            'digest'        => '',
        }
    ];
}

{
    $mock->{config}->{threshold} = +{500 => 2};
    my $rows = $agent->over_threshold($mock);
    note explain $rows;
    is_deeply $rows, [
        {
            'current_count' => '2',
            'host'          => 'example.com',
            'method'        => 'GET',
            'old_count'     => 3,
            'path'          => '/path/to',
            'server'        => 'host2',
            'status'        => '500',
            'digest'        => '',
        }
    ];
}

done_testing;

