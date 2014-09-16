use 5.010001;
use strict;
use warnings;

package RDF::Trine::Store::SPARQL::Cache;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.001';


use RDF::Trine qw(statement variable iri literal);
use RDF::Query;
use Digest::MD5 qw(md5_base64);

use base qw'RDF::Trine::Store::SPARQL';


#use LWP::UserAgent::CHICaching;
#my $cache = CHI->new( driver => 'Memory', global => 1 );

#RDF::Trine::->default_useragent(LWP::UserAgent::CHICaching->new(cache => $cache));


sub new {
	my ($class, $url, $rest) = @_;
	my $self = $class->SUPER::new($url);
	$self->{model} = $rest->{metadata_model} || RDF::Trine::Model->temporary_model;
	return $self;
}



sub get_sparql {
	my $self   = shift;
	my $sparql = shift;
	my $query  = RDF::Query->new($sparql);
	my $co     = RDF::Trine::Namespace->new('http://purl.org/ontology/co/core#');
	my $xsd    = RDF::Trine::Namespace->new('http://www.w3.org/2001/XMLSchema#');
	my @triples = $query->pattern->subpatterns_of_type('RDF::Query::Algebra::Triple');
	my %counts;
	my %digests;

	foreach my $triple (@triples) {
		if ($triple->predicate->is_resource) {
			my $pred = $triple->predicate->as_string;
			$counts{$pred}++;
			$digests{$pred} = md5_base64($pred) unless ($digests{$pred});
		}
	}

	while (my ($predicate, $count) = each(%counts)) {
		my $graph = iri('urn:sparqlcache:graphname:' . $digests{$predicate});
		my $iter = $self->{model}->get_statements($graph, $co->count, undef);
		while (my $st = $iter->next) {
			$count += $st->object->value; # Should die if there are more or not int
			$self->{model}->remove_statement($st);
		}
		$self->{model}->add_statement(statement($graph, $co->count, literal($count, undef, $xsd->integer)));
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

