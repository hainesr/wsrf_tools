#! /usr/bin/env perl

BEGIN {
       @INC = ( @INC, $ENV{WSRF_LOCATION} );
};

use LWP::Simple;
#use WSRF::Lite +trace =>  debug => sub {};
use WSRF::Lite;
use MIME::Base64;
use Digest::SHA1 qw(sha1 sha1_hex sha1_base64);;
use strict;

#need to point to user's certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";


if( @ARGV > 1  )
{
  print "Usage: appLauncher.pl [Job input file]\n";
  exit;
}

my $input_file = "";
if( @ARGV == 1 )
{
  $input_file = $ARGV[0];
}

#----------------------------------------------------------------------
# Read handle of registry from file

open(GSH_FILE, "reg_registry_info.sh") || die("can't open datafile: $!");
# Read two lines and then get the text after the '=' character
my $line_text = <GSH_FILE>;
$line_text = <GSH_FILE>;
close(GSH_FILE);

my @item_arr = split(/=/, $line_text);
my $registry_EPR = $item_arr[1];

print "\nRegistry EPR = $registry_EPR\n";

#----------------------------------------------------------------------
# Read list of available containers

open(CONTAINER_FILE, "container_addresses.txt") || die("can't open container list: $!");
my $i = 0;
my @containers = <CONTAINER_FILE>;
close(CONTAINER_FILE);

for($i=0; $i<@{containers}; $i++){
    # Remove new-line character
    $containers[$i] =~ s/\n//og;
}

#---------------------------------------------------------------------
# Ask user to choose container to host the SWS

print "Available containers:\n";
for($i=0; $i<@{containers}; $i++){
    print "    $i: $containers[$i]\n";
    # ARPDBG - hardwire for now 
    #if($containers[$i] =~ m/methuselah/){
    #  last;
    #}
}
$i = -1;
my $max_container = @{containers} - 1;
while ($i < 0 || $i > $max_container) {
    print "Which container do you want to use (0 - $max_container): ";
    $i = <STDIN>;
    print "\n";
}

my $myContainer = $containers[$i];

#----------------------------------------------------------------------
# Generate meta data 

# Get the username
my $username = $ENV{'USER'};
print "Username is: $username\n";

# Virtual Organisation of user
my $virt_org = "RSS Group";

# Get the time and date
my $time_now = time;
my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($time_now);

# month returned by localtime is zero-indexed and we need to convert to
# a four-digit date...
my $launch_time = sprintf "%4d-%02d-%02dT%02d:%02d:%02dZ",
                     $year+1900,$mon+1,$mday,$hour,$min,$sec;

# Type of application
#print "Enter name of application: ";
#my $app_name = <STDIN>;
my $app_name = "mini_app\n";
# Remove new-line character
chomp($app_name);
print "\n";

# Purpose of job
#print "Enter purpose of job: ";
#my $content = <STDIN>;
my $content = "test wsrf work\n";
# Remove new-line character
chomp($content);
print "\n";

# Run-time
#print "Max. wall-clock time of job in minutes (hit Return for none): ";
#my $run_time = <STDIN>;
my $run_time = "120\n";
# Remove new-line character
chomp($run_time);
print "\n";

my $job_description = <<EOF;
<registryEntry>
<serviceType>SWS</serviceType>
<componentContent>
<componentStartDateTime>$launch_time</componentStartDateTime>
<componentCreatorName>$username</componentCreatorName>
<componentCreatorGroup>$virt_org</componentCreatorGroup>
<componentSoftwarePackage>$app_name</componentSoftwarePackage>
<componentTaskDescription>$content</componentTaskDescription>
</componentContent>
</registryEntry>
EOF

#print $job_description;

#----------------------------------------------------------------------
# Create SWS

# Give the GS an initial lifetime of 24 hours - specified in minutes
my $timeToLive = 24*60;

#print "Enter EPR for starting checkpoint (hit Return for none): ";
#my $chkEPR = <STDIN>;
#print "\n";
my $chkEPR = '\n';

