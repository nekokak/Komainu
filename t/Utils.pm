package t::Utils;
use strict;
use warnings;
use utf8;
use lib qw(./t/ ./t/lib/);
use Test::More;
use Test::mysqld;
use DBI;
use Path::Class;

sub import {
    my $caller = caller(0);

    for my $func (qw/
        init_db
    /) {
        no strict 'refs'; ## no critic.
        *{$caller.'::'.$func} = \&$func;
    }

    strict->import;
    warnings->import;
    utf8->import;
}

sub init_db() { ## no critic.

    my $mysqld = Test::mysqld->new(
        my_cnf => {
            'skip-networking' => '',
        }
    ) or plan skip_all => $Test::mysqld::errstr;

    my $dsn = $mysqld->dsn() . ';mysql_multi_statements=1';
    my $dbh = DBI->connect($dsn, '','',{ RaiseError => 1, PrintError => 0, AutoCommit => 1 });
    $dbh->do('create database komainu_test');

    my $sql = "use komainu_test;\n";
    $sql   .= "set names utf8;\n";
    $sql   .= file('./docs/schema.sql')->slurp;
    $dbh->do($sql);

    $mysqld;
}

1;

