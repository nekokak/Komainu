use t::Utils;
use Test::More;
use Mock;

use Data::Dump qw/dump/;

use Komainu::Agent::Accesslog;

my $mock = Mock->new(+{
    greptime => '10:(05|04|03|02|01):',
    config => +{
        mail_group  => 'accesslog_developersite',
        file        => '/var/log/lighttpd/access_log.ds.%Y%m%d',
        regexp      => '\" (500|404) ',
        service     => 'common',
        component   => 'developersite',
        whitelist   => [qw{
            /robots.txt
            /favicon.ico
            /favicon.gif
            /images/common/form_bg.png
            /pub/admin/common/h1_full.png
            /pub/admin/common/form_bg.png
            /pub/news/atom.xml
        }],
        whitelist_ua => +{
            '^DoCoMo' => [qw{
                /images/upload/
            }],
            '^SoftBank' => [qw{
                /images/upload/
            }],
            '^KDDI' => [qw{
                /images/upload/
            }],
            '^Apple-PubSub' => [qw{
                /pub/news/atom.xml
            }],
        },
        agent       => 'Accesslog',
    }
});


subtest("test for _build_whitelist", sub {
    my $whitelist = Komainu::Agent::Accesslog::_build_whitelist($mock);
    is ( ref $whitelist, "Regexp", "return value is Regexp" );

    ok ( "/robots.txt" =~ /$whitelist/, "matches ok 1");
    ok ( "/pub/news/atom.xml" =~ /$whitelist/, "matches ok 1");
});

subtest("test for _build_whitelist_ua", sub {
    my $whitelist_ua = Komainu::Agent::Accesslog::_build_whitelist_ua($mock);
    is ( ref $whitelist_ua, "HASH", "return value is HashRef" );

    is ( ref $_, "Regexp", "value are Regexp" ) for values %$whitelist_ua;
});

subtest("test for _match_whitelists", sub {
    my $whitelist = Komainu::Agent::Accesslog::_build_whitelist($mock);
    my $whitelist_ua = Komainu::Agent::Accesslog::_build_whitelist_ua($mock);

    do {
        my $log = +{
            useragent => "Mozilla/5.0 kazehakase/0.0.8",
            path => "/images/upload/mobile/0/0/0030e6cd8ae54d6263803e0ec2661290",
        };
        ok ( ! Komainu::Agent::Accesslog::_match_whitelists($log, $whitelist, $whitelist_ua), "kazehakase with whitelisted path: not matches");
    };

    do {
        my $log = +{
            useragent => "DoCoMo/2.0 P903iTV(c100;W24H15)",
            path => "/images/public/mobile/0/0/0030e6cd8ae54d6263803e0ec2661290",
        };
        ok ( ! Komainu::Agent::Accesslog::_match_whitelists($log, $whitelist, $whitelist_ua), "docomo with non-whitelisted path: not matches");
    };

    do {
        my $log = +{
            useragent => "DoCoMo/2.0 P903iTV(c100;W24H15)",
            path => "/images/upload/mobile/0/0/0030e6cd8ae54d6263803e0ec2661290",
        };
        ok ( Komainu::Agent::Accesslog::_match_whitelists($log, $whitelist, $whitelist_ua), "docomo with whitelisted path: matches");
    };

});

done_testing;
