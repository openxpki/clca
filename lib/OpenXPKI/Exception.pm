package OpenXPKI::Exception;

use strict;
use Class::Std;
use warnings;
use Data::Dumper;
use Carp;

sub throw {
    my $self = shift;
    my %args = @_;

    if (exists $args{params}) {
        print "Exception parameters:\n";
        print Dumper $args{params};
	print "\n";
    }
    if (exists $args{message}) {
	croak $args{message};
    }
    die;
}

1;
