use strict; use warnings;
use ExtUtils::MakeMaker;
use File::Find;
my %pm;
find(sub { return unless -f; return if /\.(bak|orig|rej|swp)$/;
  my $p=$File::Find::name; (my $r=$p)=~s{^lib/}{}; $pm{$p}="\$(INST_LIB)/$r"; }, 'lib');
WriteMakefile(
  NAME => 'Samizdat::Plugin::BIS', VERSION => '0.01', ABSTRACT => 'Based-in-Sweden hosting compliance data',
  AUTHOR => 'Hans Svensson <hans\@alipang.se>', LICENSE => 'artistic_2', MIN_PERL_VERSION => '5.036',
  PM => \%pm, PREREQ_PM => { 'Mojolicious' => '9.0' }, TEST_REQUIRES => { 'Test::More' => 0 },
  META_MERGE => { 'meta-spec' => { version => 2 },
    prereqs => { runtime => { requires => { 'Samizdat' => 0 } } },
    no_index => { directory => ['lib/Samizdat/resources'] } },
  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' }, clean => { FILES => 'Samizdat-Plugin-BIS-*' },
);
