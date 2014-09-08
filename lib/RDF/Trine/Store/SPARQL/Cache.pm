use 5.010001;
use strict;
use warnings;

package RDF::Trine::Store::SPARQL::Cache;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001';

use base qw'RDF::Trine::Store::SPARQL';

use RDF::Trine qw(iri);
#use LWP::UserAgent::CHICaching;
#my $cache = CHI->new( driver => 'Memory', global => 1 );

#RDF::Trine::->default_useragent(LWP::UserAgent::CHICaching->new(cache => $cache));

our %COUNTS;
use RDF::Query;

sub get_sparql {
	my $self        = shift;
	my $sparql      = shift;
	my $query = RDF::Query->new($sparql);

	my @triples = $query->pattern->subpatterns_of_type('RDF::Query::Algebra::Triple');

	foreach my $triple (@triples) {
		if ($triple->predicate->is_resource) {
			$COUNTS{$triple->predicate->as_string}++;
		}
	}

	while (my ($predicate, $count) = each(%COUNTS)) {
		if ($count > 3) {
			$self->SUPER::get_statements(undef, iri($predicate), undef); # Prefetch this into cache
		}
	}

	return $self->SUPER::get_sparql($sparql);
}
1;

__END__

=pod

=encoding utf-8

=head1 NAME

RDF::Trine::Store::SPARQL::Cache - RDF Store proxy for a SPARQL endpoint with cache support

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-Trine-Store-SPARQL-Cache>.

=head1 SEE ALSO

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

