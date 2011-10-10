package Gtk3::WebKit;

=head1 NAME

Gtk3::WebKit - WebKit bindings for Perl

=head1 SYNOPSIS

	use Gtk3 -init;
	use Gtk3::WebKit;
	
	my ($url) = shift @ARGV || 'http://search.cpan.org/';
	
	my $window = Gtk3::Window->new('toplevel');
	$window->set_default_size(800, 600);
	$window->signal_connect(destroy => sub { Gtk3->main_quit() });
	
	# Create a WebKit widget
	my $view = Gtk3::WebKit::WebView->new();
	
	# Load a page
	$view->load_uri($url);
	
	# Pack the widgets together
	my $scrolls = Gtk3::ScrolledWindow->new();
	$scrolls->add($view);
	$window->add($scrolls);
	$window->show_all();
	
	Gtk3->main();  

=head1 DESCRIPTION

This module provides the Perl bindings for the Gtk3 port of WebKit.

=cut

use warnings;
use strict;

use Glib::Object::Introspection;


our $VERSION = '0.01';


sub import {
    my $class = shift;
    my %args = @_;

    $args{basename} = 'WebKit'    unless exists $args{basename};
    $args{version}  = '3.0'       unless exists $args{version};
    $args{package}  = __PACKAGE__ unless exists $args{package};
    Glib::Object::Introspection->setup(%args);
}

# XS stuff
use base 'DynaLoader';
__PACKAGE__->bootstrap($VERSION);


1;

=head1 BUGS

For any kind of help or support simply send a mail to the gtk-perl mailing
list (gtk-perl-list@gnome.org).

=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Emmanuel Rodriguez.

This library is free software; you can redistribute it and/or modify
it under the same terms of:

=over 4

=item the GNU Lesser General Public License, version 2.1; or

=item the Artistic License, version 2.0.

=back

This module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the GNU Library General Public
License along with this module; if not, see L<http://www.gnu.org/licenses/>.

For the terms of The Artistic License, see L<perlartistic>.

=cut
