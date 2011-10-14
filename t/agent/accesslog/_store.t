use t::Utils;
use Test::More;
use Komainu::Agent::Accesslog;
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

Komainu::Agent::Accesslog::_store($mock, join("\t", 'host1','example.com','500','/bar/bal','GET'), 1);
my $rows = $dbh->selectall_arrayref('select * from accesslog');

is_deeply $rows, [
    [ 
        '1',
        'test_role',
        'service',
        'api2',
        'example.com',
        'host1',
        '500',
        '/bar/bal',
        'GET',
        '2011-07-07 00:53:20',
        '1',
        '0f6ca374bab5306fd5939be9e447fbe3c90a7efc',
    ]
];

Komainu::Agent::Accesslog::_store($mock, join("\t", 'host2','example.com','500','/bar/bal','GET'), 10);
$rows = $dbh->selectall_arrayref('select * from accesslog');
is_deeply $rows,  [
    [
        '1',
        'test_role',
        'service',
        'api2',
        'example.com',
        'host1',
        '500',
        '/bar/bal',
        'GET',
        '2011-07-07 00:53:20',
        '1',
        '0f6ca374bab5306fd5939be9e447fbe3c90a7efc',
    ],
    [
        '2',
        'test_role',
        'service',
        'api2',
        'example.com',
        'host2',
        '500',
        '/bar/bal',
        'GET',
        '2011-07-07 00:53:20',
        '10',
        '2f192704c5c5d67bdd387d22d7b89e46796eb086',
    ]
];

done_testing;

