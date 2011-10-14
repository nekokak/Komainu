package Komainu::Notify::Email;
use strict;
use warnings;
use parent 'Komainu::Notify';
use Email::Sender::Transport::SMTP;
use Email::MIME;
use Email::Sender::Simple 'sendmail';

sub run {
    my ($self, $c, $result) = @_;

    my $body = $c->render($self->options->{tmpl}, +{result => $result});
    my $transport = Email::Sender::Transport::SMTP->new( host => $self->options->{smtp} );
    my $email = Email::MIME->create(
        header => [
            From    => $self->options->{mail_from},
            To      => $self->options->{mail_to},
            Subject => $self->options->{subject},
        ],
        attributes => {
            content_type => 'text/plain',
            charset      => 'ISO-2022-JP',
            encoding     => '7bit',
        },
        body => $body,
    );
    sendmail($email, { transport => $transport });
}

1;

