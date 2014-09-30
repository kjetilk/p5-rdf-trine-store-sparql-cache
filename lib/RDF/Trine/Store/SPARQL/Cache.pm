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


use LWP::UserAgent::CHICaching;
my $cache = CHI->new( driver => 'Memory', global => 1 );

RDF::Trine::->default_useragent(LWP::UserAgent::CHICaching->new(cache => $cache));


sub new {
	my ($class, $url, $rest) = @_;
	my $self = $class->SUPER::new($url);
	$self->{model} = $rest->{metadata_model} || RDF::Trine::Model->temporary_model;
	return $self;
}

sub get_statements {
	my $self   = shift;
	my @nodes  = @_[0..3];
	my $digest = md5_base64($nodes[1]->as_string);
	if ($cache->is_valid($digest)) {
		# TODO: Check if the statement is exactly what we had
		my $model = RDF::Trine::Model->temporary_model;
		my $parser = RDF::Trine::Parser->new( 'turtle' ); # TODO: Record content-type
		$parser->parse_into_model(undef, $cache->get($digest), $model);
		return $model->get_statements(@nodes);
	} else {
		return $self->SUPER::get_statements(@nodes);
	}
}

sub get_pattern {
	my $self        = shift;
	my $bgp         = shift;
	my $context     = shift;
	my @args        = @_;
	my %args        = @args;
	my $dct        = RDF::Trine::Namespace->new('http://purl.org/dc/terms/');

	if ($bgp->isa('RDF::Trine::Statement')) {
		$bgp    = RDF::Trine::Pattern->new($bgp);
	}
	
	bless($bgp, 'RDF::Trine::Pattern::CacheChecking');
	
	my @bgps = $bgp->subgroup;
	
	my $localmodel = RDF::Trine::Model->temporary_model;
	
   # Identify the triple patterns that are cached
	# Decide evaluation order
	my @patterns;
	foreach my $pattern (@bgps) {
		my @triples = $pattern->triples;
		my %triples_by_tid;
		foreach my $t (@triples) {
			my $tid = refaddr($t);
			$triples_by_tid{$tid}{'tid'} = $tid; # TODO: Worth doing this in an array?
			$triples_by_tid{$tid}{'triple'} = $t;
			my $digest = md5_base64($t->predicate->as_string);
			if ($cache->is_valid($digest)) {
				my $graph = iri('urn:sparqlcache:graphname:' . $digest);
				my $iter = $self->{model}->get_statements($graph, $dct->extent, undef);
				my $clenght = 0;
				while (my $st = $iter->next) {
					$clenght += $st->object->value; # Should die if there are more or not int
				}
				my $parser = RDF::Trine::Parser->new( 'turtle' ); # TODO: Record content-type
				$parser->parse_into_model(undef, $cache->get($digest), $localmodel);
				$triples_by_tid{$tid}{'sum'} = $clength;
			} else {
				$triples_by_tid{$tid}{'sum'} = RDF::Trine::Pattern::_hsp_heuristic_triple_sum($t); # TODO: Really nasty hack...
			}
			my @sorted_tids = sort { $a->{'sum'} <=> $b->{'sum'} } values(%triples_by_tid);
			my @sorted_triples;
			foreach my $entry (@sorted_tids) {
				push(@sorted_triples, $triples_by_tid{$entry->{'tid'}}->{'triple'});
			}
			
	}
	


	# Join the results
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

