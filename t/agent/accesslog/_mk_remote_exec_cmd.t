use t::Utils;
use Test::More;
use Komainu::Agent::Accesslog;
use Mock;

my $mock = Mock->new(+{
    config => +{
        file   => '/path/to/access_log.app.%Y%m%d_%H',
        regexp => '" 500 ',
    }
});

is +Komainu::Agent::Accesslog::_mk_remote_exec_cmd($mock), q{test -e /path/to/access_log.app.20110707_00 && /bin/egrep '00:(52|51|50|49|48):' /path/to/access_log.app.20110707_00 | /bin/egrep '" 500 '};

done_testing;

