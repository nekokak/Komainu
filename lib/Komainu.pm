package Komainu;
use strict;
use warnings;
use Time::Piece;
use DBIx::Handler;
use Fcntl ":flock";
use Class::Load ();
use Text::Xslate;
use Text::Xslate::Bridge::TT2Like;

our $VERSION = '0.01';

sub new {
    my ($class, $opts) = @_;

    $opts->{date} ||= do { my $dt = localtime; $dt };

    my $self = bless $opts, $class;
    $self->_load_config;
    $self->_lock;
    $self;
}

sub role  { $_[0]->{role} }
sub roles {
    my $self = shift;
    $self->{roles} ||= do {
        [keys %{$self->role_config}]
    };
}

sub global_config { $_[0]->{global_config} }
sub role_config   { $_[0]->{role_config}   }
sub config        { $_[0]->{config}        }

sub date  { $_[0]->{date} }
sub today {
    my $self = shift;
    $self->{today} ||= do {
        $self->{date}->strftime('%Y-%m-%d');
    };
}
sub now {
    my $self = shift;
    $self->{now} ||= do {
        $self->{date}->strftime('%Y-%m-%d %H:%M:00');
    };
}

sub db {
    my $self = shift;
    $self->{db} ||= do {
        DBIx::Handler->new(@{$self->global_config->{connect_info}});
    };
}

sub view {
    my $self = shift;
    $self->{view} ||= do {
        Text::Xslate->new(+{
            syntax   => 'TTerse',
            module   => [ 'Text::Xslate::Bridge::TT2Like' ],
            path     => [ $self->global_config->{tmpl_dir} ],
            function => {
                c => $self,
            },
        });

    };
}

sub render {
    my ($self, $tmpl, $vars) = @_;
    $self->view->render($tmpl, $vars);
}

sub _load_config {
    my $self = shift;

    die 'missing config' unless -f $self->{config_file};
    my $config = do $self->{config_file};
    die 'config should return HASHREF: '. $self->{config_file} unless ref($config) eq 'HASH';

    $self->{role_config}   = $config->{role};
    $self->{global_config} = $config->{global};
}

sub _lock {
    my $self = shift;

    my $filename = sprintf('/tmp/watch_cat_lock_%s', $self->global_config->{agent});
    open my $fh , '>' , $filename or die $!;
    flock( $fh, LOCK_EX|LOCK_NB ) or die "cannot get the lock: $filename\n";
    $self->{_flock} = $fh; # do not close the lock file
}

sub _load_class {
    my ($namespace, $pkg) = @_;

    my $class = $namespace.'::'.$pkg;
    Class::Load::load_class($class);
    $class;
}

sub run {
    my $self = shift;

    for my $role (@{$self->roles}) {
        $self->{role}   = $role;
        $self->{config} = $self->role_config->{$role};

        my $agent_class_s = $self->global_config->{agent};
        die 'missing agent class. role:  ' . $self->role unless $agent_class_s;
        my $agent_class = _load_class('Komainu::Agent', $agent_class_s);
        $agent_class->new()->run($self);
    }
}

sub notify {
    my ($self, $result) = @_;

    my $notify_agents = $self->config->{notify};
    for my $notify (@{$notify_agents}) {
        die 'notify settings must be hashref' unless ref($notify) eq 'HASH';
        my $notify_agent_s = $notify->{class};
        my $options        = $notify->{options} || +{};
        my $notify_agent   = _load_class('Komainu::Notify', $notify_agent_s);
        $notify_agent->new(+{options => $options})->run($self, $result);
    }
}

1;
__END__

=head1 NAME

Komainu -

=head1 SYNOPSIS

  use Komainu;

=head1 DESCRIPTION

Komainu is

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak _at_ gmail _dot_ comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
