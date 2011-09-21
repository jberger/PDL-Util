use strict;
use warnings;

use Test::More tests => 3;
use PDL;
use_ok('PDL::Util', 'add_pdl_method');

my $pdl = zeros(5,5);

add_pdl_method({ 'mymethod_ref' => \&method1 });
ok($pdl->can('mymethod_ref'), "method added by code reference");

add_pdl_method({ 'mymethod_unroll' => 'unroll' });
ok($pdl->can('mymethod_unroll'), "method added by name from PDL::Util's exportable function");

sub method1 {
  my $pdl = shift;
  return 1;
}

