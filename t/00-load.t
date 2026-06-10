use strict; use warnings; use Test::More;
use_ok('Samizdat::Model::BIS');
use_ok('Samizdat::Controller::BIS');
use_ok('Samizdat::Plugin::BIS');
use File::Spec;
my ($d) = grep { -d } map { File::Spec->catdir($_, 'Samizdat','resources') } @INC;
ok($d && -d File::Spec->catdir($d,'templates','bis'), 'bis templates ship');
ok($d && -f File::Spec->catfile($d,'migrations','pg','40-bis','1','up.sql'), 'bis migration ships');
done_testing;
