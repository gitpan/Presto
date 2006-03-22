package Presto;

use 5.6.0;

use strict;
use warnings;

our $VERSION = '0.01';

#use lib '/home/rob/DBM-Deep/tags/0-981_02/lib';
use DBM::Deep '0.982';
use Class::MOP;
use Data::Structure::Util qw( get_blessed );

sub new {
    my $class = shift;
    my ($filename) = @_;

    my $db = DBM::Deep->new({
        file      => $filename,
        locking   => 1,
        autobless => 1,
        autoflush => 1,
    });

    unless ( exists $db->{data} ) {
        $db->{data} = {};
    }

    return bless {
        db => $db,
        classes => {},
    } => $class;
}


sub register_class {
    my $presto = shift;
    my ($pkg) = @_;

    $presto->{classes}{$pkg} = undef;

	my $meta = Class::MOP::Class->initialize($pkg);

    my $db = $presto->{db};

    $meta->add_method('find' => sub {
        my $class = shift;
        my ($req) = @_;

        my @ret;
        OBJ: foreach my $obj ( @{$db->{data}{$class}} ) {
            foreach my $k ( keys %$req ) {
                next OBJ if !exists $obj->{$k};
                if ( defined $req->{$k} ) {
                    next OBJ if !defined $obj->{$k}
                        || $obj->{$k} ne $req->{$k};
                }
                else {
                    next OBJ if defined $obj->{$k};
                }
            }

            #XXX This is what it should be, but there's a bug in DBM::Deep.
            #push @ret, tied(%$obj)->export;
            push @ret, bless tied(%$obj)->export, Scalar::Util::blessed($obj);
        }

        return wantarray ? @ret : $ret[0];
    });

    $meta->add_method( 'save' => sub {
        my $self = shift;

        # get_blessed() is a depth-first traversal. We need to handle the
        # children first in order to make sure that we don't get duplicates.
        # Hence, the use of shift() instead of pop().

        my $objects = get_blessed( $self );
        while ( my $obj = shift @$objects ) {
            my $c = Scalar::Util::blessed($obj);
            next unless exists $presto->{classes}{$c};

            if ( exists $obj->{oid} ) {
                $db->{data}{$c}[$obj->{oid}] = $obj;
            }
            else {
                $db->{data}{$c} ||= [];
                $obj->{oid} = $db->{data}{$c}->length;
                push @{$db->{data}{$c}}, $obj;
            }
        }

        return 1;
    });

    $meta->add_method( 'delete' => sub {
        my $self = shift;

        my $c = Scalar::Util::blessed( $self );
        if ( exists $self->{oid} ) {
            delete $db->{data}{$c}[$self->{oid}];
            delete $self->{oid};
        }

        return 1;
    });

    return 1;
}

1;
__END__

=pod

=head1 NAME

Presto - An Object Oriented Database System for Perl

=head1 SYNOPSIS

  my $presto = Presto->new( $db_file );

  $presto->register_class( 'Class1', 'Class2' );

  my $obj = Class1->new( ... );

  $obj->save;

  $obj->delete;

  my @objs = Class1->find( {
      key1 => value1,
      key2 => value2,
  } );

  $objs[0]->delete;

=head1 WARNING

This is completely and utterly alpha software. If you love your job, don't
make it depend on this version of this module. This is being released solely
for community comment.

If you like this module, please provide me with failing tests and API
suggestions. I'll take patches, but I prefer faiilng tests demonstrating what
you want Presto to do and how it's not doing it. You might find that, in the
process of writing the failing test, Presto already does what you want. Plus,
with the failing test, I see what you're trying to do. A patch doesn't tell me
that.

=head1 DESCRIPTION

Presto is an object datastore, or OODBMS. There is nothing relational about it
at all. You put objects in and you get objects out. Unlike L<Pixie/>, there is
no magic cookie. Unlike L<DBM::Deep/> (which is the underlying engine), there is
DBMS management provided for you, including indexing.

=head1 METHODS

=over 4

=item B<new>

This is the constructor to create a new Presto object. It accepts one
parameter, which is the filename of the Presto database.

=item B<register_class>

This accepts a single class name. It will add the following methods to it:

=over 4

=item * find()

This is a class method. It accepts a hashref of the key/value pairs you wish
to find objects that match.

=item * save()

This is an instance method. It will save that object and any children it has
to the database. It will only call save() on children that are blessed into a
registered class. When it is done, it will set the I<oid> key to the object id.

If the object has no OID, it will perform an insertion. If it does, it will
perform an update.

B<NOTE>: The oid can be 0. Do B<NOT> check the OID for truth. Instead, check to
make sure that the I<oid> key exists.

  if ( exists $obj->{oid} ) {
      # Do something here
  }

=item * delete()

This is an instance method. It will make sure that there is no object in the
datastore with that object's OID. It will I<only> delete that object, not any
children.

=back

=back

=head1 TODO

=over 4

=item * Indices

Currently, there is B<NO> indexing done. Every find() does the equivalent of a
full-table scan. This will be added in version 0.02.

=back

=head1 RESTRICTIONS

=over 4

=item * Hashes only

All objects B<must> be blessed hashes. This restriction will go away in a later
release. If you don't use blessed hashes and it blows up on you, don't complain.
You've been warned.

=back

=head1 SEE ALSO

L<Presto::WTF/>, L<DBM::Deep/>

=head1 CODE COVERAGE

We use L<Devel::Cover/> to test the code coverage of our test suite. Here is
the current coverage report:

  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  File                           stmt   bran   cond    sub    pod   time  total
  ---------------------------- ------ ------ ------ ------ ------ ------ ------
  blib/lib/Presto.pm             98.4   66.7   88.9  100.0  100.0  100.0   92.3
  Total                          98.4   66.7   88.9  100.0  100.0  100.0   92.3
  ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHOR

Rob Kinyon E<lt>rob@iinteractive.comE<gt>

Stevan Little E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
