package Mock;
use strict;
use warnings;
use DBIx::Handler;
use Time::Piece;

sub new {
    my ($class, $opts) = @_;

    my $dt = gmtime(1310000000);
    bless {
        deploy_mode => '',
        service     => '',
        component   => '',
        db          => '',
        mysqld      => '',
        config      => '',
        date        => $dt,
        role        => 'test_role',
        %$opts
    }, $class;
}

sub date  { $_[0]->{date} }
sub today { $_[0]->{date}->strftime('%Y-%m-%d') }
sub now   { $_[0]->{date}->strftime('%Y-%m-%d %H:%M:%S') }
sub role  { $_[0]->{role} }

sub db {
    my $self = shift;
    $self->{db} ||= do {
        DBIx::Handler->new($self->{mysqld}->dsn(dbname => 'komainu_test'),'','',+{AutoCommit => 1,});
    };
}

sub config { $_[0]->{config} }

1;

