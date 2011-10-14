use t::Utils;
use Test::More;
use Komainu::Agent::Syslog;
use Mock;

my $mock = Mock->new(+{
    config => +{
        regexp => ' target ',
    }
});

is +Komainu::Agent::Syslog::_mk_remote_exec_cmd($mock, '/path/to/file'), q{test -e /path/to/file && /bin/egrep ' target ' /path/to/file};

done_testing;

