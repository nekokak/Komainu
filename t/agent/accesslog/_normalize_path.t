use t::Utils;
use Test::More;
use Komainu::Agent::Accesslog;

my $regexp = '^(/api/restful/v1/[^/]+).+';

is Komainu::Agent::Accesslog::_normalize_path('/api/restful/v1/textdata/@app/@all', $regexp), '/api/restful/v1/textdata';
is Komainu::Agent::Accesslog::_normalize_path('/api/restful/v1/textdata/@app/@all?foo=bar', $regexp), '/api/restful/v1/textdata';
is Komainu::Agent::Accesslog::_normalize_path('/foo/bar/baz/@app/@all', $regexp), '/foo/bar/baz/@app/@all';
is Komainu::Agent::Accesslog::_normalize_path('/foo/bar/baz/?foo=bar', $regexp), '/foo/bar/baz/?foo=bar';

done_testing;

