$|++;
use strict;
use warnings;

use Test::More no_plan => 1;

BEGIN {
    use_ok( 'Presto' );
}

my $FILENAME = 't/test.db';
unlink $FILENAME;

{
    package Class1;

    sub new {
        my $class = shift;
        bless { @_ }, $class;
    }
}

{
    package Class2;

    sub new {
        my $class = shift;
        bless { @_ }, $class;
    }
}

{
    package Class3;

    sub new {
        my $class = shift;
        bless { @_ }, $class;
    }
}

my $db = Presto->new( $FILENAME );

ok( -e $FILENAME, "And, now the file exists" );

$db->register_class( 'Class1' );
$db->register_class( 'Class2' );

my $obj1 = Class1->new( value => 1, children => [] );
isa_ok($obj1, 'Class1');

my $obj2 = Class2->new( value => 2 );
isa_ok($obj2, 'Class2');

my $obj3 = Class3->new( value => 3 );
isa_ok($obj3, 'Class3');

push @{$obj1->{children}}, $obj2;
push @{$obj1->{children}}, $obj3;

$obj1->save;

ok( exists $obj1->{oid}, "Obj1 was saved" );
ok( exists $obj2->{oid}, "Obj2 was saved as a child" );
ok( !exists $obj3->{oid}, "Obj3 wasn't saved because it's not registered" );

my @class1 = Class1->find();
is( scalar(@class1), 1, "There's only one Class1 object" );
isa_ok( $class1[0], 'Class1' );

my @class2 = Class2->find();
is( scalar(@class2), 1, "There's only one Class2 object" );
isa_ok( $class2[0], 'Class2' );
