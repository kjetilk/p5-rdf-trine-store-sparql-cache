RDF::Trine::Store::SPARQL::Cache
================================

This is a research prototype for a caching SPARQL client that analyzes
the queries to cache fragments of it. It consists of the client itself
and some code that works on Basic Graph Patterns.

Note that the present code is unlikely to ever be anything more than a
research prototype. If this is to be implemented in production code,
it would have to be incorporated in the [Attean framework](https://metacpan.org/release/Attean). 

Also note that simply to cache whole SPARQL queries, without further
ado, it is possible to simply set the default user agent of RDF::Trine
to a caching one. You can e.g. use my alpha [LWP::UserAgent::CHICaching](https://github.com/kjetilk/p5-lwp-useragent-chicaching):

    use LWP::UserAgent::CHICaching;
    use CHI;
    my $cache = CHI->new( driver => 'Memory', global => 1 );
    my $ua = LWP::UserAgent::CHICaching->new(cache => $cache);
    use RDF::Trine;
    RDF::Trine::->default_useragent($ua);

Subsequent requests will then be cached.
