#!usr/bin/perl
use warnings;
use diagnostics;
#use strict;

#method and procedure:
#			1)make sure the .pl and the pattern folder(input) are in the same path;
#			2)open the input directory, and copy all the .atp files in input to a new folder output;
#			3)itera all the .atp file in output folder, and invoke the pattern compiler to convert .atp to .pat;
#			4)after the .atp convert to .pat successfully, delet the related .atp file, if not also delete the .atp, and write the fail message into _FailedPatternList.txt 
#		
mkdir "pat_output",0755 or die "Cannot creat the pat_output folder: $!";#creat a folder pat_output to save the converted .pat
chdir ".\input" or die "The folder input not exist here, please check the input folder! $!";

my @all_inputs=<*>; #globbing all the files from input folder
foreach my $subdir(@all_inputs){
	if(-d $subdir); #check subdir, if it's subdir then open the directory handler
	open DIR, $subdir;
	else{
		
		}
	}




sub UltraFlexPatternCompiler()
{
my $input_file=$_[0];#"UltraFlex_SRM_VM_Dummy.atp ";
#$output="-output ";
my $pinmap="-pinmap_workbook ";
my $digital_inst="-digital_inst ";
my $opcode_mode="-opcode_mode ";

$pinmap=$pinmap . "Pinmap.txt "; #specified the pinmap file
$digital_inst=$digital_inst . "HSDMQ "; #specified the digital instrument
$opcode_mode=$opcode_mode ."single "; #specififed the timing mode

my $switches=$pinmap.$digital_inst.$opcode_mode;#
my $my_command="apc ".$input_file .$switches;

#system("apc -stdin -output bar.pat");
system($my_command);#invoke the pattern compiler by command-line interface: apc input-ascii-file(s) [switches]
	}


my $input_file="UltraFlex_SRM_VM_Dummy.atp ";
#$output="-output ";
my $pinmap="-pinmap_workbook ";
my $digital_inst="-digital_inst ";
my $opcode_mode="-opcode_mode ";

$pinmap=$pinmap . "PinMap.txt "; #specified the pinmap file
$digital_inst=$digital_inst . "HSDMQ "; #specified the digital instrument
$opcode_mode=$opcode_mode ."single "; #specififed the timing mode

my $switches=$pinmap.$digital_inst.$opcode_mode;#
my $my_command="apc ".$input_file .$switches;

#system("apc -stdin -output bar.pat");
system($my_command);#invoke the pattern compiler by command-line interface: apc input-ascii-file(s) [switches]

$input_file="UltraFlex_SRM_VM_Dummy2.atp ";
$my_command="apc ".$input_file .$switches;
print $my_command ."\n";
print "Lanch pattern compiler...\n";
#system("apc -stdin -output bar.pat");
system($my_command);#invoke the pattern compiler by command-line interface: apc input-ascii-file(s) [switches]