#!/usr/bin/perl
package Main;
use strict;
use warnings;
use WWW::Mechanize;
my $mech=WWW::Mechanize->new();
#use encode
my $main = new Main();
#'Airbrush Magazine'  424 'Tier 3' edit_009
my $appName      = 'Airbrush Magazine';
my $slot         = '00006';
my $pub_id       = '424';
my $issuePrice   = 'Tier3';
my $submit_url   = 'edit_009';
#############################################################################
my $mainUrl='https://itunesconnect.apple.com/';
my $response=$mech->get($mainUrl);
my $htmlPage;
if($response->is_success)
{
	$htmlPage=$mech->content();
	open(FILE,">content.html");
	print FILE $htmlPage;
}
my $site=$mainUrl;
if ($mainUrl!~/\/$/s)
{
	$site.="/";
}
my $nflag=0;
my $flag1=0;
my $previousPage=$htmlPage;
#############################################################################
#########################Place for functions to be called####################
print "Going to do Login page...\n";
$main->Login($htmlPage);
print "Going to check for login...\n";
$main->checkForLogin($htmlPage);# Not considered one case where we dont pass user name 
my $logoutFile=$htmlPage;
$previousPage=$htmlPage;##to be used if necessary 
print "Going to click Manage your apps...\n";
$main->clickmanageURapps($htmlPage);
print "Going to click seeAll...\n";
$main->clickseeAll($htmlPage);
print "Going to click App Name...\n";
$main->clickappName($htmlPage);
print "Going to click button Manage In App Purchases...\n";
$main->clickManageInAppPurchases($htmlPage);
print "Going to click magzine page next...\n";
$main->clickMagzineNext($htmlPage);
##############################################################################
sub Login
{
	my $this = shift;
	my ($resultFile)=@_;
	$this->clearFile(\$resultFile);
	my $loginFlag=0;
	my $formFlag=0;
	while($resultFile=~/<form(.*?)>/is)
	{
		$resultFile=$';
		my $tempFile=$`;
		my $url=$1;
		if($url=~/name\W+appleConnectForm['"]/is)
		{
			my %formData1;
			$formFlag=1;
			if ($resultFile=~/<\/form/is)
			{
				$resultFile=$`;
			}
			if($url=~/action\W+(.*?)['"]/is)
			{
				$url=$1;
				$site=~/(.*\/)/is;
				$url=$1.$url;
			}
			$this->parseAvailOptions(\%formData1,$resultFile);
			$formData1{'theAccountName'}='magappzine';
			$formData1{'theAccountPW'}='IronMan116';
			$formData1{'1.Continue.x'}='18';
			$formData1{'1.Continue.y'}='28';
			$response='';
			$response=$mech->post($url,\%formData1);
			$htmlPage='';
			if($response->is_success)
			{
				$htmlPage=$mech->content();
				open(FILE,">content.html");
				print FILE $htmlPage;
				$loginFlag=1;
			}
			return 1;
		}
	 }
	if($formFlag==0)
	{
		$this->getErrorString(2,'Home page not found.',1);		
	}
	elsif($loginFlag==0)
	{
		$this->getErrorString(5,'not logged in.',1);		
	}
}
##############################################################################
sub checkForLogin
{
	my $this=shift;
	my ($resultFile)=@_;
	if(($resultFile=~/>Your\s+Apple\s+ID\s+or\s+password\s+was\s+entered\s+incorrectly\W+</is) or ($resultFile=~/type\W+password['"]/is))
	{
		$this->getErrorString(5,'Login failure.',1);
	}
	#$loginFlag=1;---to be considered later
}
##############################################################################
sub clickmanageURapps
{
	my $this=shift;
	my ($resultFile)=@_;
	if($resultFile=~/>\s*Manage\s+Your\s+Apps\s*</is)
	{
		$resultFile=$`;
		$resultFile=~/.*href\W+(.*?)['"]/is;
		my $url=$1;
		$site=~/(.*\/)/is;
		$url=$1.$url;
		$response='';
		$response=$mech->get($url);
		$htmlPage='';
		if($response->is_success)
		{
			$htmlPage=$mech->content();
			open(FILE,">content.html");
			print FILE $htmlPage;
		}
	}
	if($htmlPage=~/class\W+upload\W+app\W+button['"]/is)
	{
		$previousPage=$htmlPage;
	}
	else
	{
		print"Manage your apps not clicked properly\n";
	}
}
##############################################################################
sub clickseeAll
{
	my $this=shift;
	my ($resultFile)=@_;
	if($resultFile=~/>\s*See\s+All\s*</is)
	{
		$resultFile=$`;
		$resultFile=~/.*href\W+(.*?)['"]/is;
		my $url=$1;
		$site=~/(.*\/)/is;
		$url=$1.$url;
		$response='';
		$response=$mech->get($url);
		$htmlPage='';
		if($response->is_success)
		{
			$htmlPage=$mech->content();
			open(FILE,">content.html");
			binmode(FILE, ":utf8");
			print FILE $htmlPage;
		}
		if($htmlPage=~/>\s*Apple\s+ID\s*</is)
		{
			$previousPage=$htmlPage;
		}
		else
		{
			print"See all not clicked properly\n";
		}
	}
}
##############################################################################
sub clickappName
{
	my $this=shift;
	my ($resultFile)=@_;
	$this->clearFile(\$resultFile);
	my $bufferFile=$resultFile;
	my $providedappName=$appName;
	$providedappName=~s/\W+//g;
	$providedappName=lc$providedappName;
	my $clickFlag=0;
	my $currentPageno="";
	my $cnt=1;
	my $tempcnt=$cnt;
	my $maxpageno;
	$this->prcurrPageno($resultFile,\$currentPageno,\$maxpageno);
	if($currentPageno eq "")
	{
		print"Can't get the current page no check out\n";
	}
	if($resultFile=~/class\W+resultList['"]>/is)
	{
		$resultFile=$';

		$resultFile=~/<\/table/is;
		$resultFile=$`;
		while($resultFile=~/<div\s+class\W+software\W+column\W+type\W+col\W+0\s+sorted">/is)
		{
			$resultFile=$';
			my $tempFile=$';
			$tempFile=~/<\/div/is;
			$tempFile=$`;
			if($tempFile=~/<p>(.*?)<p/is)
			{
				$tempFile=$1;
				if($tempFile=~/<a\s+href\W+(.*?)["']>(.*?)<\/a/is)
				{
					my $tempappName=$2;
					my $url=$1;
					$tempappName=~s/\W+//g;
					$tempappName=lc$tempappName;
					if($tempappName eq $providedappName)
					{
						$site=~/(.*\/)/is;
						$url=$1.$url;
						$response='';
						$response=$mech->get($url);
						$htmlPage='';
						$clickFlag=1;
						if($response->is_success)
						{
							$htmlPage=$mech->content();
							open(FILE,">Previouscontent.html");
							binmode(FILE, ":utf8");
							print FILE $htmlPage;
							return;
						}
					}
				}
			}
		}
		
		if(($currentPageno+1)>$maxpageno)
		{
			print"Could not get the App name\n";
			return;
		}
		if($clickFlag==0)
		{
			$this->clickNext($bufferFile,\$cnt);
		}
		if($cnt == $tempcnt)
		{
			print"Next not clicked properly\n";	
			return;
		}
		else
		{
			$previousPage=$htmlPage;
		}
	}
}
##############################################################################
sub clickNext
{
	my $this=shift;
	my ($resultFile,$cnt)=@_;
	$this->clearFile(\$resultFile);
	if($resultFile=~/>\s*Next\s*</is)
	{
		$resultFile=$`;
		$resultFile=~/.*href\W+(.*?)['"]/is;
		my $url=$1;
		$site=~/(.*\/)/is;
		$url=$1.$url;
		$response='';
		$response=$mech->get($url);
		$htmlPage='';
		if($response->is_success)
		{
			$htmlPage=$mech->content();
			open(FILE,">content.html");
			binmode(FILE, ":utf8");
			print FILE $htmlPage;
			$$cnt++;
			$main->clickappName($htmlPage);
			return;
		}
	}
}
##############################################################################
sub prcurrPageno
{
	my $this=shift;
	my ($resultFile,$currentPageno,$maxpageno)=@_;
	$this->clearFile(\$resultFile);
	while($resultFile=~/<table(.*?)>/is)
	{
		my $attrib=$1;
		$resultFile=$';
		if($attrib=~/class\W+controls['"]/is)
		{
			$resultFile=~/<\/table/is;
			$resultFile=$`;
			if($resultFile=~/>\s*Page\s*</is)
			{
				$resultFile=$';
				while($resultFile=~/input(.*?)>/is)
				{
					my $inputattrib=$1;
					$resultFile=$';
					if($inputattrib=~/name\W+currPage['"]/is)
					{
						$inputattrib=~/value\W+(.*?)['"]/is;
						$$currentPageno=$1;
						$resultFile=~/(.*?)<\/td/is;
						$$maxpageno=$1;
						$$maxpageno=~s/\D+//g;
						print"Searching App name on page no is $$currentPageno...\n";
						return;
					}
				}
			}
		}
	}
}
##############################################################################
sub clickManageInAppPurchases
{
	my $this=shift;
	my ($resultFile)=@_;
	if($resultFile=~/>\s*Manage\s+In\W+App\s+Purchases\s*</is)
	{
		$resultFile=$`;
		$resultFile=~/.*href\W+(.*?)['"]/is;
		my $url=$1;
		$site=~/(.*\/)/is;
		$url=$1.$url;
		$response='';
		$response=$mech->get($url);
		$htmlPage='';
		if($response->is_success)
		{
			sleep(3);
			$htmlPage=$mech->content();
			open(FILE,">content.html");
			binmode(FILE, ":utf8");
			print FILE $htmlPage;
		}
	}
	if($htmlPage=~/\W+In\W+App\s+Purchases\s+</is)
	{
		$previousPage=$htmlPage;
	}
	else
	{
		print" Button manage In App Purchases not clicked properly\n";
	}
}
##############################################################################
sub clickMagzineNext
{
	my $this=shift;
	my ($resultFile)=@_;
	if($resultFile=~/['"]pageNumberActionUrl\W+(.*?)['"]/is)
	{
		my $pageactionurl=$1;
		#$resultFile=$`;
		#$resultFile=~/.*href\W+(.*?)['"]/is;
		$site=~/(.*\/)/is;
		$pageactionurl=$1.$pageactionurl.'?pageNumber=2';
		$pageactionurl='https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa/wo/30.0.0.7.3.0.9.3.3.1.0.13.1.1.11.1.3.13.36?pageNumber=2';
		$response='';
		my %hs;
		#$hs{pageNumber}=2;
		$response=$mech->post($pageactionurl,\%hs);
		$htmlPage='';
		if($response->is_success)
		{
			$htmlPage=$mech->content();
			open(FILE,">content.html");
			binmode(FILE, ":utf8");
			print FILE $htmlPage;
		}
	}
	#if($htmlPage=~/\W+In\W+App\s+Purchases\s+</is)
	#{
		#$previousPage=$htmlPage;
	#}
	#else
	#{
		#print" Button manage In App Purchases not clicked properly\n";
	#}
}
##############################################################################
sub parseAvailOptions
{    
	my $this=shift;
	my ($formData,$resultFile)=@_;
	my $nm;
	while($resultFile=~/<(select|input)/is)
	{
		my $tempFile;
		$resultFile=$';
		$tempFile=$';
		if($1 eq "Input" or $1 eq "input" or $1 eq "INPUT")
		{
			$tempFile=~/(.+?>)/is;    
			$tempFile=$1;
			if(!(($tempFile=~/type\W+button/i) or ($tempFile=~/type\W+image/i) or ($tempFile=~/type\W+submit/i)))
			{
				if($tempFile=~/name\s*=\s*["'](.*?)["']/is)
				{
					$nm=$1;
					if(!($tempFile=~/type\W+radio/is or $tempFile=~/type\W+checkbox/is))
					{
						if($tempFile=~/value\s*=\s*["'](.*?)["']/is)
						{
							$tempFile=$1;
						}
						elsif($tempFile=~/value\s*=(.+?)[>\s]/is)
						{
							$tempFile=$1;
						}
						else
						{
							$tempFile="";
						}
						if(exists($formData->{$nm}))
						{
							$formData->{$nm}=$formData->{$nm}."&".$nm."=".$tempFile;	
						}
						else
						{
							$formData->{$nm}=$tempFile;
						}
					}
					elsif($tempFile=~/type\W+checkbox/is)
					{
						if ($tempFile=~/checked/is) 
						{
							if($tempFile=~/value\s*=\s*["'](.*?)["']/is)
							{
								$tempFile=$1;
							}
							else
							{
								$tempFile="on";
							}
							if(exists($formData->{$nm}))
							{
								$formData->{$nm}=$formData->{$nm}."&".$nm."=".$tempFile;	
							}
							else
							{
								$formData->{$nm}=$tempFile;
							}
						}
						else
						{
							$formData->{$nm}="";
						}
					}					
					if($tempFile=~/type\W+radio/i and $tempFile=~/checked/i)
					{
						if($tempFile=~/value\s*=\s*["'](.*?)["']/is)
						{
							$tempFile=$1;
						}
						elsif($tempFile=~/value\s*=(.+?)[>\s]/is)
						{
							$tempFile=$1;
						}
						$formData->{$nm}=$tempFile;
					}
				}
			}
		}
		elsif($1 eq "Select" or $1 eq "select" or $1 eq "SELECT")
		{
			$tempFile=~/(.+?>)/is;
			$tempFile=$1;
			if($tempFile=~/name\W+(.*?)['">\s]/is)
			{
				$nm=$1;
				if($resultFile=~/<\/select/is)
				{
					$resultFile=$';
					$tempFile=$`."</select";
				}
				elsif($resultFile=~/<select/is)
				{
					$tempFile=$`;
				}
				if($tempFile=~/.*(<option.*?selected.*?>)/is)
				{
					$tempFile=$1;
				}
				elsif($tempFile=~/<\/option/is)
				{
					$tempFile=$`;
				}
				else
				{
					$tempFile="";
				}
				if($tempFile=~/value\s*=\s*['"](.*?)['"]/i)
				{
					$tempFile=$1;
				}
				elsif($tempFile=~/value\s*=(.+?)[>\s]/i)
				{
					$tempFile=$1;
				}
				else
				{
					$tempFile="";
				}
				$formData->{$nm}=$tempFile;
			}
		}
		$nm="";
	}
	return 1;
}
##############################################################################
sub clearFile	
{
	my $this = shift;
	my ($resultFile)=@_;
	$$resultFile=~s/&nbsp\;//isg;
	$$resultFile=~s/&amp\;/&/isg;
	$$resultFile=~s/\&quot\;/\%22/isg;
	$$resultFile=~s/<!--.*?-->//isg;
	$$resultFile=~s/&middot\;//isg;
    $$resultFile=~s/&ntilde\;//isg;
    $$resultFile=~s/&oacute\;//isg;
    $$resultFile=~s/&uacute\;//isg;
    $$resultFile=~s/&aacute\;//isg;
	$$resultFile=~s/\\u0022/\"/isg;
	$$resultFile=~s/\\u0027/\'/isg;
	$$resultFile=~s/\\u003e/>/isg;
	$$resultFile=~s/\\u003c/</isg;
	$$resultFile=~s/\&gt\;//isg;
}
##############################################################################
sub getErrorString	
{
	my $this = shift;
	my ($flg,$errorString,$process)=@_;
	$nflag=1;
	$flag1=$flg;
	my $flagMsg;
	if ($flg==1)
	{
		$flagMsg='room not found';
	}
	elsif ($flg==2)
	{
		$flagMsg='change in website';
	}	
	elsif ($flg==4)
	{
		$flagMsg='hotel not found';
	}
	elsif ($flg==5)
	{
		$flagMsg='login failure';
	}
	elsif ($flg==6)
	{
		$flagMsg='website restriction';
	}
	elsif ($flg==8)
	{
		$flagMsg='invalid 3rd id';
	}
	elsif ($flg==9)
	{
		$flagMsg='unknown error';
	}
	elsif ($flg==10)
	{
		$flagMsg='invalid input';
	}
	elsif ($flg==11)
	{
		$flagMsg='invalid rate type';
	}
	if($process==0)
	{
		return 0;
	}
	elsif($process==1)
	{
		goto ENDPROCESS;
	}
}
##############################################################################
sub new
{
	my $type=shift;
	my $this = {};
	bless $this,$type;
    return $this;
}
