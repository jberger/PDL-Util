package PDL::Util;

use PDL;
use Scalar::Util qw/openhandle blessed/;

use Carp;

use parent 'Exporter';
our @EXPORT_OK = qw/
  add_pdl_method
  export2d
  unroll
/;
our %EXPORT_TAGS = (
  all => \@EXPORT_OK,
);

sub import {
  my $package = shift;
  return 1 unless @_;

  my $ref_last = ref $_[-1] || '';
  my $method_spec = $ref_last eq 'HASH' ? pop : 0;

  add_pdl_method($method_spec) if ($method_spec);

  __PACKAGE__->export_to_level(1, $package, @_) if @_;
}

sub add_pdl_method {
  my $spec = shift;
  croak 'make_pdl_method expects a hash reference as its argument' 
    unless ref $spec eq 'HASH';

  foreach my $method (keys %$spec) {
    my $function = $spec->{$method};

    # Check to see if PDL already has a method by the same name
    carp <<MESSAGE if PDL->can($method);
PDL already provides a method named '$method', read the PDL::Util documentation to learn to avoid this conflict.
MESSAGE

    unless (ref $function && ref $function eq 'CODE') {
      if ( 1 == grep { $_ eq $function } @EXPORT_OK ) {
        no strict 'refs';
        $function = \&{ 'PDL::Util::' . $function };
      } else {
        croak "value for $method must be either a code reference or the name of one of PDL::Util's exportable functions";
      }
    }
    
    no strict 'refs';
    *{'PDL::'.$method} = $function; 
  }
}

sub unroll {
 my $pdl = shift;

 if ( blessed($pdl) and $pdl->isa('PDL') ) {
   if ($pdl->ndims > 1) {
     return [ map {unroll($_)} dog $pdl ];
   } else {
     return [list $pdl];
   }
 } else {
   return $pdl;
 }

}

sub export2d {
  my ($pdl, $fh, $sep);
  $pdl = shift;
  unless (ref $pdl eq 'PDL') {
    carp "cannot call $method_name without a piddle input";
    return 0;
  }
  unless ($pdl->ndims == 2) {
    carp "$method_name may only be called on a 2D piddle";
    return 0;
  }

  # Parse additional input parameters
  while (@_) {
    my $param = shift;
    if (openhandle($param)) {
      $fh = $param;
    } else {
      $sep = $param;
    }
  }

  # Extract columns from piddle
  my @params = map {$pdl->slice("($_),")} (0..$pdl->dim(0)-1);
  my $num_cols = @params;

  # Push additional parameters for wcols
  push @params, $fh if (defined $fh); 
  push @params, {Colsep => $sep} if (defined $sep);

  # Write columns
  wcols @params;

  return $num_cols;
}

1;

__END__
__POD__

=head1 NAME

PDL::Util

=head1 SYNOPSIS

 use PDL;
 use PDL::Util 'export2d';

 my $pdl = rvals(6,4);

 open my $fh, '>', 'file.dat';
 export2d($pdl, $fh);

=head1 DESCRIPTION

Convenient utility functions/methods for use with PDL.

=cut