print "Enter a passphrase to protect the SWS: ";
my $passphrase = <STDIN>;
chomp($passphrase);
print "\n";
#my $passphrase = "somethingcunning";

# Set the location of the service
my $target = $myContainer . "Session/SWSFactory/SWSFactory";
# Set the namespace of the service
my $uri = "http://www.sve.man.ac.uk/SWSFactory";

print "Calling createSWSResource on $target...\n";

# This call returns a SOM object
my $ans =  WSRF::Lite
         -> uri($uri)
         -> wsaddress(WSRF::WS_Address->new()->Address($target)) #location of service
         -> createSWSResource($timeToLive, $registry_EPR, 
			      SOAP::Data->value($job_description)->type('string'), 
			      $chkEPR,
			      $passphrase);

die "createSWSResource call did not return anything" if !defined($ans);

if ($ans->fault) {  die "createSWSResource ERROR:: ".$ans->faultcode." ".
			$ans->faultstring."\n"; }

# Check we got a WS-Address EndPoint back
my $address = $ans->valueof('//Body//Address') or 
       die "CREATE ERROR:: No Endpoint returned\n";

print "\n   Created WSRF service, EndPoint = $address\n";
$target = $address;
$uri = "http://www.sve.man.ac.uk/SWS";

#---------------------------------------------------------------------
# Supply input file & max. runtime

$content = " ";
if( length($input_file) > 0){

    open(GSH_FILE, $input_file) || die("can't open input file: $input_file");

    while (my $line_text = <GSH_FILE>) {
	$content = $content . $line_text;
    }
    close(GSH_FILE);
}

# Protect input-file content by putting it in a CDATA section - we 
# don't want the parser to attempt to parse it.  If the user has
# specified a max. run-time of the job then configure the SGS
# with it (is used to control life-time of the service). Allow 5 more
# minutes than specified, just to be on the safe side.
if(length($run_time) > 0){
  $run_time += 5;
  $content = "<wsrp:Insert><inputFileContent><![CDATA[" . $content .
             "]]></inputFileContent><maxRunTime>" . $run_time . "</maxRunTime></wsrp:Insert>";
}
else{
  $content = "<wsrp:Insert><inputFileContent><![CDATA[" . $content .
             "]]></inputFileContent></wsrp:Insert>";
}

#print "uri     = $uri\n";
#print "target  = $target\n";
#print "content = >>$content<<\n";

# seed the random number generator
srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip`);
my $num = rand 1000000;

my $nonce = encode_base64("$num", "");

# Set earlier...
my $passwd = $passphrase;

# Password digest = Base64( SHA-1(nonce + created + password) )
# (You should see the C code for doing this!)
my $digest = sha1_base64($nonce . $launch_time . $passwd);

my $user = SOAP::Data->name('wsse:Username' => 'Andy_Porter');
my $passData = SOAP::Data->name('wsse:Password' => $digest);
my $nonceData = SOAP::Data->name('wsse:Nonce' => $nonce);
my $created = SOAP::Data->name('wsse:Created' => $launch_time);

my $hdr1 = SOAP::Data->new(name => 'wsse:UsernameToken', 
			     value => \SOAP::Data->value($user,
							 $passData,
							 $nonceData,
							 $created));

my $ans =  WSRF::Lite
    -> uri($uri)
    -> wsaddress(WSRF::WS_Address->new()->Address($target))
    -> SetResourceProperties( SOAP::Header->name('wsse:Security')->value(\$hdr1),
			      SOAP::Data->value( $content )->type( 'xml' ) );

if($ans && $ans->fault){
    die "createSWSResource ERROR:: ".$ans->faultcode." ".
	$ans->faultstring."\n"; 
}

#----------------------------------------------------------------------
# Save the GSH to file

open(GSH_FILE, "> reg_app_info.sh") || die("can't open datafile: $!");

print GSH_FILE "#!/bin/sh\n";
print GSH_FILE "export REG_SGS_ADDRESS=$target\n";

close(GSH_FILE);
