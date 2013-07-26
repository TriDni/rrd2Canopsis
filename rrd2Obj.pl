#!/usr/bin/perl

use strict;
use warnings;
use JSYNC;
use Getopt::Long;
use Scalar::Util 'blessed';

my $global;

GetOptions ('global' => \$global);

my $obj = JSYNC::load(<STDIN>);
my $rrdObj = addPerfdata($obj, $global);

my $json = JSYNC::dump($rrdObj);#, {pretty => 1});
print $json;

sub addPerfdata {
  my ($object, $global) = @_;
	my ($resource, $component, $metricObj, $metricData, $name, $type, $path, $id);
	my (@obj, @metrics);

	foreach my $plugin (@$object) {
		$resource =  ${$plugin}{resource};
		$component =  ${$plugin}{component};
		$metricObj =  ${$plugin}{metric};
		foreach my $metric (@$metricObj) {
			$name = ${$metric}{name};
			$type = ${$metric}{type};
			$path = ${$metric}{path};
			$id = ${$metric}{id};
			if ($global) {
				my $values = parseRrdGlobal($path);
				my $this = {"id", $id, "name", $name, "type", $type, "data", $values};
                                bless($this, $id);
                                push(@metrics, $this);
				}
			else {
				my $values = parseRrdLast($path);
				my $this = {"id", $id, "name", $name, "type", $type, "data", $values};
				bless($this, $id);
				push(@metrics, $this);
				}
			}
		my @tmpMetrics = @metrics;
		my $this = {"component", $component, "resource", $resource, "metric", \@tmpMetrics};
		bless($this, blessed($plugin));
		push(@obj, $this);
		undef @metrics;
		}
	return \@obj;
}

sub parseRrdGlobal {
        my ($path) = @_;

        my $timestamp;
        my $value;
        my $checking = 1;
        my %perf_data;

        if (-e "/tmp/tmp_rrd2.xml") { unlink "/tmp/tmp_rrd2.xml"; }
        `rrdtool dump $path >/tmp/tmp_rrd.xml2`;
        open(MYINPUTFILE, "/tmp/tmp_rrd.xml2");
        while(<MYINPUTFILE>){
                my($line) = $_;
                chomp($line);

                #si on sort des valeurs AVERAGE (MIN ou MAX) on quitte le rrd
                if (($line =~ /^\s+<cf>MAX<\/cf>/)||($line =~ /^\s+<cf>MIN<\/cf>/)) { $checking = 0; }
                if ($line =~ /^\s+<cf>AVERAGE<\/cf>/) { $checking = 1; }
                if ($checking == 0) { next; }
                #si la ligne n'est pas une ligne de données de perf on passe à la suivante
                if (not $line =~ /^\s*<!--\s\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}.*/) { next; }
                ($timestamp) = $line =~ /\/\s(\d{10})\s-->/;
                #génération du json string
                my ($value) = $line =~ /<v>(.*)<\/v>/;
                if ($value ne "NaN") {
                        $perf_data{$timestamp} = $value;
                        }
        };
        unlink "/tmp/tmp_rrd.xml2";
        return \%perf_data;
}


sub parseRrdLast {
        my ($path) = @_;

        my %perf_data;
        my $last = `rrdtool info $path |grep last_ds`;
        my $timestamp = `rrdtool last $path`;
        chomp($last);
        chomp($timestamp);
        my ($value) = $last =~ /.*=\s+\"(.*)\"/;

        if ($value ne "NaN" && $value ne "U") { $perf_data{$timestamp} = $value; }
	else { $perf_data{NaN} = "NaN"; }
	return \%perf_data;
}
