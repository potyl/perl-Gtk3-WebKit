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
use base 'Exporter';

use Glib::Object::Introspection;

our $VERSION = '0.02';


use constant {
    # XPath result types
    ANY_TYPE                       => 0,
    NUMBER_TYPE                    => 1,
    STRING_TYPE                    => 2,
    BOOLEAN_TYPE                   => 3,
    UNORDERED_NODE_ITERATOR_TYPE   => 4,
    ORDERED_NODE_ITERATOR_TYPE     => 5,
    UNORDERED_NODE_SNAPSHOT_TYPE   => 6,
    ORDERED_NODE_SNAPSHOT_TYPE     => 7,
    ANY_UNORDERED_NODE_TYPE        => 8,
    FIRST_ORDERED_NODE_TYPE        => 9,

    # Node type
    ELEMENT_NODE                   => 1,
    ATTRIBUTE_NODE                 => 2,
    TEXT_NODE                      => 3,
    CDATA_SECTION_NODE             => 4,
    ENTITY_REFERENCE_NODE          => 5,
    ENTITY_NODE                    => 6,
    PROCESSING_INSTRUCTION_NODE    => 7,
    COMMENT_NODE                   => 8,
    DOCUMENT_NODE                  => 9,
    DOCUMENT_TYPE_NODE             => 10,
    DOCUMENT_FRAGMENT_NODE         => 11,
    NOTATION_NODE                  => 12,

    # Document position
    DOCUMENT_POSITION_DISCONNECTED => 0x01,
    DOCUMENT_POSITION_PRECEDING    => 0x02,
    DOCUMENT_POSITION_FOLLOWING    => 0x04,
    DOCUMENT_POSITION_CONTAINS     => 0x08,
    DOCUMENT_POSITION_CONTAINED_BY => 0x10,
    DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC => 0x20,
};

# export nothing by default.
# export functions and constants by request.
our %EXPORT_TAGS = (
    xpath_results => [qw{
        ANY_TYPE
        NUMBER_TYPE
        STRING_TYPE
        BOOLEAN_TYPE
        UNORDERED_NODE_ITERATOR_TYPE
        ORDERED_NODE_ITERATOR_TYPE
        UNORDERED_NODE_SNAPSHOT_TYPE
        ORDERED_NODE_SNAPSHOT_TYPE
        ANY_UNORDERED_NODE_TYPE
        FIRST_ORDERED_NODE_TYPE
    }],

    node_types => [qw{
        ELEMENT_NODE
        ATTRIBUTE_NODE
        TEXT_NODE
        CDATA_SECTION_NODE
        ENTITY_REFERENCE_NODE
        ENTITY_NODE
        PROCESSING_INSTRUCTION_NODE
        COMMENT_NODE
        DOCUMENT_NODE
        DOCUMENT_TYPE_NODE
        DOCUMENT_FRAGMENT_NODE
        NOTATION_NODE
    }],

    document_positions => [qw{
        DOCUMENT_POSITION_DISCONNECTED
        DOCUMENT_POSITION_PRECEDING
        DOCUMENT_POSITION_FOLLOWING
        DOCUMENT_POSITION_CONTAINS
        DOCUMENT_POSITION_CONTAINED_BY
        DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC
    }],
);
our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{all} = \@EXPORT_OK;


sub import {
    my %setup = (
        basename  => 'WebKit',
        version   => '3.0',
        package   => __PACKAGE__,
    );

    my @args;
    for (my $i = 0; $i < @_; ++$i) {
        my $arg = $_[$i];
        if (exists $setup{$arg}) {
            $setup{$arg} = $_[++$i];
        }
        else {
            push @args, $arg;
        }
    }

    Glib::Object::Introspection->setup(%setup);

    # Pretend that we're calling Exporter's import
    @_ = @args;
    goto &Exporter::import;
}

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
