# Samizdat-Plugin-BIS

Based-in-Sweden hosting compliance data for [Samizdat](https://fakenews.com). Extracted from the monorepo with
history; requires core **Samizdat** (PERL5LIB or installed).

    perl Makefile.PL && make && make test    # core on PERL5LIB
    make install

Enable via `extraplugins: [BIS]`.
