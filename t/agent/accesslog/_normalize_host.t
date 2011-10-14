use t::Utils;
use Test::More;
use Komainu::Agent::Accesslog;

my $regexp = '^.+\.(app.sb.mbga-platform.jp|app.mbga-platform.jp)$';

is Komainu::Agent::Accesslog::_normalize_host('app.sb.mbga-platform.jp',$regexp), 'app.sb.mbga-platform.jp';
is Komainu::Agent::Accesslog::_normalize_host('app.mbga-platform.jp',$regexp), 'app.mbga-platform.jp';

is Komainu::Agent::Accesslog::_normalize_host('xxxxxx.app.sb.mbga-platform.jp',$regexp), 'app.sb.mbga-platform.jp';
is Komainu::Agent::Accesslog::_normalize_host('xxxxxx.app.mbga-platform.jp',$regexp), 'app.mbga-platform.jp';

is Komainu::Agent::Accesslog::_normalize_host('xxxxxx.xxxxxx.jp',$regexp), 'xxxxxx.xxxxxx.jp';

done_testing;

