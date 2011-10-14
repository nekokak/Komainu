use t::Utils;
use Test::More;
use Test::Mock::Guard qw/mock_guard/;
use Komainu::Agent::Syslog;
use Komainu::Agent;
use Mock;

my $mysqld = init_db;
my $mock = Mock->new(+{
    mysqld => $mysqld,
    config => +{
        service   => 'service',
        component => 'api2',
        servers   => [qw/host1 host2/],
        regexp    => 'FATAL',
        files     => ['/path/to/file/syslog', ],
    }
});
my $dbh = $mock->db->dbh;

my $mock_guard = mock_guard(
    'Komainu::Agent', +{
        remote_exec => sub {
            my ($self, $host, $cmd) = @_;
            ok $self;
            ok $host;
            ok $cmd;
            "log1\nlog2\nlog1";
        },
    },
);

my $agent = Komainu::Agent::Syslog->new;

{
    $agent->execute($mock);

    my $rows = $dbh->selectall_arrayref('select * from syslog');
    note explain $rows;
    is_deeply $rows,
        [
            [
                '1',
                'test_role',
                'service',
                'api2',
                'host1',
                'f4f1b5fb935f19c3ed564c873a77041e633a2260',
                'log1',
                '2011-07-07',
                '0'
            ],
            [
                '2',
                'test_role',
                'service',
                'api2',
                'host1',
                '8272fbd4ea89b69b3ccf4f94a9578f957614acd7',
                'log2',
                '2011-07-07',
                '0'
            ],
            [
                '3',
                'test_role',
                'service',
                'api2',
                'host1',
                'f4f1b5fb935f19c3ed564c873a77041e633a2260',
                'log1',
                '2011-07-07',
                '0'
            ],
            [
                '4',
                'test_role',
                'service',
                'api2',
                'host2',
                'f4f1b5fb935f19c3ed564c873a77041e633a2260',
                'log1',
                '2011-07-07',
                '0'
            ],
            [
                '5',
                'test_role',
                'service',
                'api2',
                'host2',
                '8272fbd4ea89b69b3ccf4f94a9578f957614acd7',
                'log2',
                '2011-07-07',
                '0'
            ],
            [
                '6',
                'test_role',
                'service',
                'api2',
                'host2',
                'f4f1b5fb935f19c3ed564c873a77041e633a2260',
                'log1',
                '2011-07-07',
                '0'
            ]
        ];
}

done_testing;

