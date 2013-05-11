package Reflexive::Role::StreamLining;

use Reflex::Role;

attribute_parameter att_handle_in  => "handle_in";
attribute_parameter att_handle_out => "handle_out";
attribute_parameter att_name       => "name";
attribute_parameter att_prompt     => "prompt";
attribute_parameter att_active     => "active";
callback_parameter  cb_line        => qw( on att_handle_in line );
callback_parameter  cb_eof         => qw( on att_handle_in eof );
method_parameter    method_say     => qw( say att_handle_out _ );
method_parameter    method_pause   => qw( pause att_handle_in _ );
method_parameter    method_resume  => qw( resume att_handle_in _ );
method_parameter    method_stop    => qw( stop att_handle_in _ );

role {
	use feature 'say';

	my $p = shift;

	my $att_handle_in  = $p->att_handle_in();
	my $att_handle_out = $p->att_handle_out();
	my $att_name       = $p->att_name();
	my $att_prompt     = $p->att_prompt();
	my $att_active     = $p->att_active();
	my $cb_line        = $p->cb_line();
	my $cb_eof         = $p->cb_eof();

	requires $att_handle_in, $att_handle_out, $att_name, $att_prompt;
	requires $cb_line, $cb_eof;

	my $method_say      = $p->method_say();

	my $internal_hide   = "_do_${att_handle_in}_hide";
	my $internal_pause  = "_do_${att_handle_in}_pause";
	my $method_pause    = $p->method_pause();

	my $internal_show   = "_do_${att_handle_in}_show";
	my $internal_resume = "_do_${att_handle_in}_resume";
	my $method_resume   = $p->method_resume();

	my $internal_stop   = "_do_${att_handle_in}_stop";
	my $method_stop     = $p->method_stop();

	my $internal_read   = "_on_${att_handle_in}_read";

	with 'Reflex::Role::Collectible';

	with 'Reflexive::Role::ReadLine::Gnu' => {
	  att_handle_in  => $att_handle_in,
	  att_handle_out  => $att_handle_out,
	  att_name    => $att_name,
	  att_prompt  => $att_prompt,
	  att_active  => $att_active,

	  cb_line     => $cb_line,
	  cb_eof      => $cb_eof,

	  method_read => $internal_read,
		method_hide => $internal_hide,
		method_show => $internal_show,
	};

  with 'Reflex::Role::Readable' => {
    att_active    => $att_active,
    att_handle    => $att_handle_in,

    cb_ready      => $internal_read,

    method_pause  => $internal_pause,
    method_resume => $internal_resume,
    method_stop   => $internal_stop,
  };

	method $method_pause => sub {
		my $self = shift;
		$self->$internal_hide;
		$self->$internal_pause;
	};

	method $method_resume => sub {
		my $self = shift;
		$self->$internal_show;
		$self->$internal_resume;
	};

	method $method_stop => sub {
		my $self = shift;
		$self->$internal_hide;
		$self->$internal_stop;
	};

	method $method_say => sub {
		my $self = shift;
		my $has_saved = "_rl_${att_handle_in}_has_saved";
		my $was_hidden = $self->$has_saved;
		$self->$internal_hide unless $was_hidden;
		my $handle = $self->$att_handle_out;
		say $handle $_ foreach @_;
		$self->$internal_show unless $was_hidden;
	};
};

1;
