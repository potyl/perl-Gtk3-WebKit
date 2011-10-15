#!/usr/bin/env perl

=head1 NAME

browser.pl - Embed a webkit widget in an application

=head1 SYNOPSIS

    browser.pl [URL]

Simple usage:

    browser.pl http://search.cpan.org/

=head1 DESCRIPTION

Display a web page.

=cut

use strict;
use warnings;

use Gtk3 -init;
use Gtk3::WebKit;
use JSON qw(decode_json);
use Data::Dumper;

sub main {
    my ($url) = shift @ARGV || 'http://search.cpan.org/';

    my $window = Gtk3::OffscreenWindow->new('toplevel');
    $window->set_default_size(800, 600);
    $window->signal_connect(destroy => sub { Gtk3->main_quit() });

    # Create a WebKit widget
    my $view = Gtk3::WebKit::WebView->new();

    $view->signal_connect('notify::load-status' => sub {
        return unless $view->get_uri and ($view->get_load_status eq 'finished');

        Gtk3->main_quit();

        print "Document loaded\n";
        my $frame = $view->get_main_frame();
        print "Frame is $frame\n";
        my $json = $frame->JSEvaluateScript(
#            q{ window.document.getElementsByTagName('title'); },
            q{
                var array = [ 2, 4, 8, ];

                [
                    'a', 'b', 'c',
                    [ 9, 8, 7, [ array ] ],
                    [ 10, 20, 30, ],
                    [ 'abcd', array, 'efgh', ],
                ];

                window.document.getElementsByTagName('title');
            },
#            q({'one': 22};),
        );
        print "GOT: ", Dumper($json);
        #my $data = $json eq '' ? '' : decode_json($json);
        #print "Data: ", Dumper($data);
    });

    # Load a page
    $view->load_uri($url);

    # Pack the widgets together
    my $scrolls = Gtk3::ScrolledWindow->new();
    $scrolls->add($view);
    $window->add($scrolls);
    $window->show_all();

    Gtk3->main();
    return 0;
}


exit main() unless caller;
