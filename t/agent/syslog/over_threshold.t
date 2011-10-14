use t::Utils;
use Test::More;
use Komainu::Agent::Syslog;
use Mock;

my $mysqld = init_db;
my $mock = Mock->new(+{
    mysqld => $mysqld,
    config => +{
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
        'host1',
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
        'log2',
        '2011-07-07',
        '0'
    ],
    [
        '3',
        'test_role',
        'service',
        'api2',
        'host2',
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
        'log2',
        '2011-07-07',
        '0'
    ]
];
$dbh->do('insert into syslog (id,role,service,component,server,log,logged_on,notifyed) values (?,?,?,?,?,?,?,?)', undef, @{$_}) for @$rows;

my $agent = Komainu::Agent::Syslog->new;

{
    my $rows = $agent->over_threshold($mock);
    note explain $rows;
    is_deeply $rows, [
        {
            'component' => 'api2',
            'logged_on' => '2011-07-07',
            'log'       => 'log1',
            'server'    => 'host1',
            'service'   => 'service'
        },
        {
            'component' => 'api2',
            'logged_on' => '2011-07-07',
            'log'       => 'log2',
            'server'    => 'host1',
            'service'   => 'service'
        },
        {
            'component' => 'api2',
            'logged_on' => '2011-07-07',
            'log'       => 'log1',
            'server'    => 'host2',
            'service'   => 'service'
        },
        {
            'component' => 'api2',
            'logged_on' => '2011-07-07',
            'log'       => 'log2',
            'server'    => 'host2',
            'service'   => 'service'
        }
    ];
    $rows = $agent->over_threshold($mock);
    ok not $rows;
}

$dbh->do('update syslog set notifyed = 0 where id in (1,2,3)');

{
    my $rows = $agent->over_threshold($mock);
    note explain $rows;
    is_deeply $rows, [
        {
            'component' => 'api2',
            'logged_on' => '2011-07-07',
            'log'       => 'log1',
            'server'    => 'host1',
            'service'   => 'service'
        },
        {
            'component' => 'api2',
            'logged_on' => '2011-07-07',
            'log'       => 'log2',
            'server'    => 'host1',
            'service'   => 'service'
        },
        {
            'component' => 'api2',
            'logged_on' => '2011-07-07',
            'log'       => 'log1',
            'server'    => 'host2',
            'service'   => 'service'
        },
    ];
    $rows = $agent->over_threshold($mock);
    ok not $rows;
}

done_testing;

