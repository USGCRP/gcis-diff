#!/usr/bin/env perl

use v5.20.1;
use Mojo::UserAgent;
use Gcis::Client;
use YAML::XS qw/Dump/;
use Text::Diff qw/diff/;
use Data::Dumper;

my $src_url = q[http://data.gcis-dev-front.joss.ucar.edu];
my $dst_url = q[http://data-stage.globalchange.gov];
my $verbose = 1;

my $src = Gcis::Client->new(url => $src_url );
my $dst = Gcis::Client->new(url => $dst_url );

sub same {
    my ($x,$y) = @_;
    return !( Dump($x) cmp Dump($y) );
}

my $what = q[/organization];

say "src : ".$src->url;
say "dst : ".$dst->url;
say "resource : $what";

my @src = $src->get("$what?all=1");
my @dst = $dst->get("$what?all=1");

delete $_->{href} for @src, @dst;

say "counts :";
say "         src : ".@src;
say "         dst : ".@dst;

# key on uri
my %src = map {$_->{uri} => $_} @src;
my %dst = map {$_->{uri} => $_} @dst;

say "identifiers :";
my @only_in_src = grep !exists($dst{$_}), keys %src;
my @only_in_dst = grep !exists($src{$_}), keys %dst;
say "      common : ".(grep exists($dst{$_}), keys %src);
say " only in src : ".@only_in_src;
say " only in dst : ".@only_in_dst;

say "content : ";
my @common    = grep exists($dst{$_}), keys %src;
my @same      = grep same($src{$_},$dst{$_}), @common;
my @different = grep !same($src{$_},$dst{$_}), @common;
say "        same : ".@same;
say "   different : ".@different;

if ($verbose) {
    say "Only in $src_url : ";
    say $_ for @only_in_src;
    say "\nDifferences between resources in both places : ";
    for (@different) {
        say "uri : ".$_;
        say diff(\Dump($src{$_}), \Dump($dst{$_}));
    }
}

