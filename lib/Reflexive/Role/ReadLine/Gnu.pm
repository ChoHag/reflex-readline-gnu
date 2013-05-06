package Reflexive::Role::ReadLine::Gnu;

use Reflex::Role;
use Reflex::Timeout;
use Reflex::Callbacks qw/cb_coderef/;
use Reflexive::Event::ReadLine;
use Reflex::Event::EOF;

use Scalar::Util qw(weaken);

# This comes straight out of AnyEvent::ReadLine::Gnu
BEGIN {
  local $ENV{PERL_RL} = "Gnu";

  require Term::ReadLine;
  require Term::ReadLine::Gnu;
}

attribute_parameter att_in      => 'in';
attribute_parameter att_out     => 'out';
attribute_parameter att_name    => 'name';
attribute_parameter att_prompt  => 'prompt';
attribute_parameter att_active  => 'active';
callback_parameter  cb_line     => qw( on att_in line );
callback_parameter  cb_eof      => qw( on att_in eof );
method_parameter    method_hide => qw( hide att_out _ );
method_parameter    method_show => qw( show att_out _ );

role {
  my $p = shift;

  my $att_in     = $p->att_in();
  my $att_out    = $p->att_out();
  my $att_name   = $p->att_name();
  my $att_prompt = $p->att_prompt();
  my $att_active = $p->att_active();
  my $cb_line    = $p->cb_line();
  my $cb_eof     = $p->cb_eof();

  requires $att_in, $att_out, $att_name, $att_prompt, $att_active;
  requires $cb_line, $cb_eof;

  my $method_hide = $p->method_hide();
  my $method_show = $p->method_show();

  my $_rl             = '_rl_' . $att_in;
  my $_rl_builder     = '_build_' . $_rl;
  my $_rl_saved_point = $_rl . '_saved_point';
  my $_rl_saved_line  = $_rl . '_saved_line';
  my $_rl_clear_saved = $_rl . '_clear_saved';
  my $_rl_has_saved   = $_rl . '_has_saved';
  my $method_pause    = $_rl . '_pause';
  my $method_resume   = $_rl . '_resume';
  my $method_stop     = $_rl . '_stop';
  my $method_ready    = '_on' . $_rl . '_readable';

  has $_rl => (
    is         => 'ro',
    isa        => 'Term::ReadLine',
    lazy_build => 1,
  );

  method $_rl_builder => sub {
    my $self = shift;
    Term::ReadLine->new($self->$att_name(), $self->$att_in(), $self->$att_out());
  };


  sub BUILD {}
  after BUILD => sub {
    my $self = shift;
    $self->$_rl->CallbackHandlerInstall($self->$att_prompt(), sub {
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
	$self->$method_stop;
      }
      POE::Kernel->post(
	$self->session_id,
	'call_gate_method',
	$self, $cb, $event
      );
    });
    $self->$method_hide;
    $self->$method_show if $self->$att_active();
  };

  sub DEMOLISH {}
  before DEMOLISH => sub {
    my $self = shift;
    $self->$method_stop();
    $self->callback_handler_remove;
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
    $self->$method_pause();
    $self->$_rl_saved_point($self->$_rl->{point});
    $self->$_rl_saved_line($self->$_rl->{line_buffer});
    $self->$_rl->set_prompt('');
    $self->$_rl->{line_buffer} = '';
    $self->$_rl->redisplay();
  };

  method $method_show => sub {
    my $self = shift;
    if ($self->$_rl_has_saved()) {
      $self->$_rl->set_prompt($self->$att_prompt());
      $self->$_rl->{line_buffer} = $self->$_rl_saved_line();
      $self->$_rl->{point} = $self->$_rl_saved_point();
      $self->$_rl_clear_saved();
      $self->$_rl->redisplay();
    }
    $self->$method_resume;
  };

  method $method_ready => sub {
    my $self = shift;
    $self->$_rl->rl_callback_read_char;
  };

  with 'Reflex::Role::Readable' => {
    active        => 0,
    att_handle    => $att_in,
    cb_ready      => $method_ready,
    method_pause  => $method_pause,
    method_resume => $method_resume,
    method_stop   => $method_stop,
  };
};

1;
