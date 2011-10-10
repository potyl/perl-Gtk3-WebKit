use strict;
use warnings;

use ExtUtils::MakeMaker;

use Cwd;
use File::Spec;
use Data::Dumper;

use Glib::CodeGen;
use Glib::MakeHelper;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;

my $DEPENDS;
my @XS_FILES = ();


sub main {


	# Create the build folder used by the code generation utilities
	mkdir 'build', 0777;

	# Find the C libraries
	my @typemaps = ();
	my @deps = ('Glib');
	my %pkgconfig;
	my %requires = (
		'Glib::Object::Introspection' => 0,
	);

	eval {
		%pkgconfig = ExtUtils::PkgConfig->find("webkitgtk-3.0");
		push @XS_FILES, <xs/*.xs>;
		push @typemaps, 'maps';
		push @deps, 'Glib';
		$requires{Glib} = '1.000';
	};
	if (my $error = $@) {
		warn "FAIL: ", $error;
		return;
	}

	foreach my $module (keys %requires) {
		my $version = $requires{$module};
		eval "use $module '$version'; 1;" or die "Can't load $module $version\n";
	}

	$DEPENDS = ExtUtils::Depends->new('Gtk3::WebKit', @deps);
	$DEPENDS->add_pm(
		File::Spec->catfile('lib', 'Gtk3', 'WebKit.pm'),
		File::Spec->catfile('$(INST_LIBDIR)', 'WebKit.pm'),
	);

	# Code generation
	Glib::CodeGen->parse_maps('webkit', input => [ @typemaps ]);
	Glib::CodeGen->write_boot(
		xs_files => [ @XS_FILES ],
		ignore   => qr/^Gtk3::WebKit$/,
	);


	$DEPENDS->set_inc($pkgconfig{cflags} . ' -I./build');
	$DEPENDS->set_libs($pkgconfig{libs});
	$DEPENDS->add_xs(@XS_FILES);
	$DEPENDS->add_typemaps(
		File::Spec->catfile(cwd(), 'build', 'webkit.typemap')
	);
	$DEPENDS->install(
		File::Spec->catfile('build', 'webkit-autogen.h'),
		'webkit-perl.h',
	);
	$DEPENDS->save_config(File::Spec->catfile('build', 'IFiles.pm'));


	# Create the Makefile
	my @args = (
		AUTHOR        => 'Emmanuel Rodriguez <potyl@cpan.org>',
		NAME          => 'Gtk3::WebKit',
		VERSION_FROM  => File::Spec->catfile('lib', 'Gtk3', 'WebKit.pm'),
		ABSTRACT_FROM => File::Spec->catfile('lib', 'Gtk3', 'WebKit.pm'),
		LICENSE       => 'perl, lgpl',

		PREREQ_PM     => \%requires,
		PREREQ_FATAL  => 1,

		XSPROTOARG    => '-noprototypes ',
		MAN3PODS      => {
			Glib::MakeHelper->do_pod_files(@XS_FILES),
		},

		$DEPENDS->get_makefile_vars(),

		# Remove the build folder when doing "make clean"
		clean => {
			FILES => 'build',
		},


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


sub MY::postamble {

	my $postamble = Glib::MakeHelper->postamble_clean();
	$postamble .= Glib::MakeHelper->postamble_docs_full(
		DEPENDS   => $DEPENDS,
		XS_FILES  => [ @XS_FILES ],
		COPYRIGHT => 'Copyright (C) 2011 by Emmanuel Rodriguez'
	);

	return $postamble;
}


exit main() unless caller;

