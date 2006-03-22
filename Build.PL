use Module::Build;

use strict;

my $build = Module::Build->new(
    module_name => 'Presto',
    license => 'perl',
    requires => {
        'perl'         => '5.6.0',
        'Scalar::Util' => '1.18',
        'DBM::Deep'    => '0.97',
        'Class::MOP'   => '0.11',
        'Data::Structure::Util' => '0.02',
    },
    optional => {
    },
    build_requires => {
        'Test::More'      => '0.47',
        'Test::Exception' => '0.21',
    },
    create_makefile_pl => 'traditional',
    add_to_cleanup => [
        'META.yml', '*.bak', '*.gz', 'Makefile.PL', 't/test*.db',
    ],
);

$build->create_build_script;

