#! usr/bin/perl
use warnings;
use diagnostics;

#<!-- lang: perl -->
my $basedir = '.';
my $d;
my @files = ();
my @dirs = ($basedir);
die "error $basedir: $!" unless(-d $basedir);
open WRITE, ">>outputAtpFileList.txt" or die "Can't open outputFileList.txt";
    
while(@dirs){
   $d = $dirs[0];
   $d .= "/" unless($d=~/\/$/);
	 
   opendir FOLDER, $d || die "Can not open this directory";
   my @filelist = readdir FOLDER; 
   closedir FOLDER;
   my $f;
   #print $d ."\n";#debug
   foreach (@filelist) {
      #print $_."\n"; #debug
      $f = $d.$_;

      #need to remove . and ..
      if($_ eq "." || $_ eq "..")
      {
          #print "ignore"."\n";
          next;
      }
			if($_=~(/\.atp$/i))			{print WRITE $d ."	".$_."\n";}
      push(@dirs, $f) if(-d $f) ;
      push(@files,$f)if(-f $f);
    }
    #print WRITE $d ."\n" if $folder_flag==1;
   shift @dirs;
}
close WRITE;