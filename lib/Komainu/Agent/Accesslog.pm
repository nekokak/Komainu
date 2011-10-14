package Komainu::Agent::Accesslog;
use strict;
use warnings;
use parent 'Komainu::Agent';
use Parallel::ForkManager;
use Regexp::Trie;
use Digest::SHA1 qw(sha1_hex);

sub run {
    my ($self, $c) = @_;

    $self->execute($c);
    my $result = $self->over_threshold($c);
    $c->notify($result) if scalar(@$result);
}

sub execute {
    my ($self, $c) = @_;

    my $servers        = $c->config->{servers};
    my $normalize_host = $c->config->{normalize_host};
    my $normalize_path = $c->config->{normalize_path};
    my $remote_exec_cmd = _mk_remote_exec_cmd($c);

    my $whitelist    = _build_whitelist($c);
    my $whitelist_ua = _build_whitelist_ua($c);

    my $pm = Parallel::ForkManager->new($c->config->{workers} || 1);

    for my $server (@$servers) {
        $pm->start and next;

        my @logs = split /\n/, $self->remote_exec($server, $remote_exec_cmd);

        my $rows = +{};
        for my $line (@logs) {
            my $log = _parse_accesslog($line);
            next unless $log;
            next if _match_whitelists($log, $whitelist, $whitelist_ua);

            $log->{path} =~ s/\?.+$//;
            $log->{host} = _normalize_host($log->{host}, $normalize_host) if $normalize_host;
            $log->{path} = _normalize_path($log->{path}, $normalize_path) if $normalize_path;

            $rows->{join "\t", $server, $log->{host}, $log->{status}, $log->{path}, $log->{method}}++;
        }

        for my $key (keys %$rows) {
            _store($c, $key, $rows->{$key});
        }

        $pm->finish;
    }

    $pm->wait_all_children;
}

sub _build_whitelist {
    my $c = shift;

    my $whitelist;

    if (my $list = $c->config->{whitelist}) {
        my $rt = Regexp::Trie->new;
        $rt->add($_) for @$list;
        $whitelist = $rt->regexp;
    }
    return $whitelist;
}

sub _build_whitelist_ua {
    my $c = shift;

    my $whitelist_ua = +{};
    my $whitelist_ua_conf = $c->config->{whitelist_ua};

    for my $key (keys %$whitelist_ua_conf) {
        my $list = $whitelist_ua_conf->{$key};
        my $rt = Regexp::Trie->new;
        $rt->add($_) for @$list;
        $whitelist_ua->{$key} = $rt->regexp;
    }
    return $whitelist_ua;
}

sub _match_whitelists {
    my ($log, $whitelist, $whitelist_ua) = @_;

    return 1 if $whitelist && $log->{path} =~ m/$whitelist/smo;

    for my $ua (keys %$whitelist_ua) {
        my $path_regex = $whitelist_ua->{$ua};
        return 1 if $log->{useragent} =~ /$ua/ && $log->{path} =~ m/$path_regex/smo;
    }

    return 0;
}

sub _mk_remote_exec_cmd {
    my $c = shift;

    my $file   = $c->date->strftime($c->config->{file});
    my $regexp = $c->config->{regexp};

    my $greptime = $c->date->strftime('%H:(');
    my @min;
    for my $i (1..5) {
        my $t = $c->date - (60 * $i);
        push @min, $t->strftime('%M');
    }
    $greptime .= join '|', @min;
    $greptime .= '):';

    "test -e $file && /bin/egrep '$greptime' $file | /bin/egrep '$regexp'"
}

sub _normalize_host {
    my ($host, $normalize_host) = @_;
    $host =~ s/$normalize_host/$1/o;
    $host;
}

sub _normalize_path {
    my ($path, $normalize_path) = @_;
    $path =~ s/$normalize_path/$1/o;
    $path;
}

sub _parse_accesslog {
    my $line = shift;
    chomp $line;
    $line =~ /
        ^
        (\S+)\s     # $1  IP
        (\S+)\s     # $2  HOST
        (\S+)\s     # $3  PORT
        \[(.+)\]\s  # $4  DATE
        \"
        (\S+)\s     # $5  METHOD
        (\S+)\s     # $6  PATH
        (\S+)       # $7  HTTP
        \"\s
        (\S+)\s     # $8  HTTP STATUS
        (\S+)\s     # $9  SIZE
        \"
        (.+?)       # $10 USER AGENT
        \"\s
        .+
        $
    /x or return;

    return +{
        ip     => $1,
        host   => $2,
        port   => $3,
        date   => $4,
        method => $5,
        path   => $6,
        status => $8,
        useragent => $10,
    };
}

sub _store {
    my ($c, $key, $count) = @_;

    my ($server, $host, $status, $path, $method) = split "\t", $key;

    my $dbh = $c->db->dbh;
    $dbh->do(
        'INSERT INTO accesslog (role,service,component,logged_at,host,status,path,method,server,digest,count) VALUES (?,?,?,?,?,?,?,?,?,?,?)', undef,
        $c->role, $c->config->{service}, $c->config->{component}, $c->now, $host, $status, $path, $method, $server, sha1_hex($key), $count
    );
}

sub over_threshold {
    my ($self, $c) = @_;

    my $dbh = $c->db->dbh;

    my $rows = $dbh->selectall_arrayref(
        q{
            SELECT host, status, path, method, server, digest, SUM(count) AS current_count
            FROM accesslog
            WHERE
                role      = ?
            AND logged_at = ?
            GROUP BY host, status, path, method, server, digest
        },
        +{ Slice => +{} },
        $c->role, $c->now,
    );

    my $old_rows = $dbh->selectall_hashref(
        q{
            SELECT digest, SUM(count) AS old_count
            FROM accesslog
            WHERE
                role      = ?
            AND DATE_FORMAT(logged_at, "%Y-%m-%d") = ?
            AND logged_at != ?
            GROUP BY digest
        },
        'digest', undef,
        $c->role, $c->today, $c->now,
    );

    for my $row (@$rows) {
        $row->{old_count} = $old_rows->{$row->{digest}}->{old_count} || 0;
    }

    my $result = [];
    if (my $threshold = $c->config->{threshold}) {
        for my $row (@$rows) {
            unless ($threshold->{$row->{status}}) {
                push @$result, $row;
                next;
            }
            if ($threshold->{$row->{status}} && $threshold->{$row->{status}} <= $row->{current_count}) {
                push @$result, $row;
                next;
            }
        }
    } else {
        $result = $rows;
    }

    $result;
}

1;

