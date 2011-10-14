package Komainu::Notify::IRC;
use strict;
use warnings;
use parent 'Komainu::Notify';
use AnyEvent::JSONRPC::Lite;

sub run {
    my ($self, $c, $result) = @_;

    my $body   = $c->render($self->options->{tmpl}, +{result => $result, staff => $self->options->{staff}});
    my $irc    = $self->options->{irc};
    my $client = jsonrpc_client $irc->{host}, $irc->{port};

    my $cnt=0;
    for my $line (split /\n/, $body) {
        $cnt++;
        my $res = $client->call( post => { msg => $line } )->recv;
        if ($cnt>=10) {
             $res = $client->call( post => { msg => 'too many error occured. check email please' } )->recv;
             $res = $client->call( post => { msg => $self->options->{staff}.': ^^' } )->recv;
             last;
        }
    }
}

1;

