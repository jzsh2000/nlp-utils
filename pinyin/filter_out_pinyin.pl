#!/usr/bin/env perl

# Author: JIN Xiaoyang
# Date  : 2015-11-15
#
# Filter out a line if every 'words' in it look like pinyin

use warnings;
use strict;

sub usage() {
    # fields are separated by <TAB>
    print "Usage: $0 [field_num] <file>\n";
}

&usage and exit if defined $ARGV[0] and $ARGV[0] eq '-h';

my $field=0;
if (defined $ARGV[0] and $ARGV[0]=~/[0-9]+/) {
    $field=shift;
}

my %pinyin;
my $pinyin_file = $0; $pinyin_file =~ s![^/]+$!pinyin.txt!;

open(PINYIN, "<$pinyin_file") or die "Error: cannot open file 'pinyin.txt'";
while(<PINYIN>) {
    chomp;
    $pinyin{$_}++;
}
close PINYIN;

while(<>) {
    chomp;
    my @fields=split /\t/,$_;
    my $term=$fields[$field-1];
    my $pinyin="true";
    my $pinyin_num=0;
    foreach my $subterm (split /\s+/,$term) {
	if (exists $pinyin{$subterm} or exists $pinyin{"\L$subterm"}) {
	    $pinyin_num++;
	} else {
	    $pinyin="false";
	    last;
	}
    }
    print "$_\n" if $pinyin eq "false" or $pinyin_num==1;
}
