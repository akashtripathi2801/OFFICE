BEGIN
{
	unshift(@INC,"../library");
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
my $logpath=$localpath.$main->{"logfile"};
my $foldername=$localpath.$main->{"folderName"};
my $finalXmlContent;
my $errorContent;
my $nflag=0;
my $flag1=0;
my $ref='';
my $ref1='';
my ($openRow,$closeRow)=(1,1);
my $commandline;
my $errorMessage;
while (@ARGV)
{
	$commandline = "$commandline"." ".shift(@ARGV);
}
#websiteID|WebsiteName|WebsiteOtherID|userName|password|websiteUrl|curreny|StartDate|endDate|hotelId|dateFormat|{room1},{room2},{room3}...|sessionID|website_markup_type|website_markup
#CommandLine='141972|Javool||test|testhot|http://www.javool.com/booking/admin/|Euro|2012-04-16|2012-04-16||yyyy-mm-dd|{1001##TRIPLA##Tripla},{2002##DOUBLE##Double},{3003##SUITE##Suite}|175hghusssy|Dollars|0'
my @commargs;
@commargs = split ("\\|",$commandline);
$commargs[0]=~s/\s+//isg;
##-------------------------------------------------------##
my $websiteID_cmd = $commargs[0];
my $websiteName_cmd = $commargs[1];
my $websiteOtherID_cmd = $commargs[2];
my $websiteUserName_cmd = $commargs[3];
my $websitePassword_cmd = $commargs[4];
my $url_cmd = $commargs[5];
my $curreny_cmd = $commargs[6];
my $startDate_cmd = $commargs[7];
my $endDate_cmd = $commargs[8];
my $hotelId_cmd = $commargs[9];
my $dateFormat_cmd = $commargs[10];
my $dBroomName_cmd=$commargs[11];
my $createFileName_cmd=$commargs[12];
my $website_markup_type_cmd=$commargs[13];
my $website_markup_cmd=$commargs[14];
$dateFormat_cmd=~s/\s+//sg;
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$mon=$mon+1;
$year=$year+1900;
$mon=int($mon);
$mday=int($mday);
my $currDate=$mday.'/'.$mon.'/'.$year;
##-------------------------------------------------------##
my %month1=("January"=>"01","February"=>"02","March"=>"03","April"=>"04","May"=>"05","June"=>"06","July"=>"07","August"=>"08","September"=>"09","Oktober"=>"10","November"=>"11","December"=>"12");
my $website_markup_type=$website_markup_type_cmd;
my $website_markup=$website_markup_cmd;
my $curr_symbol=$curreny_cmd;
my $script="delmayCompanion.pl";
my $logFile="delmay_".$websiteID_cmd."_".$hotelId_cmd." : ";
$main->appendHeader($logpath, $logFile.$commandline."...\n");
if($websiteID_cmd eq "" or $websiteUserName_cmd eq "" or $websitePassword_cmd eq "" or $url_cmd eq "" or $startDate_cmd eq "" or $endDate_cmd eq ""or $dBroomName_cmd eq "")
{
	$errorMessage='Invalid data in database.';
	$main->getErrorString(10,$errorMessage,1);
}
if($dateFormat_cmd=~/^mm\/dd\/yy/is)
{
	my ($m1,$d1,$y1)=split("/",$startDate_cmd);
	my ($m2,$d2,$y2)=split("/",$endDate_cmd);
	$startDate_cmd=$d1."/".$m1."/".$y1;
	$endDate_cmd=$d2."/".$m2."/".$y2;
}
elsif($dateFormat_cmd=~/^dd\/mm\/yy/is)
{
	my ($d1,$m1,$y1)=split("/",$startDate_cmd);
	my ($d2,$m2,$y2)=split("/",$endDate_cmd);
	$startDate_cmd=$d1."/".$m1."/".$y1;
	$endDate_cmd=$d2."/".$m2."/".$y2;
}
elsif($dateFormat_cmd=~/^yyyy-mm-dd/is)
{
	my ($y1,$m1,$d1)=split("-",$startDate_cmd);
	my ($y2,$m2,$d2)=split("-",$endDate_cmd);
	$startDate_cmd=$d1."/".$m1."/".$y1;
	$endDate_cmd=$d2."/".$m2."/".$y2;
}
my ($headerFname, $resultFname, $site,$cookFile);
$headerFname =$foldername."/".$websiteID_cmd."_".$hotelId_cmd."_".$createFileName_cmd."_c.txt";
$resultFname =$foldername."/".$websiteID_cmd."_".$hotelId_cmd."_".$createFileName_cmd."_r.html";
$cookFile=$foldername."/".$websiteID_cmd."_".$hotelId_cmd."_".$createFileName_cmd."_mycook.txt";
my @dbRoomInfo=split(",",$dBroomName_cmd);
my $url = $url_cmd;
my $site=$url;
my $method='get';
my $content="";
my $cookieSetOrRead='set';
my $loginFlag=0;
my $site1;
####################################################################
$main->appendHeader($logpath, $logFile."Going To get Home Page \n");  
$main->getCurlData19($url,$resultFname,$method,$content,$headerFname,$cookieSetOrRead,$cookFile);
$main->appendHeader($logpath, $logFile."Going To Parse Login Page \n");
$main->parseLoginPage($resultFname,\$url,\$method,\$cookieSetOrRead,\$content);
$main->getCurlData19($url,$resultFname,$method,$content,$headerFname,$cookieSetOrRead,$cookFile);
$main->appendHeader($logpath, $logFile."Going to check for login...\n");
$main->checkForLogin($resultFname);
$main->appendHeader($logpath, $logFile."Going redirect for login...\n");
$main->redirectLogin($resultFname);
my $logOutFile=$main->readFile($resultFname);
$main->appendHeader($logpath, $logFile."Going to click manageEvents.\n");
$main->clickmanageEvents($resultFname);
$main->appendHeader($logpath, $logFile."Going to check event and click manage.\n");
$main->checkEventNclickmanage($resultFname);
$main->appendHeader($logpath, $logFile."Going to check hotel and click manage.\n");
$main->checkHotelNclickmanage($resultFname);
$main->appendHeader($logpath, $logFile."Going to parse Room and Data.\n");
$main->parseRoomAndData($resultFname);
####----------------------------------------------------------------------------------------#
ENDPROCESS:
if($flag1 !=5)
{
	$main->appendHeader($logpath, $logFile."Going to Logout...\n");
	$main->logOut($logOutFile);
}
if($nflag==1)
{
	$errorContent="<errors>\n".$errorContent."</errors>\n";
}
else
{
	 $errorContent="";
}
if($openRow==0 and $closeRow==1)
{
	$finalXmlContent .=$main->getRowsClose();
}

$finalXmlContent =$main->getReportOpen($websiteName_cmd).$errorContent.$finalXmlContent.$main->getReportClose();
$finalXmlContent=~s/\&amp;/\&/isg;
$finalXmlContent=~s/\&/\&amp;/isg;
print "$finalXmlContent";
unlink("$headerFname");
unlink("$resultFname");
unlink("$cookFile");
exit;
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
			$formData1{'username'}=$websiteUserName_cmd;
			$formData1{'password'}=$websitePassword_cmd;
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
	my (undef,$eventID,undef,undef)=split("##",$websiteOtherID_cmd);
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
	my (undef,undef,undef,$hotelID)=split("##",$websiteOtherID_cmd);
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
sub parseRoomAndData
{
	my $this = shift;
	my ($resultFname)=@_;
	my $resultFileBuffer=$this->readFile($resultFname);
	$this->clearFile(\$resultFileBuffer);
	my %finalData;
	for my $refRoom (@dbRoomInfo)
	{
		$refRoom=~s/^\s*,?{//is;
		$refRoom=~s/}\s*$//is;
		if($openRow==0 and $closeRow==1)
		{
			$finalXmlContent .=$this->getRowsClose();
		}
		($openRow,$closeRow)=(1,1);
		if($refRoom ne "")
		{
			my ($dbRoomID,$displayRoom,$roomName,$roomID)=split("##",$refRoom);
			my $startDt=$startDate_cmd;
			my $startDt1=$startDt;
			my $endDt=$endDate_cmd;	
			if ($this->checkNsetRoom($resultFileBuffer,$roomID))
			{
				my $resultFile=$this->readFile($resultFname);
				if ($this->checkDate(\$startDt,\$endDt,$roomName,$resultFile))
				{
					my %finalData;
					while($this->dateCompare($endDt,$startDt)>=0)
					{
						my ($d,$m,$y)=split("\/",$startDt);#15/11/2012
						my $tempstartDt=$y.'-'.$m.'-'.$d;
						$this->getData($resultFname,\%finalData,$tempstartDt);
						$startDt=$this->dateAdd($startDt,1);#$startDt,$endDt
					}	
					$finalXmlContent.=$this->getRowsOpenNtableHeading($roomName);
					$openRow=0;
					$startDt=$startDate_cmd;		
					$endDt=$endDate_cmd;
					my $numDays=$this->dateDiff($endDt,$startDt);				
					my ($netRate,$antiSellRate,$allotment,$roomSold,$allotmentRemains,$stopSell,$avail,$min,$cta,$persentSold,$persentRemains,$dateToShow,$sold,$cutOff,$packageRate);
					for(my $i=0;$i<=$numDays;$i++)
					{
						my($d1,$m1,$y1)=split("\/",$startDt);
						$m1="0".int($m1) if($m1<10);
						$d1="0".int($d1) if($d1<10);
						my $tempstartDt=$startDt; 
						$tempstartDt=$y1.'-'.$m1.'-'.$d1;
						if($dateFormat_cmd=~/^MM\/dd\/yy/is)
						{
							$dateToShow=$m1."/".$d1."/".$y1;
						}
						elsif($dateFormat_cmd=~/^yyyy-mm-dd/is)
						{
							$dateToShow=$y1."-".$m1."-".$d1;
						}
						else
						{
							$dateToShow=int($d1)."/".int($m1)."/".$y1;
						}
						$netRate=$finalData{'net_'.$tempstartDt};
						$allotment=$finalData{'alot_'.$tempstartDt};
						if($allotment ne '')
						{						
							$allotmentRemains=$allotment;
							$roomSold=$allotment-$allotmentRemains;	
							if($allotment ==0)
							{
								$stopSell="Yes";
							}
							else
							{
								$stopSell="No";
							}
						}
						else
						{
							$allotment="N/A";
							$allotmentRemains="N/A";	
							$roomSold="N/A";
							$stopSell="N/A";
						}
						if($netRate eq '')
						{
							$netRate="0.00";
						}
						else
						{
							$netRate=sprintf("%.2f",$netRate);
						}
						$min="N/A";
						$cutOff="N/A";
						$antiSellRate=$this->getSellingRate($website_markup_type,$netRate,$website_markup);
						$this->getPersentSoldnRemain($roomSold,$allotment,$allotmentRemains,\$persentSold,\$persentRemains);
						$this->appendHeader($logpath, $logFile."Data for Property name---$refRoom and for date -- $dateToShow ==>\n");
						$finalXmlContent.=$this->getRowColumn($dbRoomID,$dateToShow,$netRate.' ('.$curreny_cmd.')',$antiSellRate." (".$curreny_cmd.')',$allotment,$roomSold,$allotmentRemains,"",$min,$cta,$stopSell,$cutOff,$persentSold,$persentRemains);
						$startDt=$this->dateAdd($startDt,1);
					}
					$closeRow=0;
					$finalXmlContent.=$this->getRowsClose();					
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
sub getData
{
	my $this=shift;
	my ($resultFname,$finalData,$tempstartDt)=@_;
	my $resultFile=$this->readFile($resultFname);
	$this->clearFile(\$resultFile);
	my $rowID;
	my ($y,$m,$d) = split("-",$tempstartDt);
	$d='0'.int($d) if($d<10);
	$m='0'.int($m) if($m<10);
	my $startDt=$d.'/'.$m.'/'.$y;
	if($resultFile=~/Ajax.InPlaceEditor\W+roomies(\d+)\W+http\W+www.delmayandpartners.com\W+admin\W+events\W+addroombydate.php\W+event\W+\d+&date\W+$tempstartDt\&.*?['"]/is)
	{
		$rowID=$1;
		my $tempresultFile=$`;
		if($tempresultFile=~/<div\s+id\W+roomies$rowID["'].*?>(.*?)<\/div>/is)
		{
			$$finalData{'alot_'.$startDt}=$1;
		}
		$tempresultFile=~/.*Ajax.InPlaceEditor\W+price\d+\W+(.*?type\W+price)['"]/is;
		if($tempresultFile=~/<div\s+id\W+price$rowID["'].*?>(.*?)<\/div>/is)
		{
			$$finalData{'net_'.$startDt}=$1;
		}
	}
	return 1;	
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
	}
	if($this->dateCompare($$endDt,$webEndDt)>0)
	{
		$$endDt=$webEndDt;
	}
	if($this->dateCompare($$startDt,$$endDt)>0)
	{
		$$endDt=$$startDt;
	}
	return 1;
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
sub clearFile	
{
	my $this = shift;
	my ($resultFile)=@_;
	$$resultFile=~s/\&nbsp\;//isg;
	$$resultFile=~s/\&gt\;//isg;
	$$resultFile=~s/\&amp\;/&/isg;
	$$resultFile=~s/\&quot\;/\%22/isg;
	$$resultFile=~s/<!--.*?-->//isg;
}
#=========================================================#
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
#=========================================================#
sub getContent
{
	my $this = shift;
	my ($content)=@_;	
	$$content =~ s/^\&(.*)$/$1/;
	$$content =~ s/\+/\%2B/g;
	$$content =~ s/\s\!/\+\%21/g;
	$$content =~ s/\s/\%20/g;
	$$content =~ s/:/\%3A/g;
	$$content =~ s/\@/\%40/g;
	$$content =~ s/\$/\%24/g;
	$$content =~ s/\//\%2F/g;
	$$content =~ s/\(/\%28/g;
	$$content =~ s/\)/\%29/g;
	$$content =~ s/\</\%3C/g;
	$$content =~ s/\>/\%3E/g;
	$$content =~ s/\"/\%22/g;
	$$content =~ s/\$/\%24/g;
	$$content =~ s/\|/\%7C/g;
	$$content =~ s/\,/\%2C/g;
	$$content =~ s/\[/\%5B/g;
	$$content =~ s/\]/\%5D/g;
	$$content =~ s/\'/\%27/g;
	$$content =~ s/\;/\%3B/g;
}
#=========================================================#

sub parseAvailOptions{
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
			if(!(($tempFile=~/type\W+button/i) or ($tempFile=~/disabled\W+disabled/i) or ($tempFile=~/type\W+image/i) or ($tempFile=~/type\W+submit/i)))
			{
				if($tempFile=~/name\s*=\s*['"]*(.*?)['">\s]/is)
				{
					$nm=$1;
					if(!($tempFile=~/type\W+radio/i))
					{
						if($tempFile=~/\s+value=["](.*?)["]/i)
						{
							$tempFile=$1;
						}
						elsif($tempFile=~/\s+value\s*=\s*["']*(.*?)["'\s>]/i)
						{
							$tempFile=$1;
						}
						elsif($tempFile=~/\s+value.*?["'](.*?["'])/i)
						{
							$tempFile=$1;
							$tempFile=~s/\W\z//i;
						}
						elsif($tempFile=~/\s+value\W*=(.+?[\s|>])/i)

						{
							$tempFile=$1;
							$tempFile=~s/\W\z//i;
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
					elsif($tempFile=~/type\W+checkbox/i and $tempFile=~/checked/i)
					{
						$formData->{$nm}="1";
					}
					elsif($tempFile=~/type\W+checkbox/i)
					{
						$formData->{$nm}="";
					}
				}
			}				
		}
		elsif($1 eq "Select" or $1 eq "select" or $1 eq "SELECT")
		{
			$tempFile=~/(.+?>)/is;
			$tempFile=$1;
			if($tempFile=~/name\s*=\s*['"]*(.*?)["'\s>]/is)
			{
				$nm=$1;
				$resultFile=~/<\/select/is;
				$resultFile=$';
				$tempFile=$`."</select";				
				if($tempFile=~/.*(<option.*selected.*?>)/is) 
				{											
					$tempFile=$1;
					if($tempFile=~/value\s*=\s*['"]*(.*?)['"\s>]/i)
					{
						$tempFile=$1;
					}
					elsif($tempFile=~/value="(.*?")/i)
					{
						$tempFile=$1;
						$tempFile=~s/\W\z//i;

					}
					elsif($tempFile=~/value='(.*?')/i)
					{
						$tempFile=$1;
						my $this=shift;
						my ($formData,$resultFile)=@_;
						my $nm;
						$tempFile=~s/\W\z//i;
					}
					elsif($tempFile=~/value=(.+?[\s|>])/i)
					{
						$tempFile=$1;
						$tempFile=~s/\W\z//i;
					}

					else
					{
						$tempFile="";
					}
				}
				elsif($tempFile=~/(<option.*?>)/is)
				{
					$tempFile=$1;
					if($tempFile=~/\s+value=["](.*?)["]/i)
					{
						$tempFile=$1;
					}
					elsif($tempFile=~/\s+value\s*=\s*['"]*(.*?)['"\s>]/i)
					{
						$tempFile=$1;
					}
					elsif($tempFile=~/\s+value="(.*?")/i)
					{
						$tempFile=$1;
						$tempFile=~s/\W\z//i;
					}
					elsif($tempFile=~/\s+value='(.*?')/i)
					{
						$tempFile=$1;
						$tempFile=~s/\W\z//i;
					}
					elsif($tempFile=~/\s+value=(.+?[\s|>])/i)
					{
						$tempFile=$1;
						$tempFile=~s/\W\z//i;
					}
					else
					{
						$tempFile="";
					}
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
#=========================================================#
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
#==============================================================#
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
#==============================================================#
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
#=========================================================#
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

#=========================================================#
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
	$errorContent .=$this->addError("$flag1","$flagMsg",$script);
	$this->appendHeader($logpath, $logFile."$errorString......\n");
	if($process==0)
	{
		return 0;
	}
	elsif($process==1)
	{
		goto ENDPROCESS;
	}
}
#=========================================================#
