use strict;
use warnings;

use ExtUtils::MakeMaker;

use Cwd;
use File::Spec;
use Data::Dumper;


sub main {
	# Create the Makefile
	my @args = (
		AUTHOR        => 'Emmanuel Rodriguez <potyl@cpan.org>',
		NAME          => 'Gtk3::WebKit',
		VERSION_FROM  => File::Spec->catfile('lib', 'Gtk3', 'WebKit.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'Gtk3', 'WebKit.pm'),
		LICENSE       => 'perl, lgpl',

		PREREQ_PM     => {
			'Glib::Object::Introspection' => 0,
		},
		PREREQ_FATAL  => 1,

		META_MERGE => {
			resources => {
				homepage    => 'https://github.com/potyl/perl-Gtk3-WebKit',
				bucktracker => 'https://github.com/potyl/perl-Gtk3-WebKit/issues',
				repository  => 'https://github.com/potyl/perl-Gtk3-WebKit',
			},
		},
	);
	WriteMakefile(@args);


	return 0;
}


exit main() unless caller;

