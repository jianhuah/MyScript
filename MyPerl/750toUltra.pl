use feature qw(say);

$outputfolder = "UltraFlex";
if ( !-e $outputfolder ) 
{
	mkdir $outputfolder, 0755 or warn "Folder create failed.";
}
$filepath = "input\\";
opendir FOLDER, $filepath or die "cannot find $filepath";
my @filelist = readdir(FOLDER);
foreach $file (@filelist) 
{
	if ( $file =~ /.atp/ ) 
	{
		$filename = $filepath . $file;
		&findopcode( $filename, "$outputfolder\\",$file );   #,"opcode in pattern.txt");
	}
}

sub findopcode 
{
	open READ,  "<",  $_[0];
	open WRITE, ">", $_[1] . $_[2];
	open WRITETEMPT,">","tempt.txt";
	open WRITECOMMENT,">","comment.txt";
	my $patternnumber=0;
	my $str_line;
	my $outofcolumn = 1;
	my $result="";
	my $originStr="";
	my $origindata="";
	my $before="";
	my $beforetwo="";
	my $pinlist="";
	my $srm=0;
	my $linenumber=0;
	
	my $subfilename=$_[2];
	$subfilename=~s/.atp//;
	say "$_[0]   Please wait";

    while ( defined( $originStr = <READ> ) ) 
	{
		chomp($originStr);
		my $label="";
		$originStr =~ s/^\s+|\s+$//;
		$str_line=$originStr;
		
		if ($outofcolumn) 
		{
			if ( $str_line =~ /^{/ ) 
			{
				$outofcolumn = 0;
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
		
		if($outofcolumn)
		{
			if(($str_line =~ /^\/\// )||($str_line =~ /^\/\*/ ))
			{
				if($str_line =~ /^\/\*/&&!($str_line=~/\*\/$/))
				{
					print WRITECOMMENT "$originStr\n";
					while(1)
					{
						$originStr = <READ>;
						chomp($originStr);
						$originStr =~ s/^\s+|\s+$//;
						$str_line=$originStr;
						
						if($str_line=~/\*\/$/)
						{
							print WRITECOMMENT "$originStr\n";
							last;
						}
						else
						{
							print WRITECOMMENT "$originStr\n";
			    			next;
						}
					}
					next;
				}
				else
				{
					print WRITECOMMENT "$originStr\n";
			    	next;
				}
			}
		}
		
		if ( !($str_line =~ /^\/\// )||($str_line =~ /^\/\*/ )) 
		{
			if($str_line=~/>.*;/)
			{
				$linenumber++;
			}
			
			if ( $str_line =~ /^(?<label>.*:)?(?<opcode>.*)>.*;/ ) 
			{
				if ( $+{opcode} ) 
				{
					$result = $+{opcode};
				}
				
				if($+{label})
				{
					$label=$+{label};
				}
			}
			elsif (  $str_line =~ /^(?<label>.*:)?(?<opcode>.*)(?<comment>\/\/.*)?/) 
			{
				if ( $+{opcode} ) 
				{
					$result = $+{opcode};
				}
				
				if($+{label})
				{
					$label=$+{label};
				}
			}

			if ( $result =~ /return/ )                     
			{
				$srm=1;
			}
			elsif($result =~ /push/ )
			{
				$srm=1;
			}
			
			if($label=~/subr/)
			{
				$srm=1;
			}
			elsif($label=~/global\s+subr/)
			{
				$srm=1;
			}
			elsif($label=~/stop\s+subr/)
			{
				$srm=1;
			}
			elsif($label=~/keepalive\s+subr/)
			{
				$srm=1;
			}
		}
	}
	if($linenumber<64)
	{
		$srm=1;
	}
	seek(READ,0,0);
	$result="";
	$outofcolumn=1;
	close WRITECOMMENT;

	while ( defined( $originStr = <READ> ) ) 
	{
		chomp($originStr);
		$origindata=$originStr;
        
		$originStr =~ s/^\s+|\s+$//;
		$str_line=$originStr;

		if ($outofcolumn) 
		{
			if ( $str_line =~ /^{/ ) 
			{
				$outofcolumn = 0;
				next;
			}
			else 
			{
				if(($str_line =~ /^\/\// )||($str_line =~ /^\/\*/ ))
				{
					if($str_line =~ /^\/\*/&&!($str_line=~/\*\/$/))
					{
						while(1)
						{
							$originStr = <READ>;
							chomp($originStr);
							$originStr =~ s/^\s+|\s+$//;
							$str_line=$originStr;
								
							if($str_line=~/\*\/$/)
							{
								last;
							}
							else
							{
				    			next;
							}
						}
			    		next;
					}

					next;
					
				}
				else
				{
					if($str_line=~/vector\s*\(\s*\$tset\s*,/)
					{
						$str_line=~/vector\s*\(\s*\$tset\s*,(?<pinlist>.*)\)/;
						$pinlist=$+{pinlist};
						if($srm==0)
						{
							print WRITE "vm_vector $subfilename (\$tset,$pinlist)\n";
						}
						else
						{
							print WRITE "srm_vector $subfilename (\$tset,$pinlist)\n";
						}
						
						print WRITE "\{\n";
						open READCOMMENT,"<","comment.txt";
						while(defined( $originStr = <READCOMMENT> ))
						{
							chomp($originStr);
							print WRITE "$originStr\n";
						}
						close READCOMMENT;
						next;
					}
					else
					{
						print WRITE "$originStr\n";
						next;
					}
				}
			}
		}

		if ( !$outofcolumn ) 
		{
			if ( $str_line =~ /^}/ ) 
			{
				$outofcolumn = 1;
				print WRITE "$originStr\n";
				next;
			}
		}

		if ( !($str_line =~ /^\/\// )||($str_line =~ /^\/\*/ )) 
		{
			if($str_line=~/^start_label\s*/)
			{
				$origindata =~ s/^\s*start_label\s*//;
			}
			
			if ( $str_line =~ /^(?<label>.*:)?(?<opcode>.*)>.*;/ ) 
			{
				if ( $+{opcode} ) 
				{
					$result = $+{opcode};
				}
			}
			elsif (  $str_line =~ /^(?<label>.*:)?(?<opcode>.*)(?<comment>\/\/.*)?/) 
			{
				if ( $+{opcode} ) 
				{
					$result = $+{opcode};
				}
			}
			
			if ( $result =~ /mrepeat/ )                     #ok
			{
				$origindata =~ s/mrepeat/repeat/;
			}
			elsif($result=~/end_module/)                    #ok
			{
				$origindata =~ s/end_module/halt/;
			}
			elsif($result=~/ign/)                           #ok
			{
				$origindata =~ s/\bign\b/mask/;
			}
			elsif($result=~/set_code/)                      #ok
			{
				$origindata=~/(?<set>set_code\s+\d+)/;
				my $setcode1=$+{set};
				$origindata =~ s/set_code\s+\d+//;
				$origindata=$origindata."\/\/ $setcode1";
			}
			elsif(($result=~/enable/)&&($result=~/none/))   #ok
			{
				$origindata =~ s/enable/branch_expr=/;
			}
			elsif($result=~/enable/)                        #ok
			{
				$origindata =~ s/enable/branch_expr=/;
				$origindata=~s/cpuA/cpuA_cond/i;
				$origindata=~s/cpuB/cpuB_cond/i;
				$origindata=~s/cpuC/cpuC_cond/i;
				$origindata=~s/cpuD/cpuD_cond/i;
			}
			elsif($result=~/if\s*\(flag\)\s*jump/)          #ok
			{
				$origindata =~ s/\bflag\b/branch_expr/;
			}
			elsif($result=~/clr_flag\s*\(cpuA\)/)           #ok
			{
				$origindata =~ s/clr_flag/clr_cond_flags/;
				$origindata=~s/cpuA/cpuA_cond/;
			}
			elsif($result=~/clr_flag\s*\(fail\)/)           #ok
			{
				$origindata =~ s/clr_flag/clr_cond_flags/;
			}
			elsif ( $result =~ /set_cpu\s*\(cpuA\)/ )       #ok
			{
				$origindata =~ s/set_cpu/set_cpu_cond/;
				$origindata =~ s/cpuA/cpuA_cond/;
			}
			elsif ( $result =~ /exit_loop/ )                #ok        
			{
				$origindata =~ s/exit_loop/clr_loop/;
			}
			elsif ( $result =~ /push/ )                     #ok
			{
				$origindata =~ s/\bpush\b/push_subr/;
			}
			elsif($result =~ /call_glo/ )                   #ok
			{
				$origindata =~ s/call_glo/call globalAddr/;
			}
			elsif($result =~ /if\s*\(.?cpuA_cond\)\s*jump/) #ok
			{
				if($srm)
				{
					if($originStr=~/^\w+\s?:/)    #label and if () jump is on the same line
					{
						$originStr =~ s/^\s+|\s+$//;
						$originStr=~/if\s*\((?<cpu>.*)\)/;
						my $cpu=$+{cpu};
						$originStr=~/(?<data>>.*)/;
						if($+{data})     #label and if () jump is on the same line ;and vector data is also on the same line
						{
							my $data=$+{data};
							print WRITE "branch_expr=($cpu) $data\n"; 
							$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
							print WRITE "$originStr\n";
							$result="";
							next;
						}
						else    #label and if () jump is on the same line ;but vector data is  on the next line
						{
							my $temptoriginStr = <READ>;
							chomp($temptoriginStr);
							$temptoriginStr =~ s/^\s+|\s+$//;
							$temptoriginStr=~/(?<data>>.*)/;
							my $data=$+{data};
							print WRITE "branch_expr=($cpu) $data\n"; 
							$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
							print WRITE "$originStr\n$temptoriginStr\n";
							$result="";
							next;
						}
					}
					else   #label and if () jump is on the different line
					{
						$originStr=~/if\s*\((?<cpu>.*)\)/;
						my $cpu=$+{cpu};
						if($originStr=~/>.*;/)   #label and if () jump is on the different line;and vector data is on the same line of if() jump
						{
							$originStr=~/(?<data>>.*;)/;
							my $data=$+{data};
							$position1=length($before.$origindata)+4;
							$position2=length($before)+2;
							seek(READ,-$position1,1);
							seek(WRITE,-$position2,1);
							$originStr = <READ>;
							chomp($originStr);
							$originStr =~ s/^\s+|\s+$//;
							$originStr=~/^(?<label>.*:)/;
							
							if($+{label})        #label is above the line of if () jump
							{
								my $label=$+{label};
								$originStr=~/(?<data>>.*;)/;
								if($+{data})     #label is above the line of if () jump and it has vector data
								{
									$originStr=~s/^.*:/$label branch_expr=($cpu) /;
									print WRITE "$originStr\n";
									$originStr = <READ>;
									chomp($originStr);
									$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
									print WRITE "$originStr\n";
									$result="";
									next;
								}
								else            #label is above the line of if () jump but it has no vector data
								{
									$originStr=~s/^.*:/branch_expr=($cpu) $data/;
									print WRITE "$originStr\n";
									$originStr = <READ>;
									chomp($originStr);
									$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
									print WRITE "$label $originStr\n";
									$result="";
									next;
								}
								
							}
							else       #label is above two line of if () jump, so the line above if () jump must be vector data
							{
								print WRITE " branch_expr=($cpu) $originStr\n";
								$originStr = <READ>;
								chomp($originStr);
								$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
								print WRITE "$originStr\n";
								$result="";
								next;
							}
							
						}
						else    #label and if () jump is on the different line; but vector data is on the next line of if() jump
						{
							$datastring=<READ>;
							chomp($datastring);
							$position1=length($before.$origindata.$datastring)+6;
							$position2=length($before)+2;
							seek(READ,-$position1,1);
							seek(WRITE,-$position2,1);
							$originStr = <READ>;
							chomp($originStr);
							$originStr =~ s/^\s+|\s+$//;
							$originStr=~/^(?<label>.*:)/;
							
							if($+{label})     #the line above if () jump has label
							{
								my $label=$+{label};
								$originStr=~/(?<data>>.*;)/;
								if($+{data})     #the line above if () jump has label and it has vector data
								{
									$originStr=~s/^.*:/$label branch_expr=($cpu) /;
									print WRITE "$originStr\n";
									$originStr = <READ>;
									chomp($originStr);
									$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
									print WRITE "$originStr\n";
									$result="";
									next;
								}
								else          #the line above if () jump has label but it has no vector data
								{
									$originStr=~s/^.*:/branch_expr=($cpu) $datastring/;
									print WRITE "$originStr\n";
									$originStr = <READ>;
									chomp($originStr);
									$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
									print WRITE "$label $originStr\n";
									$result="";
									next;
								}
							}
							else            #the line above if () jump has no label, so it must be vector data
							{
								print WRITE " branch_expr=($cpu) $originStr\n";
								$originStr = <READ>;
								chomp($originStr);
								$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
								print WRITE "$originStr\n";
								$result="";
								next;
							}
							
						}
					}
				}
				else                      # vm
				{
					if($originStr=~/^\w+\s?:/)    #label and if () jump is on the same line
					{
						$originStr =~ s/^\s+|\s+$//;
						$originStr=~/if\s*\((?<cpu>.*)\)/;
						my $cpu=$+{cpu};
						$originStr=~/^(?<label>\w+\s*):/;
						my $label=$+{label};
						$originStr=~/(?<data>>.*)/;
						if($+{data})     #label and if () jump is on the same line ;and vector data is also on the same line
						{	
							my $data=$+{data};
							print WRITE "call srm_$label"."_$subfilename $data\n";
							print WRITETEMPT "srm_vector $subfilename"."_srm_$label (\$tset, $pinlist)\n";
							print WRITETEMPT "{\n";
							print WRITETEMPT "global subr srm_$label"."_$subfilename:  $data\n";
							print WRITETEMPT "branch_expr=($cpu) $data\n";
							$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
							print WRITETEMPT "$originStr\n";
							print WRITETEMPT "return $data\n";
							print WRITETEMPT "}\n";
							$result="";
							next;					
						}
						else    #label and if () jump is on the same line ;but vector data is  on the next line
						{
							my $temptoriginStr = <READ>;
							chomp($temptoriginStr);
							$temptoriginStr =~ s/^\s+|\s+$//;
							$temptoriginStr=~/(?<data>>.*)/;
							my $data=$+{data};
							print WRITE "call srm_$label"."_$subfilename $data\n";
							print WRITETEMPT "srm_vector $subfilename"."_srm_$label (\$tset, $pinlist)\n";
							print WRITETEMPT "{\n";
							print WRITETEMPT "global subr srm_$label"."_$subfilename:  $data\n";
							print WRITETEMPT "branch_expr=($cpu) $data\n";
							$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
							print WRITETEMPT "$originStr\n";
							print WRITETEMPT "return $data\n";
							print WRITETEMPT "}\n";
							$result="";
							next;		
						}
					}
					else   #label and if () jump is on the different line
					{
						$originStr=~/if\s*\((?<cpu>.*)\)/;
						my $cpu=$+{cpu};
						if($originStr=~/>.*;/)   #label and if () jump is on the different line;and vector data is on the same line of if() jump
						{
							$originStr=~/(?<data>>.*)/;
							my $data=$+{data};
							$position1=length($before.$origindata)+4;
							$position2=length($before)+2;
							seek(READ,-$position1,1);
							seek(WRITE,-$position2,1);
							$originStr = <READ>;
							chomp($originStr);
							$originStr =~ s/^\s+|\s+$//;
							$originStr=~/^(?<label>.*):/;
							
							if($+{label})        #label is above the line of if () jump
							{
								my $label=$+{label};
								$originStr=~/(?<data>>.*;)/;
								if($+{data})     #label is above the line of if () jump and it has vector data
								{
									my $labeldata=$+{data};
									print WRITE "call srm_$label"."_$subfilename $labeldata\n";
									print WRITETEMPT "srm_vector $subfilename"."_srm_$label (\$tset, $pinlist)\n";
									print WRITETEMPT "{\n";
									print WRITETEMPT "global subr srm_$label"."_$subfilename:  $data\n";
									print WRITETEMPT "$label:  branch_expr=($cpu) $labeldata\n";
									$originStr = <READ>;
									chomp($originStr);
									$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
									print WRITETEMPT "$originStr\n";
									print WRITETEMPT "return $data\n";
									print WRITETEMPT "}\n";
									$result="";
									next;		
								}
								else            #label is above the line of if () jump but it has no vector data
								{
									print WRITE "call srm_$label"."_$subfilename $data\n";
									print WRITETEMPT "srm_vector $subfilename"."_srm_$label (\$tset, $pinlist)\n";
									print WRITETEMPT "{\n";
									print WRITETEMPT "global subr srm_$label"."_$subfilename:  $data\n";
									print WRITETEMPT "branch_expr=($cpu) $data\n";
									$originStr = <READ>;
									chomp($originStr);
									$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
									print WRITETEMPT "$label: $originStr\n";
									print WRITETEMPT "return $data\n";
									print WRITETEMPT "}\n";
									$result="";
									next;		
									
								}
								
							}
							else       #label is above two line of if () jump, so the line above if () jump must be vector data
							{
								my $position3=length($before.$beforetwo)+4;
								my $position4=length($beforetwo)+2;
								seek(READ,-$position3,1);
								seek(WRITE,-$position4,1);
								$originStr = <READ>;     #get label
								chomp($originStr);
								$originStr =~ s/^\s+|\s+$//;
								$originStr=~/^(?<label>.*):/;
								my $label=$+{label};
								$originStr = <READ>;     #get vector data
								chomp($originStr);
								$originStr =~ s/^\s+|\s+$//;
								$originStr=~/(?<labeldata>>.*)/;
								my $labeldata=$+{labeldata};
								print WRITE "call srm_$label"."_$subfilename $labeldata\n\/\/Origin data here has been overwrited.                                                                  \n";
								print WRITETEMPT "srm_vector $subfilename"."_srm_$label (\$tset, $pinlist)\n";
								print WRITETEMPT "{\n";
								print WRITETEMPT "global subr srm_$label"."_$subfilename:  $data\n";
								print WRITETEMPT "$label: branch_expr=($cpu) $data\n";
								$originStr = <READ>;
								chomp($originStr);
								$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
								print WRITETEMPT "$originStr\n";
								print WRITETEMPT "return $data\n";
								print WRITETEMPT "}\n";
								$result="";
								next;		
							}
							
						}
						else    #label and if () jump is on the different line; but vector data is on the next line of if() jump
						{
							my $datastring=<READ>;
							chomp($datastring);
							my $position1=length($before.$origindata.$datastring)+6;
							my $position2=length($before)+2;
							seek(READ,-$position1,1);
							seek(WRITE,-$position2,1);
							$originStr = <READ>;
							chomp($originStr);
							$originStr =~ s/^\s+|\s+$//;
							$originStr=~/^(?<label>.*):/;
							
							if($+{label})     #the line above if () jump has label
							{
								my $label=$+{label};
								$originStr=~/(?<data>>.*;)/;
								if($+{data})     #the line above if () jump has label and it has vector data
								{
									my $labeldata=$+{data};
									print WRITE "call srm_$label"."_$subfilename $labeldata\n";
									print WRITETEMPT "srm_vector $subfilename"."_srm_$label (\$tset, $pinlist)\n";
									print WRITETEMPT "{\n";
									print WRITETEMPT "global subr srm_$label"."_$subfilename:  $labeldata\n";
									print WRITETEMPT "$label:  branch_expr=($cpu) $labeldata\n";
									$originStr = <READ>;
									chomp($originStr);
									$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
									print WRITETEMPT "$originStr\n";
									$originStr = <READ>;
									chomp($originStr);
									print WRITETEMPT "$originStr\n";
									print WRITETEMPT "return $labeldata\n";
									print WRITETEMPT "}\n";
									$result="";
									next;		
								}
								else          #the line above if () jump has label but it has no vector data
								{
									print WRITE "call srm_$label"."_$subfilename $datastring\n";
									print WRITETEMPT "srm_vector $subfilename"."_srm_$label (\$tset, $pinlist)\n";
									print WRITETEMPT "{\n";
									print WRITETEMPT "global subr srm_$label"."_$subfilename:  $datastring\n";
									print WRITETEMPT " branch_expr=($cpu) $datastring\n";
									$originStr = <READ>;
									chomp($originStr);
									$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
									print WRITETEMPT "$label: $originStr\n";
									$originStr = <READ>;
									chomp($originStr);
									print WRITETEMPT "$originStr\n";
									print WRITETEMPT "return $datastring\n";
									print WRITETEMPT "}\n";
									$result="";
									next;		
									
								}
							}
							else            #the line above if () jump has no label, so it must be vector data
							{
								
								my $position3=length($before.$beforetwo)+4;
								my $position4=length($beforetwo)+2;
								seek(READ,-$position3,1);
								seek(WRITE,-$position4,1);
								$originStr = <READ>;     #get label
								chomp($originStr);
								$originStr =~ s/^\s+|\s+$//;
								$originStr=~/^(?<label>.*):/;
								my $label=$+{label};
								$originStr = <READ>;     #get vector data
								chomp($originStr);
								$originStr =~ s/^\s+|\s+$//;
								$originStr=~/(?<labeldata>>.*)/;
								my $labeldata=$+{labeldata};
								print WRITE "call srm_$label"."_$subfilename $labeldata\n\/\/Origin data here has been overwrited.                                                                  \n";
								print WRITETEMPT "srm_vector $subfilename"."_srm_$label (\$tset, $pinlist)\n";
								print WRITETEMPT "{\n";
								print WRITETEMPT "global subr srm_$label"."_$subfilename:  $labeldata\n";
								print WRITETEMPT "$label: branch_expr=($cpu) $labeldata\n";
								$originStr = <READ>;
								chomp($originStr);
								$originStr=~s/\(.?cpuA_cond\)/(branch_expr)/;
								print WRITETEMPT "$originStr\n";
								$originStr = <READ>;
								chomp($originStr);
								print WRITETEMPT "$originStr\n";
								print WRITETEMPT "return $labeldata\n";
								print WRITETEMPT "}\n";
								$result="";
								next;		

							}
							
						}
					}
				}
				
			}
			elsif($result =~ /set_loopA/)                            #ok
			{
				my @loopcontent;
				my $lastone;
				my $loopcount=1;
				
				$patternnumber++;
				$originStr=~/set_loop\w\s+(?<opcodetime>\d+)/;
				my $opcodetime=$+{opcodetime}-3;
				if(!($originStr=~/>.*;/))
				{
					while(1)
					{
						my $temptstr=<READ>;
						chomp($temptstr);
						
						if($temptstr=~/>.*;/)
						{
							$originStr=$originStr.$temptstr;
							last;
						}
						else
						{
							$originStr=$originStr.$temptstr;
						}
					}
				}
				$before=$originStr;
				my $nil=$patternnumber."_$subfilename";
				$before=~s/set_loop\w\s+\d+/call label$nil/;
				print WRITE "$before\n";
				while(1)
				{
					$originStr = <READ>;
					chomp($originStr);
					$originStr =~ s/^\s+|\s+$//;
					$originStr=~/^(?<label>\w+\s*:)/;
					if($+{label})
					{
						$label=$+{label};
						if(!($originStr=~/>.*;/))
						{
							while(1)
							{
								my $temptstr=<READ>;
								chomp($temptstr);
								
								if($temptstr=~/>.*;/)
								{
									$originStr=$originStr.$temptstr;
									last;
								}
								else
								{
									$originStr=$originStr.$temptstr;
								}
							}
						}
						$originStr=~s/^.*://;
						push(@loopcontent,$originStr);
						last;
					}
					else
					{
						print WRITE "$originStr\n";
					}
				}
				
				
				#first time of loop
				print WRITETEMPT "srm_vector $subfilename$patternnumber (\$tset, $pinlist)\n";
				print WRITETEMPT "{\n";
				
				if($originStr=~/^\s*\w+\s*>/)
				{
					print WRITETEMPT "global subr label$patternnumber"."_$subfilename: set_msb $opcodetime ,";
				}
				else
				{
					print WRITETEMPT "global subr label$patternnumber"."_$subfilename: set_msb $opcodetime ";
				}
				
				while(1)
				{
					$originStr = <READ>;
					chomp($originStr);		
					$loopcount++;			
					
					if($originStr=~/end_loop/)
					{
						$originStr=~s/end_loop\w/end_loop/;
						if($originStr=~/>.*;/)
						{
							$lastone=$originStr;
							$originStr=~s/^.*>/ >/;
							$lastonewithout=$originStr;
							last;
						}
						else
						{
							my $temptstr=<READ>;
							chomp($temptstr);
							$originStr=$originStr.$temptstr;
							$lastone=$originStr;
							$originStr=~s/^.*>/ >/;
							$lastonewithout=$originStr;
							last;
						}
					}
					else
					{
						if(!($originStr=~/>.*;/))
						{
							my $temptstr = <READ>;
							chomp($temptstr);
							$originStr=$originStr.$temptstr;
						}
						push(@loopcontent,$originStr);
					}
				}
				
				if($#loopcontent==0)
				{
					
					print WRITETEMPT " $loopcontent[0]\n";
				    print WRITETEMPT "set c0 $opcodetime $lastonewithout\n";
				    
				}
				elsif($#loopcontent==1)
				{
					print WRITETEMPT " $loopcontent[0]\n";
				    if($loopcontent[1]=~/^\s*\w+\s*>/)
					{
						print WRITETEMPT "set c0 $opcodetime, $loopcontent[1]\n";
					}
					else
					{
						print WRITETEMPT "set c0 $opcodetime $loopcontent[1]\n";
					}
				    print WRITETEMPT " $lastonewithout\n";
				    
				}
				else
				{
					for($i=0;$i<($#loopcontent+1);$i++)
				    {
						if($i==0)
						{
							print WRITETEMPT " $loopcontent[0]\n";
						}
						elsif($i==1)
						{
							if($loopcontent[1]=~/^\s*\w+\s*>/)
							{
								print WRITETEMPT "set c0 $opcodetime, $loopcontent[1]\n";
							}
							else
							{
								print WRITETEMPT "set c0 $opcodetime $loopcontent[1]\n";
							}
						}
						else
						{
							print WRITETEMPT " $loopcontent[$i]\n";
						}
				    }
				    print WRITETEMPT " $lastonewithout\n";
				    
				}
				
				#true loop content
				print WRITETEMPT " $label  ";

				for($i=0;$i<($#loopcontent+1);$i++)
				{
					if($i==0)
					{
						if($loopcontent[0]=~/^\s*\w+\s*>/)
						{
							print WRITETEMPT "loop c0, $loopcontent[0]\n";
						}
						else
						{
							print WRITETEMPT " $loopcontent[0]\n";
						}
					}
					else
					{
						print WRITETEMPT " $loopcontent[$i]\n";
					}
				}
				
				print WRITETEMPT "$lastone\n";
				
				#third time of loop
				
				foreach my $loop (@loopcontent)
				{
					print WRITETEMPT " $loop\n";
				}
				
				my $thirdoflast=$lastone;
				$thirdoflast=~s/^.*>/ return >/;
				print WRITETEMPT " $thirdoflast\n";
				
				print WRITETEMPT "}\n";
				$result="";
				next;
			}
			elsif($result =~ /\bloop\w\s+\d+/)            #ok
			{
				my @loopcontent;
				my $lastone;
				my $loopcount=1;
				
				$patternnumber++;
				$originStr=~/\bloop\w\s+(?<opcodetime>\d+)/;
				my $opcodetime=$+{opcodetime}-3;
				if(!($originStr=~/>.*;/))
				{
					while(1)
					{
						my $temptstr=<READ>;
						chomp($temptstr);
						
						if($temptstr=~/>.*;/)
						{
							$originStr=$originStr.$temptstr;
							last;
						}
						else
						{
							$originStr=$originStr.$temptstr;
						}
					}
				}
				$before=$originStr;
				my $nil=$patternnumber."_$subfilename";
				$before=~s/\bloop\w\s+\d+/call label$nil/;
				print WRITE "$before\n";
				while(1)
				{
					$originStr = <READ>;
					chomp($originStr);
					$originStr =~ s/^\s+|\s+$//;
					$originStr=~/^(?<label>\w+\s*:)/;
					if($+{label})
					{
						$label=$+{label};
						if(!($originStr=~/>.*;/))
						{
							while(1)
							{
								my $temptstr=<READ>;
								chomp($temptstr);
								
								if($temptstr=~/>.*;/)
								{
									$originStr=$originStr.$temptstr;
									last;
								}
								else
								{
									$originStr=$originStr.$temptstr;
								}
							}
						}
						$originStr=~s/^.*://;
						push(@loopcontent,$originStr);
						last;
					}
					else
					{
						print WRITE "$originStr\n";
					}
				}
				
				
				#first time of loop
				print WRITETEMPT "srm_vector $subfilename$patternnumber (\$tset, $pinlist)\n";
				print WRITETEMPT "{\n";
				
				if($originStr=~/^\s*\w+\s*>/)
				{
					print WRITETEMPT "global subr label$patternnumber"."_$subfilename: set_msb $opcodetime ,";
				}
				else
				{
					print WRITETEMPT "global subr label$patternnumber"."_$subfilename: set_msb $opcodetime ";
				}
				
				while(1)
				{
					$originStr = <READ>;
					chomp($originStr);		
					$loopcount++;			
					
					if($originStr=~/end_loop/)
					{
						$originStr=~s/end_loop\w/end_loop/;
						if($originStr=~/>.*;/)
						{
							$lastone=$originStr;
							$originStr=~s/^.*>/ >/;
							$lastonewithout=$originStr;
							last;
						}
						else
						{
							my $temptstr=<READ>;
							chomp($temptstr);
							$originStr=$originStr.$temptstr;
							$lastone=$originStr;
							$originStr=~s/^.*>/ >/;
							$lastonewithout=$originStr;
							last;
						}
					}
					else
					{
						if(!($originStr=~/>.*;/))
						{
							my $temptstr = <READ>;
							chomp($temptstr);
							$originStr=$originStr.$temptstr;
						}
						push(@loopcontent,$originStr);
					}
				}
				
				if($#loopcontent==0)
				{
					
					print WRITETEMPT " $loopcontent[0]\n";
				    print WRITETEMPT "set c0 $opcodetime $lastonewithout\n";
				    
				}
				elsif($#loopcontent==1)
				{
					print WRITETEMPT " $loopcontent[0]\n";
				    if($loopcontent[1]=~/^\s*\w+\s*>/)
					{
						print WRITETEMPT "set c0 $opcodetime, $loopcontent[1]\n";
					}
					else
					{
						print WRITETEMPT "set c0 $opcodetime $loopcontent[1]\n";
					}
				    print WRITETEMPT " $lastonewithout\n";
				    
				}
				else
				{
					for($i=0;$i<($#loopcontent+1);$i++)
				    {
						if($i==0)
						{
							print WRITETEMPT " $loopcontent[0]\n";
						}
						elsif($i==1)
						{
							if($loopcontent[1]=~/^\s*\w+\s*>/)
							{
								print WRITETEMPT "set c0 $opcodetime, $loopcontent[1]\n";
							}
							else
							{
								print WRITETEMPT "set c0 $opcodetime $loopcontent[1]\n";
							}
							
						}
						else
						{
							print WRITETEMPT " $loopcontent[$i]\n";
						}
				    }
				    print WRITETEMPT " $lastonewithout\n";
				    
				}
				
				#true loop content
				print WRITETEMPT " $label  ";

				for($i=0;$i<($#loopcontent+1);$i++)
				{
					if($i==0)
					{
						if($loopcontent[0]=~/^\s*\w+\s*>/)
						{
							print WRITETEMPT "loop c0, $loopcontent[0]\n";
						}
						else
						{
							print WRITETEMPT " $loopcontent[0]\n";
						}
					}
					else
					{
						print WRITETEMPT " $loopcontent[$i]\n";
					}
				}
				
				print WRITETEMPT "$lastone\n";
				
				#third time of loop
				
				foreach my $loop (@loopcontent)
				{
					print WRITETEMPT " $loop\n";
				}
				
				my $thirdoflast=$lastone;
				$thirdoflast=~s/^.*>/ return >/;
				print WRITETEMPT " $thirdoflast\n";
				
				print WRITETEMPT "}\n";
				$result="";
				next;
			}
			
			
			print WRITE "$origindata\n";
			$beforetwo=$before;
			$before=$origindata;
			$result="";

		}
		else
		{
			print WRITE "$origindata\n";
		}
	}
	
	close WRITETEMPT;
	open READTEMPT,"<","tempt.txt";
	while ( defined( $originStr = <READTEMPT> ) ) 
	{
		chomp($originStr);
		print WRITE "$originStr\n";
	}
	
	close READ;
	close WRITE;
	close READTEMPT;
	unlink ("tempt.txt");
	unlink ("comment.txt");
}