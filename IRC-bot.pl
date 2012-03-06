#!/usr/bin/perl

=head1 NAME

Hoity-Toity Bot - prints the last user twitter message
invocation in the IRC channel: .lt nickname

=cut
package HoityToity;
use base 'Bot::BasicBot';
use strict;
use warnings;
use LWP::Simple qw(get);
use XML::Parser;

sub new {
	my ($class, @args) = @_;
	
	my $self = $class->SUPER::new(@args);
	$self->{_data} = undef;
	$self->{_info} = undef;
	$self->{_parser} = new XML::Parser(
		'Non-Expat-Options' => { 
			 strMsg => undef,
			 info => undef
		},	
		Handlers => {
			Start => \&hdl_start,
			End => \&hdl_end,
			Char => \&hdl_char,
			Default => \&hdl_def
		}
    );
	bless $self, $class;
	
	$self;
}

sub said {
    my $self = shift;
    my $message = shift;
    
    my $body = $message->{body};   
    if ($body eq 'shutdown'){
        $self->shutdown('Bye.');
    } else {   
		return unless $body =~ /^\.lt\W(\w{3,}?)$/i;

		my $nickname = $1;
		my $lastTwitterMsg = get("http://twitter.com/statuses/user_timeline.xml?screen_name=$nickname&count=1");
		
		if ($lastTwitterMsg) { 
			$self->{_parser}->parse($lastTwitterMsg);
			
			if ($self->{_parser}->{'Non-Expat-Options'}->{strMsg}) {
				$self->reply($message, "$nickname said on twitter: $self->{_parser}->{'Non-Expat-Options'}->{strMsg}");
				undef $self->{_parser}->{'Non-Expat-Options'}->{strMsg};
			}
		}
	}
}

####routines####
sub hdl_start {
    my($p, $elt, %atts) = @_;
    return unless $elt eq 'text';
    
    $atts{'_str'} = '';
    $p->{'Non-Expat-Options'}->{info} = \%atts;
}

sub hdl_end { 
    my($p, $elt) = @_;
    
    if ($elt eq 'text' && $p->{'Non-Expat-Options'}->{info}{'_str'} =~ /\S/) {
		
		$p->{'Non-Expat-Options'}->{info}{'_str'} =~ s/\n//g;	
		$p->{'Non-Expat-Options'}->{strMsg} = $p->{'Non-Expat-Options'}->{info}{'_str'};
		undef $p->{'Non-Expat-Options'}->{info};
	}
}

sub hdl_char {
    my ($p, $str) = @_;
    $p->{'Non-Expat-Options'}->{info}{'_str'} .= $str;
}

sub hdl_def { }  # We just throw everything else

my $hoityToity = new HoityToity(
    server => "irc.freenode.net",
    channels => [ '#foobar' ],
    nick => 'hoity-toity'
);
$hoityToity->run();
