#!/usr/bin/perl	-w
#************************************************#
#happyHoliday.pl by Kushal on 28-Aug-2012
#Room Mapping is room=Room Name##Room ID
#e.g. (room=Deluxe Double or Twin Room##36).
#************************************************#
BEGIN
{
	unshift(@INC,"/www/include");
}
package main;
use strict;
use vars qw(@ISA);
use WNS;
require Exporter;
@ISA = qw(WNS Exporter);
my $localpath = `pwd`;
chop $localpath;
my $main = new main(locpath => $localpath);
$| = 1;
my $phpath = $main->{phpath};
my $phpath1 = $main->{phpath1};
my $nflag=0;
my $flag1=0;
my $dateErrStr;
my $textFile = $ARGV[0];
my $textFile1 = $textFile;
$textFile1 =~ s/^$phpath\///;
my ($proxyFlag,$proxy_server)=(0,"");
$main->setProxy($proxyFlag,$proxy_server);
my ($headerFname, $resultFname, $site);
($headerFname = $textFile) =~ s/^(.*)\.txt$/$1_c\.txt/;
($resultFname = $textFile) =~ s/^(.*)\.txt$/$1_r\.html/;
my %fileData = $main->getFileData($textFile);
my @roomInfo = @{$main->getRoomInfo(%fileData)};
my $url = $fileData{websiteURL};
$site=$url;
if ($url!~/\/$/s)
{
	$site.="/";
}
my $site1;
my $method = 'get';
my $content = "";
my $cookieSetOrRead = 'set';
my $finalMessage;
my $cookFile=`pwd`;
chop $cookFile;
$cookFile=$cookFile."/mycook_".$headerFname;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$mon=$mon+1;
$year=$year+1900;
$mon=int($mon);
$mday=int($mday);
my $currDate=$mday.'/'.$mon.'/'.$year;
my $mailFlag=0;
my $dateErrStr1;
#***************** change in fileData ***********#
$fileData{submissiondate} = $main->convertDateTo224($fileData{submissiondate});
$fileData{submissiontime} = $main->convert24to12($main->convert12to24($fileData{submissiontime}));
#***************** GET LOGIN PAGE ***************#
if($fileData{websiteusername} eq "" or $fileData{websitepassword} eq "" or $fileData{start} eq "" or $fileData{end} eq "" or $fileData{websiteURL} eq "" )
{
	$main->getErrorString(10,'Website username or Website password or Start date or end date or websiteURL is blank.',1);
}
my $loginFlag=0;
#************************************************#
print "Going to get Login page ...\n"; 
$main->getCurlData19($url,$resultFname,$method,$content,$headerFname,$cookieSetOrRead,$cookFile);
print "Going to do login...\n";
$main->parseLoginPage($resultFname,\$url,\$method,\$cookieSetOrRead,\$content);
$main->getCurlData19($url,$resultFname,$method,$content,$headerFname,$cookieSetOrRead,$cookFile);
print "Going to check for login...\n";
$main->checkForLogin($resultFname);
print "Going redirect for login...\n";
$main->redirectLogin($resultFname);
my $logOutFile=$main->readFile($resultFname);
print "Going to click manageEvents.\n";
$main->clickmanageEvents($resultFname);
print "Going to check event and click manage.\n";
$main->checkEventNclickmanage($resultFname);
print "Going to check hotel and click manage.\n";
$main->checkHotelNclickmanage($resultFname);
print "Going to parse room and update data...\n";
$main->parseRoomAndUpdate($resultFname);
#************************************************#
if($nflag == 0)
{
	print "Successfully done...\n";	
	$flag1=0;
	$finalMessage="Successfully Submitted";
	$main->updateDatabase($flag1,$finalMessage,$localpath,$textFile);
	$main->updateReportFile(1,$textFile1,join(" ### ", $main->currentTime, $fileData{submissiondate}.' '.$fileData{submissiontime}, $fileData{hotelname}, $fileData{websiteURL}, $fileData{start}, $fileData{end}, $textFile1, 'Successfully Submitted'));
	`mv $textFile $phpath1/success/`;
}
#************************************************#
ENDPROCESS:
#************************************************#
if($nflag == 1)
{
	print "Failure...\n";
	$main->updateDatabase($flag1,$finalMessage,$localpath,$textFile);
	if($flag1 == 2)
	{
		my ($from,$to,$subject,$data);
		$from = "internetupdates\@d2etechnologies.com";
		$to = "websiteissues\@d2etechnologies.com";
		$subject = "$fileData{hotelname}/$fileData{websitename} submissions";
		$data = qq{
			There has been a change in website $fileData{websitename} which is affecting the submission of data to the site.<br/>
			<br/> This is an automatic error reporting mechanism.
		};
		#$main->sendEmail($from,\$to,$subject,$data);
		`mv $textFile $phpath1/failure/`;
	}
	elsif($flag1==3)
	{
		my ($from,$to,$subject,$data);
		$main->getFrom(\$from);
		$to = $fileData{contactemail};
		$subject = "$fileData{hotelname}/$fileData{websitename} submissions";
		$data = qq{
			 Please check your account with $fileData{websitename}  Submissions received today have failed because the following room types, $dateErrStr do not have inventory for the following date range $fileData{start} to $fileData{end}.<br/>
			 <br/> Similar submissions will continue to fail until inventory is extended.  Thanks.
		};
		#$main->sendEmail($from,\$to,$subject,$data);
		`mv $textFile $phpath1/date_failures/`;
	}
	elsif($mailFlag==1)
	{
		my ($from,$to,$subject,$data);
		$main->getFrom(\$from);
		$to = $fileData{contactemail};
		$subject = "$fileData{hotelname}/$fileData{websitename} submissions";
		$data = qq{
				 Hello $fileData{contactname},<br><br>
  				 Please check your account with $fileData{websitename}.  Submissions received today for the $dateErrStr1 on $fileData{start} to $fileData{end} could not be processed.  There is currently no inventory available for this period.  Similar submissions will continue to fail until a base inventory has been added.<br><br>
				 This is an automated message.  Please do not respond directly.
		};
		#$main->sendEmail($from,\$to,$subject,$data);
		`mv $textFile $phpath1/alt_failures/`;
	}
	else
	{
		`mv $textFile $phpath1/failure/`;
	}
}
$main->logOut($logOutFile) if ($loginFlag==1);
unlink("$headerFname");
unlink("$resultFname");
unlink("$cookFile");
exit;
#************************************************#
sub getFrom
{
	my $this = shift;
	my ($from) = @_;
	my $resultFile = $this->readFile($textFile);
	if($resultFile=~/Instance\W+VIP/is)
	{
		$$from="merchantsupport\@vantiscorp.com";
	}
	else
	{
		$$from="internetupdates\@d2etechnologies.com";
	}
}
#************************************************#
sub new
{
	my $type = shift;
	my %parm = @_;
	my $this = $type->SUPER::new(%parm);
	bless $this,$type;
	return $this;
}
#=========================================================#
sub redirectLogin
{
	my $this=shift;
	my ($resultFname)=@_;
	my $resultFile=$this->readFile($resultFname);
	$this->clearFile(\$resultFile);
	my $content = "";
	my $method = "get";
	my $cookieSetOrRead="read";
	if ($resultFile=~/window.location\W+(.*?)['"]/is) 
	{
		my $url=$site.$1;
		$this->getCurlData19($url,$resultFname,$method,$content,$headerFname,$cookieSetOrRead,$cookFile);
	}
}
#=========================================================#
sub logOut
{
	my $this=shift;
	my ($resultFile)=@_;
	$this->clearFile(\$resultFile);
	my $content = "";
	my $method = "get";
	my $cookieSetOrRead="read";
	if ($resultFile=~/>\s*Logout\s*</is) 
	{
		$resultFile=$`;
		$resultFile=~/.*href\W+(.*?)["']/is;
		my $url=$site.$1;
		$this->getCurlData19($url,$resultFname,$method,$content,$headerFname,$cookieSetOrRead,$cookFile);
	}
}
#============================================================#
sub parseLoginPage
{
	my $this = shift;
	my ($resultFname,$url,$method,$cookieSetOrRead,$content)= @_;
	my $resultFile=$this->readFile($resultFname);
	$this->clearFile(\$resultFile);
	my $nm="";
	my %formData;
	$$content = "";
	$$method = "post";	
	$$cookieSetOrRead="read";
	my $formFlag=0;
	while($resultFile=~/<form(.*?)>/is)
	{
		$resultFile=$';
		my $tempFile=$`;
		$$url=$1;
		if($$url=~/name\W+login['"]/is)
		{
			my %formData1;
			my $content1;
			$formFlag=1;
			if ($resultFile=~/<\/form/is)
			{
				$resultFile=$`;
			}
			if($tempFile=~/xajaxRequestUri\W+(.*?)['"]/is)
			{				
				$$url=$1;
			}
			$this->parseAvailOptions(\%formData1,$resultFile);
			$formData1{'username'}=$fileData{websiteusername};
			$formData1{'password'}=$fileData{websitepassword};
			$formData1{'loginButton'}='Login';
			delete$formData1{'remember'};
			foreach $nm (keys %formData1)
			{
				$content1.="&".$nm."=".$formData1{$nm};
			}
			$content1=~s/\&/\%26/g;
			$content1=~s/\=/\%3D/g;
			$formData{'xajaxargs[]'}='<xjxquery><q>'.$content1.'</q></xjxquery>';
			$formData{'xajaxr'}=time * 1000;
			$formData{'xajax'}='checkUser';
			$nm='';
			foreach $nm (keys %formData)
			{
				$$content.="&".$nm."=".$formData{$nm};
			}
			$this->getContent1($content);
			return 1;
		}
	 }
	if($formFlag==0)
	{
		$this->getErrorString(2,'Home page not found.',1);		
	}
}
#=========================================================#
sub checkForLogin
{
	my $this=shift;
	my ($resultFname)=@_;
	my $resultFile=$this->readFile($resultFname);
	if($resultFile=~/\[\s*Wrong\s+username\s+and\W+or\s+password\s*\]/is)
	{
		$this->getErrorString(5,'Login failure.',1);
	}
	$loginFlag=1;
}
#=========================================================#
sub clickmanageEvents
{
	my $this = shift;
	my ($resultFname)=@_;
	my $resultFile=$this->readFile($resultFname);
	$this->clearFile(\$resultFile);
	my $url;
	my $content = "";
	my $method = "get";	
	my $cookieSetOrRead="read";
	if($resultFile=~/>\s*Manage\s+Events\s*</is)
	{
		$resultFile=$`;
		$resultFile=~/.*href\W+(.*?)['"]/is;
		$url=$1;
		$this->getCurlData19($url,$resultFname,$method,$content,$headerFname,$cookieSetOrRead,$cookFile);
		return 1;
	}
	else
	{
		$this->getErrorString(2,'Label --Manage Events-- not found.',1);
	}
}
#=========================================================#
sub checkEventNclickmanage
{
	my $this = shift;
	my ($resultFname)=@_;
	my $resultFile=$this->readFile($resultFname);
	$this->clearFile(\$resultFile);
	my $url;
	my $content = "";
	my $method = "get";	
	my $cookieSetOrRead="read";
	my $websiteOtherID=$fileData{websiteotherid};
	my (undef,$eventID,undef,undef)=split("##",$websiteOtherID);
	$eventID=~s/^\s+|\s+$//g;
	my $checkFlag=0;
	my $linkFlag=0;
	while($resultFile=~/>\s*Manage\s*</is)
	{
		$resultFile=$';
		$linkFlag=1;
		my $tempresultFile=$`;
		$tempresultFile=~/.*href\W+(.*?['"])/is;
		$url=$1;
		if($url=~/event\W+$eventID['"]/is)
		{
			$checkFlag=1;
			$url=~/(.*?)['"]/g;
			$url=$1;
			$site1=$url;
			$this->getCurlData19($url,$resultFname,$method,$content,$headerFname,$cookieSetOrRead,$cookFile);
			return 1;
		}		
	}
	if($linkFlag==0)
	{
		$this->getErrorString(2,'Label --Manage-- not found.',1);
	}
	if($checkFlag==0)
	{
		$this->getErrorString(8,'Event id is not correct.',1);
	}
}
#=========================================================#
sub checkHotelNclickmanage
{
	my $this = shift;
	my ($resultFname)=@_;
	my $resultFile=$this->readFile($resultFname);
	$this->clearFile(\$resultFile);
	my $url;
	my $content = "";
	my $method = "get";	
	my $cookieSetOrRead="read";
	my $websiteOtherID=$fileData{websiteotherid};
	my (undef,undef,undef,$hotelID)=split("##",$websiteOtherID);
	$hotelID=~s/^\s+|\s+$//g;
	my $checkFlag=0;
	my $linkFlag=0;
	while($resultFile=~/>\s*Manage\s*</is)
	{
		$resultFile=$';
		$linkFlag=1;
		my $tempresultFile=$`;
		$tempresultFile=~/.*href\W+(.*?['"])/is;
		$url=$1;
		if($url=~/hotel\W+$hotelID['"]/is)
		{
			$checkFlag=1;
			$url=~/(.*?)['"]/g;
			$url=$1;
			$this->getCurlData19($url,$resultFname,$method,$content,$headerFname,$cookieSetOrRead,$cookFile);
			return 1;
		}		
	}
	if($linkFlag==0)
	{
		$this->getErrorString(2,'Label --Manage-- not found.',1);
	}
	if($checkFlag==0)
	{
		$this->getErrorString(4,'Hotel id is not correct.',1);
	}
}
#=========================================================#
sub parseRoomAndUpdate
{
	my $this=shift;
	my ($resultFname)=@_;
	my $resultFileBuffer=$this->readFile($resultFname);
	$this->clearFile(\$resultFileBuffer);
	for my $refRoom(@roomInfo)
	{
		if(ref($refRoom) eq "HASH")
		{
			my ($roomName,$roomID)=split("##",$refRoom->{"room"});
			my($m1,$d1,$y1)=split("/",$fileData{'start'});
			my $startDt=$d1."/".$m1."/".$y1;			
			my($m2,$d2,$y2)=split("/",$fileData{"end"});
			my $endDt=$d2."/".$m2."/".$y2;
			$refRoom->{'alot'}="" if($refRoom->{'alot'} eq 'NC');
			$refRoom->{'net'}="" if($refRoom->{'net'} eq 'NC');
			$roomID=~s/^\s+|\s+$//isg;
			my $startDt1=$startDt;
			if($refRoom->{"alot"} ne "" or $refRoom->{"avail"} eq "N" or $refRoom->{"avail"} eq "Y" or $refRoom->{"net"} ne "") 
			{
				print "Going to check room for room --- $roomName  ...\n";	
				if ($this->checkNsetRoom($resultFileBuffer,$roomID))
				{
					my $resultFile=$this->readFile($resultFname);
					print "Going to check date for room --- $roomName  ...\n";
					if ($this->checkDate(\$startDt,\$endDt,$roomName,$resultFile))
					{	
						my %formData;
						print "Going to set data for room --- $roomName  ...\n";
						my $updateFlag=0;
						my $startDt1=$startDt;
						while($this->dateCompare($endDt,$startDt1)>=0)
						{
							my ($d,$m,$y)=split("\/",$startDt1);#15/11/2012
							my $tempstartDt=$y.'-'.$m.'-'.$d;
							if ($refRoom->{'net'} ne "")
							{
								if ($this->getUrl($resultFile,\$url,$tempstartDt,0))
								{
									if ($this->setActualData(\%formData,$refRoom))
									{
										print "Going to update final page for room --- $roomName  ...\n";
										$this->updateFinalPage(\%formData,$url);
										$updateFlag=1;
									}
								}									
							}
							elsif ($refRoom->{'alot'} ne "")
							{
								if ($this->getUrl($resultFile,\$url,$tempstartDt,1))
								{
									if($refRoom->{'avail'} eq "Y" or $refRoom->{'avail'} eq "N")
									{
										if ($this->setActualData(\%formData,$refRoom))
										{
											print "Going to update final page for room --- $roomName  ...\n";
											$this->updateFinalPage(\%formData,$url);
											$updateFlag=1;
										}
									}
								}	
							}
							elsif ($refRoom->{'avail'} eq "Y" or $refRoom->{'alot'} eq "")
							{
								#error
							}
							
							$startDt1=$this->dateAdd($startDt1,1);
						}
						if ($updateFlag==1)
						{
							my %formData1;
							print "Going to set date to verify data for room --- $roomName  ...\n";
							if ($this->checkNsetRoom($resultFileBuffer,$roomID))
							{
								print "Going to get data to verify for room --- $roomName  ...\n";
								$this->getData($resultFname,\%formData1,$startDt,$endDt);#$startDt,$endDt
								print "Going to verify thr data for room --- $roomName  ...\n";
								$this->verificationCode(\%formData1,$refRoom,$startDt,$endDt);
							}
						}
									
					}
				}
			}
		}
	}
}
#=========================================================#
sub getDate
{
	my $this=shift;
	my ($webEndDate,$resultFile)=@_;
	if ($resultFile=~/.*addroombydate.php\W+event\W+\d+\W+date\W+(\d\d\d\d\-\d\d\-\d\d)&/is)
	{
		$$webEndDate=$1;
	}
}
#=========================================================#
sub checkNsetRoom
{
	my $this=shift;
	my ($resultFile,$roomID)=@_;
	$this->clearFile(\$resultFile);
	my $url;
	my $content = "";
	my $method = "get";	
	my $cookieSetOrRead="read";
	if($roomID eq "")
	{
		$this->getErrorString(10,'Room ID not provided.',0);
	}
	$roomID=~s/\W+//g;
	if($resultFile=~/href\W+(showonlycategory.php\Wroom=$roomID&event\W+\d+&hotel\W+\d+)['"]/is)
	{
		$url=$1;
		$site1=~/(.*?\/\/.*?\/.*?\/.*?\/)/;
		$url=$1.$url;
		$this->getCurlData19($url,$resultFname,$method,$content,$headerFname,$cookieSetOrRead,$cookFile);
		return 1;
	}
	else
	{
		$this->getErrorString(1,'Room ID--'.$roomID.' -- not found.',0);
		return 0;
	}	
}
#=========================================================#
sub checkDate
{
	my $this = shift;
	my ($startDt,$endDt,$roomName,$resultFile) = @_;
	my $webEndDt;
	$this->getDate(\$webEndDt,$resultFile);
	my ($y,$m,$d)=split('-',$webEndDt);
	$webEndDt=$d.'/'.$m.'/'.$y;
	if ($webEndDt !~ /\d+\/\d+\/\d\d\d\d/is)
	{
		$this->getErrorString(2,'Could not parse WebEnd Date.',1);
	}
	if($this->dateCompare($currDate,$$startDt)>0)
	{
		$$startDt=$currDate;
		$this->createDateErrStr(\$dateErrStr,$roomName);
		$this->getErrorString(3,'Start date is less than current date.',0);
	}
	if($this->dateCompare($$endDt,$webEndDt)>0)
	{
		$$endDt=$webEndDt;
		$this->createDateErrStr(\$dateErrStr,$roomName);
		$this->getErrorString(3,'End Date is greater than webend date.',0);
	}
	if($this->dateCompare($$startDt,$$endDt)>0)
	{
		$this->createDateErrStr(\$dateErrStr,$roomName);
		$this->getErrorString(3,'Invalid date range.',0);
		return 0;
	}
	return 1;
}
#=========================================================#
sub updateFinalPage
{
	my $this=shift;
	my ($formData,$url)=@_;
	my $nm="";
	my $method = "post";
	my $cookieSetOrRead = "read";
	my $content="";
	foreach $nm (keys %$formData)
	{
		$formData->{$nm}=~s/\=/\%3D/isg;
		$content.="&".$nm."=".$formData->{$nm};
	}
	$this->getContent(\$content);
	$this->getCurlData17($url,$resultFname,$method,$content,$headerFname,$cookieSetOrRead,$cookFile);
	return 1;
}
#==============================================================#
sub getUrl
{
	my $this=shift;
	my ($resultFile,$url,$tempstartDt,$flowFlag)=@_;
	my $chkFlag=0;
	while($resultFile=~/Ajax.InPlaceEditor\W+roomies\d+\W+(.*?)['"]/is)
	{
		my $tempurl=$1;
		$chkFlag=1;
		$resultFile=$';
		my $tempresultFile=$`;
		if($tempurl=~/date\W+$tempstartDt\&/is)
		{
			if($flowFlag==0)
			{
				$tempresultFile=~/.*Ajax.InPlaceEditor\W+price\d+\W+(.*?type\W+price)['"]/is;
				$$url=$1;
				return 1;
			}
			elsif($flowFlag==1)
			{
				$$url=$tempurl;
				return 1;
			}
		}
	}
	if($chkFlag==0)
	{
		$this->getErrorString(2,"Url search pattern not found.",1);
		return 0;
	}
}
#=========================================================#
sub setActualData
{
	my $this=shift;
	my ($formData,$refRoom)=@_;
	if ($refRoom->{'net'} ne "")
	{	
		my $net=sprintf("%.2f",$refRoom->{"net"});			
		$formData->{'editvalue'}=$net;
		$formData->{'_'}='';		
	}
	if ($refRoom->{'alot'} ne "" and $refRoom->{'avail'} ne "")
	{
		if ($refRoom->{'avail'} eq 'N')
		{
			$formData->{'editvalue'}=0;
			#$formData->{'_'}='';
		}
		elsif($refRoom->{'avail'} eq 'Y')
		{
			$formData->{'editvalue'}=$refRoom->{'alot'};
			#$formData->{'_'}='';
		}	
	}
	return 1;
}
#=========================================================#
sub getData
{
	my $this=shift;
	my ($resultFname,$formData1,$startDt,$endDt)=@_;
	my $resultFile=$this->readFile($resultFname);
	$this->clearFile(\$resultFile);
	my $rowID;
	while($this->dateCompare($endDt,$startDt)>=0)
	{
		my ($d,$m,$y)=split("\/",$startDt);#15/11/2012
		my $tempstartDt=$y.'-'.$m.'-'.$d;
		if($resultFile=~/Ajax.InPlaceEditor\W+roomies(\d+)\W+http\W+www.delmayandpartners.com\W+admin\W+events\W+addroombydate.php\W+event\W+\d+&date\W+$tempstartDt\&.*?['"]/is)
		{
			$rowID=$1;
			my $tempresultFile=$`;
			if($tempresultFile=~/<div\s+id\W+roomies$rowID["'].*?>(.*?)<\/div>/is)
			{
				$formData1->{'alot_'.$startDt}=$1;
			}
			$tempresultFile=~/.*Ajax.InPlaceEditor\W+price\d+\W+(.*?type\W+price)['"]/is;
			if($tempresultFile=~/<div\s+id\W+price$rowID["'].*?>(.*?)<\/div>/is)
			{
				$formData1->{'net_'.$startDt}=$1;
			}
		}
		$startDt=$this->dateAdd($startDt,1);
	}
	return 1;	
}
#=========================================================#
sub verificationCode
{
	my $this=shift;
	my ($formData,$refRoom,$startDt,$endDt)=@_;	
	my $verificationFlag=0;
	while ($this->dateCompare($startDt,$endDt) <=0)
	{
		my ($d,$m,$y)=split ("/",$startDt);
		$d="0".int $d if ($d<10);
		$m="0".int $m if ($m<10);
		$startDt=$d."/".$m."/".$y;
		if ($refRoom->{'alot'} ne "")
		{
			if (exists $formData->{'alot_'.$startDt})
			{
				if(($formData->{'alot_'.$startDt}) ne $refRoom->{"alot"})
				{
					$verificationFlag=1;
					last;
				}
			}
		}		
		if($refRoom->{'net'} ne "")
		{
			if (exists $formData->{'net_'.$startDt})
			{
				my $net=sprintf("%.2f",$refRoom->{"net"});
				my $parsenet=sprintf("%.2f",$formData->{'net_'.$startDt});
				if ($parsenet != $net)
				{
					$verificationFlag=1;
					last;
				}
			}
		}
		$startDt=$this->dateAdd($startDt,1);
	}
	if ($verificationFlag ==1)
	{
		$this->getErrorString(7,"could not update properly.",0);
	}
	return 1;
}
#************************************************#
sub dateCompare
{
	my $this=shift;
	my ($d1,$d2) = @_;
	$d1=~s/\s//g;
	$d2=~s/\s//g;
	$d1=~s/\W/\//g;
	$d2=~s/\W/\//g;	
	my($day1,$mon1,$yr1) =split("\/",$d1);
	my($day2,$mon2,$yr2) =split("\/",$d2);	
	if($yr1>$yr2)
	{return 1;}
	elsif($yr1<$yr2)
	{return -1;}
	elsif($mon1>$mon2)
	{return 1;}
	elsif($mon1<$mon2)
	{return -1;}
	elsif($day1>$day2)
	{return 1;}
	elsif($day1<$day2)
	{return -1;}
	else
	{return 0;}
}
#************************************************#
sub dateAdd
{
	my $this=shift;
	my ($d1,$numDays) = @_;
	$d1=~s/\s//g;
	$d1=~s/\W/\//g;
	my $dysInMonth;
	my($day,$mon,$yr) =split("\/",$d1);
	while($numDays>0)
	{	
		$dysInMonth=$this->daysInMonth($mon,$yr);
		if($numDays-($dysInMonth-$day)>0)
		{
			$numDays=$numDays-($dysInMonth-$day);
			$day=0;
			$mon=($mon%12)+1;
			if($mon==1)
			{
				$yr=$yr+1;
			}	
		}
		else
		{
			$day=$numDays+$day;
			$numDays=0;
		}		
	}
	return $day."/".$mon."/".$yr;
}
#************************************************#
sub daysInMonth
{
	my $this=shift;
	my ($theMonth,$theYear) = @_;
	my @mon=(
		"31",
		"28",
		"31",
		"30",
		"31",
		"30",
		"31",
		"31",
		"30",
		"31",
		"30",
		"31"
	);
	my $dys = $mon[$theMonth-1];		
	if ($theMonth == 2) 
	{ 	if ($theYear%400==0 || ($theYear%4 == 0 && $theYear%100!=0) )
		{
			$dys +=1; 
		}
	}
	return $dys;
}
#************************************************#
sub dateDiff
{
	my $this=shift;
	my ($dt1,$dt2) = @_;
	my $dt3;
	my $dys=0;
	my $flg=$this->dateCompare($dt1,$dt2);
	if($flg==-1)
	{
		$dt3=$dt1;
		$dt1=$dt2;
		$dt2=$dt3;
	}
	elsif($flg==0)
	{
		return 0;
	}
	my ($day1,$mon1,$yr1)=split("\/",$dt1);
	my ($day2,$mon2,$yr2)=split("\/",$dt2);
	if(($yr1-$yr2)>1)
	{
		$dys=($yr1-$yr2-1)*365;
		$dt2=$this->dateAdd($dt2,$dys);
	}	
	while($this->dateCompare($dt1,$dt2)!=0)
	{		
		$dt2=$this->dateAdd($dt2,1);
		++$dys;
	}
	return $dys;
}
#************************************************#
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
#************************************************#
sub getErrorString	#(errorcode,message,return)
{
	my $this = shift;
	my ($flg,$errorString,$process)=@_;
	$nflag=1;
	$flag1=$flg;
	$finalMessage=$errorString;
	$this->updateReportFile(0,$textFile1,join(" ### ", $this->currentTime, $fileData{submissiondate}.' '.$fileData{submissiontime}, $fileData{hotelname}, $fileData{websiteURL}, $fileData{start}, $fileData{end}, $textFile1, $errorString));
	if($process==0)
	{
		return 0;
	}
	elsif($process==1)
	{
		goto ENDPROCESS;
	}
}
#************************************************#
sub createDateErrStr
{
	my $this = shift;
	my ($dateErrStr,$roomName)=@_;
	$roomName=~s/\(/\%28/g;
	$roomName=~s/\)/\%29/g;
	$roomName=~s/\*/\%2A/g;
	$roomName=~s/\&/\%26/g;
	$roomName=~s/\//\%2F/g;
	$$dateErrStr=~s/\(/\%28/g;
	$$dateErrStr=~s/\)/\%29/g;
	$$dateErrStr=~s/\*/\%2A/g;
	$$dateErrStr=~s/\&/\%26/g;
	$$dateErrStr=~s/\//\%2F/g;
	if($$dateErrStr!~/$roomName,/is)
	{
	$$dateErrStr.=$roomName.",";
	}
	$$dateErrStr=~s/\%28/\(/g;
	$$dateErrStr=~s/\%29/\)/g;
	$$dateErrStr=~s/\%2A/\*/g;
	$$dateErrStr=~s/\%26/\&/g;
	$$dateErrStr=~s/\%2F/\//g;
	return 1;
}
#************************************************#
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
}
#************************************************#
sub getContent
{
	my $this = shift;
	my ($content)=@_;
	
	$$content =~ s/^\&(.*)$/$1/;
	$$content =~ s/\s/\%20/g;
	$$content =~ s/\+/\%2B/g;
	$$content =~ s/:/\%3A/g;
	$$content =~ s/\$/\%24/g;
	$$content =~ s/\//\%2F/g;
	$$content =~ s/\(/\%28/g;
	$$content =~ s/\)/\%29/g;
	$$content =~ s/\$/\%24/g;
	$$content =~ s/\|/\%7C/g;
	$$content =~ s/\,/\%2C/g;
	$$content =~ s/\[/\%5B/g;
	$$content =~ s/\]/\%5D/g;
	$$content =~ s/\'/\%27/g;
	$$content =~ s/\;/\%3B/g;
	$$content =~ s/\#/\%23/g;
}
#************************************************#
sub getContent1
{
	my $this = shift;
	my ($content)=@_;
	$$content =~ s/^\&(.*)$/$1/;
	$$content =~ s/\s/\%20/g;
	$$content =~ s/\+/\%2B/g;
	$$content =~ s/:/\%3A/g;
	$$content =~ s/\$/\%24/g;
	$$content =~ s/\//\%2F/g;
	$$content =~ s/\(/\%28/g;
	$$content =~ s/\)/\%29/g;
	$$content =~ s/\$/\%24/g;
	$$content =~ s/\|/\%7C/g;
	$$content =~ s/\,/\%2C/g;
	$$content =~ s/\'/\%27/g;
	$$content =~ s/\;/\%3B/g;
	$$content =~ s/\#/\%23/g;
	$$content=~s/</\%3C/g;
	$$content=~s/>/\%3E/g;
}
#*****************   END OF FILE   **************#
