package Reflex::ReadLine::Gnu;

use Moose;
extends 'Reflex::Base';
use Reflex::Callbacks qw/make_emitter/;

has stdin  => ( is  => 'rw', isa => 'FileHandle', default => sub{\*STDIN} );
has stdout => ( is  => 'rw', isa => 'FileHandle', default => sub{\*STDOUT} );
has name   => ( is  => 'rw', isa => 'Str',        default => sub{'Reflex'} );
has prompt => ( is  => 'rw', isa => 'Str',        default => sub{'> '} );
has active => ( is  => 'rw', isa => 'Bool',       default => sub{1} );

with 'Reflex::Role::ReadLine::Gnu' => {
  att_in      => 'stdin',
  att_out     => 'stdout',
  att_name    => 'name',
  att_prompt  => 'prompt',
  att_active  => 'active',
  cb_line     => make_emitter(on_line => 'line'),
  cb_eof      => make_emitter(on_eof  => 'eof'),
  method_show => 'show',
  method_hide => 'hide',
};

__PACKAGE__->meta->make_immutable;

1;
