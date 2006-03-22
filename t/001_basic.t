#!/usr/bin/perl

$|++;
use strict;
use warnings;

use Test::More tests => 33;

BEGIN {
    use_ok('Presto');       
}

my $FILENAME = 't/test.db';
unlink $FILENAME;

{
    package Tree;
    
    sub new { 
        my $class = shift;
        bless {
            value     => undef,
            children => []
        } => $class; 
    }
    
    sub value { 
        my $self = shift;
        $self->{value} = shift if @_;
        $self->{value};
    }
    
    sub add_children {
        my $self = shift;
        push @{$self->{children}} => @_;
    }
    
    sub get_child {
        my ($self, $index) = @_;
        $self->{children}->[$index];
    }
    
    sub child_count {
        my $self = shift;
        scalar @{$self->{children}};        
    }
}

my $db = Presto->new( $FILENAME );

ok( -e $FILENAME, "And, now the file exists" );

$db->register_class( 'Tree' );

can_ok( 'Tree', 'find', 'save', 'delete' );

my $tree = Tree->new();
isa_ok($tree, 'Tree');

is($tree->value, undef, '... got the no node value back');
$tree->value("Hello");
is($tree->value, 'Hello', '... got the right node value back');

is($tree->child_count, 0, '... we have no children yet');
$tree->add_children(Tree->new());
is($tree->child_count, 1, '... we have 1 child now');

my $child_1 = $tree->get_child(0);
isa_ok($child_1, 'Tree');

is($child_1->value, undef, '... got the no node value back');
$child_1->value("World");
is($child_1->value, 'World', '... got the right node value back');

$tree->save;

my $PARENT_OID = 1;
my $CHILD_OID = 0;

is( $tree->{oid}, $PARENT_OID, "You get an oid assigned to you" );
is( $child_1->{oid}, $CHILD_OID, "Its parent was saved, so it has an oid" );

{
    my $found = Tree->find( { value => 'Hello' } );
    isa_ok( $found, 'Tree' );
    is( $found->{oid}, $PARENT_OID, "Found OID is correct" );
    is( $found->value, 'Hello', "Found value is correct" );
    is( $found->child_count, 1, "Found number of children is correct" );

    my $child = $found->get_child( 0 );
    is( $child->value, $child_1->value, "Found children is correct" );
    is( $child->{oid}, $CHILD_OID, "And the OID was also set" );

    $found->value( 'Hello2' );
    my $found2 = Tree->find( { value => 'Hello2' } );
    is( $found2, undef, "Changes aren't saved until save() is called" );

    $found->save;
    my $found3 = Tree->find( {value => 'Hello2'} );
    isa_ok( $found3, 'Tree' );
    is( $found3->value, 'Hello2', "Changes reflected in DB after save" );
}

{
    my ($found) = Tree->find( { oid => $PARENT_OID } );
    isa_ok( $found, 'Tree' );
    is( $found->value, 'Hello2', "Found value is correct" );
    is( $found->child_count, 1, "Found number of children is correct" );
    is( $found->get_child( 0 )->value, $child_1->value, "Found children is correct" );
}

$tree->delete;
is( $tree->{oid}, undef, "Deleting removes the oid" );
is( $tree->value, 'Hello', "... but the value is still there" );
is( $tree->child_count, 1, "Found number of children is correct" );

my $child = $tree->get_child( 0 );
is( $child->value, $child_1->value, "Found child value is correct" );
is( $child->{oid}, $CHILD_OID, "And the OID is still there (child wasn't deleted)" );

my @objects = Tree->find;
is( scalar(@objects), 1, "There's only one object left" );
is( $objects[0]->{oid}, $CHILD_OID );
