#/usr/bin/perl

use warnings;

sub print_lol
{
	print "CALL function lol\n";
}

sub print_pwet
{
	print "CALL function pwet\n";
}

sub main
{	
	my $arg = shift @_;
	
	my %functions = (
		'lol' => \&print_lol,
		'pwet' => \&print_pwet
	);
	
	if (exists($functions{$arg}))
	{
		$functions{$arg}->();
	}
	else
	{
		print "La fonction correspondante n'est pas enregistrée.\n";
	}
}

main(@ARGV);