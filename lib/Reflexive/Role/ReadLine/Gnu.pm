package Reflexive::Role::ReadLine::Gnu;

use Reflex::Role;
use Reflexive::Event::ReadLine;
use Reflex::Event::EOF;

# This comes straight out of AnyEvent::ReadLine::Gnu
BEGIN {
  local $ENV{PERL_RL} = "Gnu";

  require Term::ReadLine;
  require Term::ReadLine::Gnu;
}

attribute_parameter att_handle_in  => 'handle_in';
attribute_parameter att_handle_out => 'handle_out';
attribute_parameter att_name       => 'name';
attribute_parameter att_prompt     => 'prompt';
attribute_parameter att_active     => 'active';
callback_parameter  cb_line        => qw( on att_handle line );
callback_parameter  cb_eof         => qw( on att_handle eof );
method_parameter    method_read    => qw( read att_handle _ );
method_parameter    method_hide    => qw( hide att_handle _ );
method_parameter    method_show    => qw( show att_handle _ );

role {
  my $p = shift;

  my $att_handle_in  = $p->att_handle_in();
  my $att_handle_out = $p->att_handle_out();
  my $att_name       = $p->att_name();
  my $att_prompt     = $p->att_prompt();
  my $att_active     = $p->att_active();
  my $cb_line        = $p->cb_line();
  my $cb_eof         = $p->cb_eof();

  requires $att_handle_in, $att_handle_out, $att_name, $att_prompt, $att_active;
  requires $cb_line, $cb_eof;

  my $method_read = $p->method_read();
  my $method_hide = $p->method_hide();
  my $method_show = $p->method_show();

  my $_rl             = '_rl_' . $att_handle_in;
  my $_rl_builder     = '_build_' . $_rl;
  my $_rl_saved_point = $_rl . '_saved_point';
  my $_rl_saved_line  = $_rl . '_saved_line';
  my $_rl_clear_saved = $_rl . '_clear_saved';
  my $_rl_has_saved   = $_rl . '_has_saved';

  has $_rl => (
    is         => 'ro',
    isa        => 'Term::ReadLine',
    lazy_build => 1,
  );

  method $_rl_builder => sub {
    my $self = shift;
    Term::ReadLine->new($self->$att_name(), $self->$att_handle_in(), $self->$att_handle_out());
  };


  sub BUILD {}
  after BUILD => sub {
    my $self = shift;
    $self->$_rl->CallbackHandlerInstall('', sub {
      my $line = shift;
      my ($cb, $event);
      if (defined $line) {
	$cb = $cb_line;
	$event = Reflexive::Event::ReadLine->new(
	  _emitters => [ $self ],
	  line => $line,
	);
      } else {
	$cb = $cb_eof;
	$event = Reflex::Event::EOF->new(
	  _emitters => [ $self ],
	);
	$self->$method_hide;
      }
      POE::Kernel->post(
	$self->session_id,
	'call_gate_method',
	$self, $cb, $event
      );
    });
    $self->$method_show() if $self->$att_active();
  };

  sub DEMOLISH {}
  before DEMOLISH => sub {
    my $self = shift;
    $self->$_rl->callback_handler_remove;
  };

  has $_rl_saved_point => (
    is      => 'rw',
    isa     => 'Num',
    default => 0,
  );

  has $_rl_saved_line => (
    is        => 'rw',
    isa       => 'Str',
    clearer   => $_rl_clear_saved,
    predicate => $_rl_has_saved,
  );

  method $method_hide => sub {
    my $self = shift;
    $self->$_rl_saved_point($self->$_rl->{point});
    $self->$_rl_saved_line($self->$_rl->{line_buffer});
    $self->$_rl->set_prompt('');
    $self->$_rl->{line_buffer} = '';
    $self->$_rl->redisplay;
  };

  method $method_show => sub {
    my $self = shift;
    $self->$_rl->set_prompt($self->$att_prompt());
    if ($self->$_rl_has_saved()) {
      $self->$_rl->{line_buffer} = $self->$_rl_saved_line();
      $self->$_rl->{point} = $self->$_rl_saved_point();
      $self->$_rl_clear_saved();
    }
    $self->$_rl->redisplay;
  };

  method $method_read => sub {
    my $self = shift;
    $self->$_rl->rl_callback_read_char;
  };
};

1;
