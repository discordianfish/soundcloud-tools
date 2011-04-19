#!/usr/bin/env perl
# try: player.pl tags=dubstep q=sick

use constant ID => 'r7hAB5SAlvls3rjlVjJ2w';
use constant SECRET => 'RKp3czlwOJSLlMMJhemXM3dDBVboIZVofKs24NGy4';

use LWP::UserAgent;
use URI;
use JSON qw(from_json);
use Term::ReadKey;

my %filter;
for my $opt (@ARGV)
{
    $opt =~ /^([^=]*)=(.*)$/
        or die "invalid filter: $opt";
    $filter{$1} = $2;
}

print "username: ";
my $user = <STDIN>;

print "password: ";
ReadMode('noecho');
my $pass = ReadLine(0);
ReadMode('normal');

my $ua = LWP::UserAgent->new;
$ua->agent('perl-cli-radio/0.01');


open my $player, "|mpg123 -"
    or die "could not open player: $!";

for my $track (@{ request('tracks.json', limit => 200, %filter) })
{
    print "$track->{user}->{username} - $track->{title}: $track->{permlink_url}\n";
    unless ($track->{streamable})
    {
        print "not streamable, skipping\n";
        next;
    }

    my $uri = URI->new($track->{stream_url});
    $uri->query_form
    (
        client_id => ID,
        client_secret => SECRET,
        grant_type => 'password',
        username => $user,
        password => $password
    );
    warn $uri;
    my $ret = $ua->get
    (
        $uri,
        ':content_cb' => sub
        {
            print $player shift
               or die "could not play data from stream: $!"
        }
    );
    warn $ret->status_line;
}

sub play
{
}


# ---
sub request
{
    my $resource = shift
        or return;
    my %param = @_;

    my $uri = URI->new('http://api.soundcloud.com');

    $uri->path($resource);
    $uri->query_form(client_id => ID, %param);

    warn $uri;

    my $ret = $ua->request(HTTP::Request->new(GET => $uri));
    
    return from_json $ret->content
        if ($ret->is_success);

    warn 'something went wrong: ' . $ret->status_line;
}



