reflex-readline-gnu
===================

Use gnu readline (via Term::ReadLine::Gnu) in Reflex

This is basically a port of AnyEvent::ReadLine::Gnu
(http://search.cpan.org/~mlehmann/AnyEvent-ReadLine-Gnu/) to Reflex
(http://search.cpan.org/~rcaputo/Reflex/). There is also Term::ReadLine::Event
(http://search.cpan.org/~dmcbride/Term-ReadLine-Event/) but I couldn't get that
to work how I wanted. Also I couldn't wrap my head around the event_loop
function in Term::ReadLine.

Whatever counts as mine rather than Marc Lehmann's or Rocco Caputo's is
licenced under the WTFPL version 2. See COPYING for more details.
