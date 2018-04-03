use feature qw(say);

$outputfolder = "outputOpcode";
if ( !-e $outputfolder ) 
{
	mkdir $outputfolder, 0755 or warn "Folder create failed.";
}
$filepath = "J750input\\";
opendir FOLDER, $filepath or die "cannot find $filepath";
my @filelist = readdir(FOLDER);
@opcodelist = "";
if ( -e $outputfolder . "\\opcode.txt" ) 
{
	unlink $outputfolder . "\\opcode.txt";
}
if ( -e $outputfolder . "\\opcode in pattern.txt" ) 
{
	unlink $outputfolder . "\\opcode in pattern.txt";
}
foreach $file (@filelist) 
{
	if ( $file =~ /.atp$/i ) 
	{
		$filename = $filepath . $file;
		&findopcode( $filename, "$outputfolder\\", "opcode.txt" ,"opcode in pattern.txt");
	}
}

sub findopcode {
	open READ,  "<",  $_[0];
	open WRITE, ">>", $_[1] . $_[2];
	open WRITESOURCE,">>",$_[1].$_[3];
	my $linenumber=0;
	my $str_line;
	my $flag        = 1;
	my $outofcolumn = 1;
	my $result="";
	my $tempt="";
	say "$_[0]   Please wait";
	print WRITESOURCE "--------------$_[0]--------------\n";
	while ( defined( $str_line = <READ> ) ) 
	{
		$linenumber++;
		$str_line =~ s/^\s+|\s+$//;

		if ($outofcolumn) 
		{
			if ( $str_line =~ /^{/ ) 
			{
				$outofcolumn = 0;
				next;
			}
			else 
			{
				next;
			}
		}

		if ( !$outofcolumn ) 
		{
			if ( $str_line =~ /^}/ ) 
			{
				$outofcolumn = 1;
				next;
			}
		}

		if ( !($str_line =~ /^\/\// )) 
		{
			if ( $str_line =~ /^(?<label>.*:)?(?<opcode>.*)>.*;/ ) 
			{
				if ( $+{opcode} ) 
				{
					$result = $+{opcode};
				}
			}
			elsif (  $str_line =~ /^(?<label>\w+\s?:)?(?<opcode>.*)>.*;(?<comment>\/\/.*)?/) 
			{
				if ( $+{opcode} ) 
				{
					$result = $+{opcode};
				}
			}
			
			$result =~ s/^\s+//;
			$result =~ s/\s+$//;

			$tempt = $result;
			$tempt =~ s/\d+/ /;
			$tempt =~ s/^\s+//;
			$tempt =~ s/\s+$//;
			$tempt=~s/^.*://;

			if ( $tempt =~ /jump/ ) 
			{
				$tempt =~ s/\s+\w+$//;
			}
			elsif ( $tempt =~ /end_loop/ ) 
			{
				$tempt =~ s/\s+\w+$//;
				$tempt =~ s/\w$//;
			}
			elsif ( $tempt =~ /call/ ) 
			{
				$tempt =~ s/\s+\w+$//;
			}
			elsif ( $tempt =~ /^loop/ ) 
			{
				$tempt =~ s/\w$//;
			}

			#    			创建记录已有的opcode的列表
			foreach my $compare (@opcodelist) 
			{
				if ( $compare eq $tempt ) 
				{
					$flag = 0;
				}
			}	

			#    			输出不重复的opcode的行
			if ($flag) 
			{
				push( @opcodelist, $tempt );
				print WRITESOURCE "$linenumber:  ";
				print WRITESOURCE "$str_line\n";
				print WRITE "$tempt\n";
			}
			$flag = 1;
		}
	}
	close READ;
	close WRITE;
	close WRITESOURCE;
}
