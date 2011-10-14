use t::Utils;
use Test::More;
use Komainu::Agent::Accesslog;


my $log = Komainu::Agent::Accesslog::_parse_accesslog(
    '203.184.141.230 foo.example.com 80 [30/Jun/2011:11:57:35 +0900] "POST /foo/bar HTTP/1.0" 200 146 "Mozilla/5.0 (Windows NT 5.1; rv:5.0) Gecko/20100101 Firefox/5.0" "-" "-" "http://foo.example.com/foo/bar" "-" "-" "-" "-" 4'
);

is_deeply $log, +{
    ip     => '203.184.141.230',
    host   => 'foo.example.com',
    port   => 80,
    date   => '30/Jun/2011:11:57:35 +0900',
    method => 'POST',
    path   => '/foo/bar',
    status => 200,
    useragent => "Mozilla/5.0 (Windows NT 5.1; rv:5.0) Gecko/20100101 Firefox/5.0",
};

done_testing;

