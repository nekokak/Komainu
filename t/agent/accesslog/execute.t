use t::Utils;
use Test::More;
use Test::SharedFork;
use Test::Mock::Guard qw/mock_guard/;
use Komainu::Agent::Accesslog;
use Mock;

my $mysqld = init_db;
my $mock = Mock->new(+{
    mysqld => $mysqld,
    config => +{
        role      => 'test_role',
        service   => 'service',
        component => 'api2',
        servers   => [qw/host1 host2/],
    }
});
my $dbh = $mock->db->dbh;

my $mock_guard = mock_guard(
    'Komainu::Agent::Accesslog', +{
        _mk_remote_exec_cmd => sub {
            'foo'
        },
        remote_exec => sub {
            join "\n", 
              '203.184.141.230 foo.example.com 80 [30/Jun/2011:11:57:35 +0900] "POST /foo/bar HTTP/1.0" 200 146 "Mozilla/5.0 (Windows NT 5.1; rv:5.0) Gecko/20100101 Firefox/5.0" "-" "-" "http://foo.example.com/foo/bar" "-" "-" "-" "-" 4"',
              '203.184.141.230 foo.example.com 80 [30/Jun/2011:11:57:35 +0900] "POST /hog/mog HTTP/1.0" 200 146 "Mozilla/5.0 (Windows NT 5.1; rv:5.0) Gecko/20100101 Firefox/5.0" "-" "-" "http://foo.example.com/hog/mog" "-" "-" "-" "-" 4"';
        },
    },
);

my $agent = Komainu::Agent::Accesslog->new;

{
    $agent->execute($mock);

    my $rows = $dbh->selectall_arrayref('select * from accesslog');
    note explain $rows;
    is_deeply $rows, [
        [
            '1',
            'test_role',
            'service',
            'api2',
            'foo.example.com',
            'host1',
            '200',
            '/hog/mog',
            'POST',
            '2011-07-07 00:53:20',
            '1',
            '07b85eb7ebff859706f1cbdd2ce5e9052df53a69',
        ],
        [
            '2',
            'test_role',
            'service',
            'api2',
            'foo.example.com',
            'host1',
            '200',
            '/foo/bar',
            'POST',
            '2011-07-07 00:53:20',
            '1',
            'ef16cab2593fe4fccbc8f1ac6827a02f6cd1a792',
        ],
        [
            '3',
            'test_role',
            'service',
            'api2',
            'foo.example.com',
            'host2',
            '200',
            '/foo/bar',
            'POST',
            '2011-07-07 00:53:20',
            '1',
            '52e64b33ea3cc29bd68348ba9b06bd90b526fd0c',
        ],
        [
            '4',
            'test_role',
            'service',
            'api2',
            'foo.example.com',
            'host2',
            '200',
            '/hog/mog',
            'POST',
            '2011-07-07 00:53:20',
            '1',
            '6502899e3112be5cd13d79c330b128742fa3652d',
        ]
    ];
}

$dbh->do('delete from accesslog');
$dbh->commit;

{
    $mock->{config}->{workers} = 2;
    $agent->execute($mock);

    my $rows = $dbh->selectall_arrayref('select role, server,host,status,path,method,count from accesslog order by server, path');
    note explain $rows;
    is_deeply $rows, [
        [
            'test_role',
            'host1',
            'foo.example.com',
            '200',
            '/foo/bar',
            'POST',
            '1'
        ],
        [
            'test_role',
            'host1',
            'foo.example.com',
            '200',
            '/hog/mog',
            'POST',
            '1'
        ],
        [
            'test_role',
            'host2',
            'foo.example.com',
            '200',
            '/foo/bar',
            'POST',
            '1'
        ],
        [
            'test_role',
            'host2',
            'foo.example.com',
            '200',
            '/hog/mog',
            'POST',
            '1'
        ]
    ];
}

done_testing;

