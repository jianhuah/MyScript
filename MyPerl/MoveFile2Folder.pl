#! usr/bin/perl
use warnings;
use diagnostics;
use File::Copy;

#<!-- lang: perl -->
my $basedir = '.';
my $d;
my @files = ();
my @dirs = ($basedir);
my $folder_flag;
my $fileIn;
my $fileOut="input";
if ( !-e $fileOut ) 
{
	mkdir $fileOut, 0755 or warn "Folder create failed.";
}

die "error $basedir: $!" unless(-d $basedir);
open WRITE, ">>J750atpFileList.txt" or die "Can't open outputFileList.txt";
    
while(@dirs){
   $d = $dirs[0];
   $d .= "/" unless($d=~/\/$/);
	 
   opendir FOLDER, $d || die "Can not open this directory";
   my @filelist = readdir FOLDER; 
   closedir FOLDER;
   my $f;
   print $d ."\n";#debug
   $folder_flag=0;
   foreach (@filelist) {
      print $_."\n"; #debug
      $f = $d.$_;

      #need to remove . and ..
      if($_ eq "." || $_ eq "..")
      {
          #print "ignore"."\n";
          next;
      }
      $folder_flag=1 if($_=~(/\.atp$/i));
			if($_=~(/\.atp$/i)){
				print WRITE $d ."	".$_."\n";
				$fileIn=$d . $_;
				move($fileIn,$fileOut) or warn "Can't move the file: $fileIn\n"; #move the fileIn to fileOut folder
				}
      push(@dirs, $f) if(-d $f) ;
      push(@files,$f)if(-f $f);
    }
    #print WRITE $d ."\n" if $folder_flag==1;
   shift @dirs;
}
close WRITE;