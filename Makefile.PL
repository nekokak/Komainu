use inc::Module::Install;
name 'Komainu';
all_from 'lib/Komainu.pm';

requires 'Any::Moose';
requires 'AnyEvent';
requires 'AnyEvent::IRC';
requires 'AnyEvent::JSONRPC::Lite';
requires 'Mouse';
requires 'Path::Class';
requires 'Net::SSH';
requires 'Parallel::ForkManager';
requires 'Email::Sender::Transport::SMTP';
requires 'Email::MIME';
requires 'Email::Sender::Simple';
requires 'Regexp::Trie';
requires 'Class::Load';
requires 'parent';
requires 'Time::Piece';
requires 'DBIx::Handler';
requires 'Text::Xslate';
requires 'Text::Xslate::Bridge::TT2Like';

test_requires 'Test::More' => '0.94';
test_requires 'Test::SharedFork';
test_requires 'Test::Mock::Guard';

tests 't/*.t t/*/*.t';
author_tests('xt');

auto_set_repository;

WriteAll;
