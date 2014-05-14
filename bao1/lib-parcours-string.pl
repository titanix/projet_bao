use warnings;
use strict;

# param $content : texte xml à traiter
# param $tag : nom (sans crochets) du tag xml dont il faut récupérer le contenu
# return : la liste des contenus du tag contenu dans le texte
# note : la balise qui entoure le XML à extraire n'est pas retirée par cette fonction
sub extract_tag_content
{
	my ($content, $tag) = @_;
	my @list = ();
	extract_tag_content_helper($content, $tag, \@list);
	return @list;
}

sub extract_tag_content_helper_derec
{
	my ($content, $tag, $list) = @_;
	
	my $start_tag = "<$tag>";
	my $end_tag = "</$tag>";
	my $start_tag_index = index($content, $start_tag);	
	my $end_tag_index = index $content, $end_tag;
	
	while ($start_tag_index != -1 && defined($content) && $content ne "")
	#while ($start_tag_index != -1 || !defined($content) || $content eq "")
	{
		$start_tag_index = index($content, $start_tag);	
		$end_tag_index = index $content, $end_tag;
		
		my $temp = substr($content, $start_tag_index, 
			$end_tag_index - $start_tag_index + length($end_tag));
		if($temp eq "") { return; }
		
		push @$list, substr($content, $start_tag_index, 
			$end_tag_index - $start_tag_index + length($end_tag));

		$content = substr($content, $end_tag_index + length($end_tag));
		

	}
}

sub extract_tag_content_helper
{
	my ($content, $tag, $list) = @_;
	
	my $start_tag = "<$tag>";
	my $end_tag = "</$tag>";
	my $start_tag_index = index($content, $start_tag);	
	my $end_tag_index = index $content, $end_tag;
		
	if($start_tag_index == -1)
	{
		return;
	}
	
	push @$list, substr($content, $start_tag_index, 
		$end_tag_index - $start_tag_index + length($end_tag));
	
	$content = substr($content, $end_tag_index + length($end_tag));
	
	extract_tag_content_helper($content, $tag, $list);
}

1;
