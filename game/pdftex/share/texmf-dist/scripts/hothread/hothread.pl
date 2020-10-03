eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}' && eval 'exec perl -S $0 $argv:q'
  if 0;
use strict;
#
# hothread.pl
#
# Copyright (C) 1999 Heiko Oberdiek.
#
# This program can be redistributed and/or modified under the terms
# of the LaTeX Project Public License distributed from CTAN
# archives in directory macros/latex/base/lppl.txt; either
# version 1 of the License, or (at your option) any later version.
#
# See file "readme.txt" for a list of files that belong to this project.
#
# This file "hothread.pl" may be renamed to "hothread"
# for installation purposes.
#
my $file        = "hothread.pl";
my $progname1   = ($file =~ /^(\w+)/,$1);
my $program     = uc($progname1);
my $version     = "0.1";
my $date        = "12.04.1999";
my $author      = "Heiko Oberdiek";
my $copyright   = "Copyright (c) 1999 by $author.";
#
# Reqirements: Perl5
# History:
#   1.0, 08.04.1999: First release.

### program identification
my $title = "$program $version, $date - $copyright\n";

### error strings
my $Error = "!!! Error:"; # error prefix

### usage
my @bool = ("false", "true");
$::opt_help=0;
$::opt_quiet=0;
$::opt_verbose=0;
$::opt_debug=0;

my $usage = <<"END_OF_USAGE";
${title}Syntax:   \L$program\E <pdf file>
Function:
Options:
  --help          print usage
  --(no)quiet     suppress messages  (default: $bool[$::opt_quiet])
  --(no)verbose   verbose printing   (default: $bool[$::opt_verbose])
  --(no)debug     debug informations (default: $bool[$::opt_debug])
END_OF_USAGE

### Printing functions
sub Debug
{
  print "* @_\n" if $::opt_debug;
}
sub Verbose
{
  print "* @_\n" if $::opt_verbose;
}
sub Info
{
  print "* @_\n" unless $::opt_quiet;
}
sub Die
{
  die "$Error @_!\n";
}
sub DieUsage
{
  print $usage;
  Die(@_);
}

### Variables
my @obj_off;
my @obj_txt;
my $trailer_txt;
my $root_no;
my $size;
my $threads_no;
my $threads_count;
my @thread_no;
my @thread_F;
my @thread_title;
my @thread_subject;
my @thread_author;
my @thread_keywords;
my @thread_beads_ref; # -> array with bead hash ref
my $pages_no;
my $pages_count;
my @page_no;
my @GetPage; # /Page obj -> page count
my @page_beads_ref; # -> array with bead obj
my @GetThread; # bead obj -> thread count
my @GetBead;   # bead obj -> bead count
my @MediaBox;

my $refpat = '\s*(\d+)\s+(\d+)\s+R\s*';
my $arraypat = '[0-9\sR]';
my $realpat = '[0-9\.]';
my $rectpat = '\s*\[\s*([0-9\.]+)\s+([0-9\.]+)\s+([0-9\.]+)\s+([0-9\.]+)\s*\]\s*';

my $i;

sub MakeArrayRef
{
  my $ref;
  eval('my @newarray; $ref = \@newarray;');
  return $ref;
}
sub MakeHashRef
{
  my $ref;
  eval('my %newhash; $ref = \%hash;');
  return $ref;
}

### Object handling

sub SeekObj
{
  seek(PDF, $obj_off[$_[0]], 0) or
    Die "Seek obj $_[0] [$obj_off[$_[0]]]";
}

sub GetObj
{
  my $objno = $_[0];
  my $result = "";
  my $line;

  SeekObj $objno;
  $line = <PDF>;
  $line =~ s/^\s*(\d+)\s+(\d+)\s+obj\s*// or Die "obj <$objno> not found";
  $objno == $1 or Die "Wrong obj number: $objno <> $1 (found)";
  while (1)
  {
    if ($line =~ /\s*endobj/)
    {
      $result .= $`;
      last;
    }
    $result .= $line;
    $line = <PDF>;
  }
  $obj_txt[$objno] = $result;
  return 1;
}

sub GetString
{
  my $str = $_[0];
  my $len = length($str);
  my $result = "";
  my $level = 1;

  while ($str)
  {
    if ($str =~ s/^((\\[\d\w\(\)\\])+)//) {
      $result .= $1;
      next;
    }
    if ($str =~ s/^([^\\\(\)])//) {
      $result .= $1;
      next;
    }
    if ($str =~ s/^(\()//) {
      $result .= $1;
      $level++;
      next;
    }
    if ($str =~ s/^(\))//) {
      $level--;
      if ($level > 0) {
        $result .= $1;
        next;
      }
      else {
        last;
      }
    }
  }
  $level == 0 or Die "Error string processing: ($_[0]";
  return $result;
}

### process options
use Getopt::Long;
GetOptions(
  "help!",
  "quiet!",
  "verbose!",
  "debug!"
) or die $usage;
!$::opt_help or die $usage;
@ARGV < 2 or DieUsage "Too many files";
@ARGV == 1 or DieUsage "No pdf file";

$::opt_verbose = 1 if $::opt_debug;
$::opt_quiet = 0 if $::opt_verbose;


### get pdf file name
my $pdffile;
$pdffile = $ARGV[0];
$pdffile .= '.pdf' if -f "$pdffile.pdf";
-f $pdffile or DieUsage "PDF file '$pdffile' not found";

print $title unless $::opt_quiet;
Verbose "pdf file: $pdffile";

# open file
my $PDF = $pdffile;
open(PDF, $PDF) or die "$Error Cannot open '$PDF'!\n";
binmode(PDF);

# get startxref
my $startxref;
{
  my $buffer;
  my $length = 30;
  seek(PDF, -$length, 2) or die "$Error Cannot seek '$PDF'!\n";
  read(PDF,$buffer,$length) == $length or
    die "$Error Cannot read '$PDF'!\n";
  $buffer =~ /startxref\s+(\d+)\s+%%EOF$/m or
    die "$Error Cannot find 'startxref'!\n";
  $startxref = $1;
}
Debug "startxref: [$startxref]";

my $line;

# read max xref
my $max_xref;
{
  seek(PDF, $startxref, 0) or die "$Error Cannot seek 'startxref'!\n";

  # Line: xref
  $line = <PDF>;
  chomp $line;
  $line =~ /^xref$/ or die "$Error 'xref' not found!\n";

  # Line: 0 <count>
  $line = <PDF>;
  $line =~ /^\s*0\s+(\d+)\s*$/ or die "$Error Cannot get xref count!\n";
  $max_xref = $1;
}
Debug "max xref: $max_xref";

# read xref table
{
  my $i;
  for ($i=0; $i<$max_xref; $i++)
  {
    $line = <PDF>;
    $line =~ /^(\d{10})\s(\d{5})\s([nf])\s*$/ or
      die "$Error Parsing xref table!\n";
    $obj_off[$i] = 0;
    if ($3 eq "n")
    {
      $2 == 0 or Die "Generation number not supported";
      $obj_off[$i] = $1 + 0; # remove leading zeros
    }
  }
}

# trailer
$trailer_txt = "";
while (<PDF>)
{
  if (/startxref/) {
    last;
  }
  $trailer_txt .= $_;
}
$trailer_txt =~ /^\s*trailer\s*<<\s*([\s\S]*)\s*>>\s*$/ or
  Die "trailer syntax error";
$trailer_txt = $1;

# check /Prev
$trailer_txt !~ /\/Prev/ or Die "Incremental pdf not supported";

# get /Root
$trailer_txt =~ /\/Root$refpat/m or Die "/Root not found";
$root_no = $1;
Debug "/Root: <$root_no> [$obj_off[$root_no]]";
GetObj $root_no;

# get /Size
$trailer_txt =~ /\/Size\s*(\d+)\s+/ or Die "Size not found";
$size = $1;

# threads
$obj_txt[$root_no] =~ /\/Threads$refpat/ or Die "/Threads not found!\n";
$threads_no = $1;
Debug "/Threads: <$threads_no> [$obj_off[$threads_no]]";
GetObj $threads_no;

# threads list
{
  my $txt = $obj_txt[$threads_no];
  $txt =~ /^\s*\[($arraypat*)\]\s*$/ or Die "Threads: no array";
  $txt = $1;
  $threads_count = 0;
  while ($txt =~ s/$refpat//)
  {
    $thread_no[$threads_count++] = $1;
  }
  $threads_count > 0 or Die "No threads found";
  my $store = $";
  $" = "> <";
  Debug "Threads ($threads_count): <@thread_no>";
  $" = $store;
  $threads_count == 1 or Die "Only one thread supported";
}

# read threads
for ($i=0; $i<@thread_no; $i++)
{
  my $no = $thread_no[$i];
  GetObj $no;
  my $txt = $obj_txt[$no];
  # /I
  if ($txt =~ /\/I\s*<</)
  {
    if ($txt =~ /\/Title\s*\(/)
    {
      $thread_title[$i] = GetString $';
      Debug "thread $i <$no>: /Title ($thread_title[$i])";
    }
    if ($txt =~ /\/Subject\s*\(/)
    {
      $thread_subject[$i] = GetString $';
      Debug "thread $i <$no>: /Subject ($thread_subject[$i])";
    }
    if ($txt =~ /\/Author\s*\(/)
    {
      $thread_author[$i] = GetString $';
      Debug "thread $i <$no>: /Subject ($thread_author[$i])";
    }
    if ($txt =~ /\/Keywords\s*\(/)
    {
      $thread_keywords[$i] = GetString $';
      Debug "thread $i <$no>: /Keywords ($thread_keywords[$i])";
    }
  }
  else
  {
    Debug "thread $i <$no>: No /I dict"
  }

  # /F
  $txt =~ s/\/F$refpat// or Die "/F not found in thread <$no>";
  $thread_F[$i] = $1;
  Debug "thread $i <$no>: /F <$thread_F[$i]>";

  my @bead_refs;
  my $bead_count = 0;
  my $bead_N = $thread_F[$i];
  do
  {
    my %bead = ("obj", $bead_N);
    $GetThread[$bead_N] = $i;
    $GetBead[$bead_N] = $bead_count;
    GetObj $bead_N;
    my $txt = $obj_txt[$bead_N];
    my $msg = "";

    if ($txt =~ /\/T$refpat/) {
      $bead{T} = $1;
      $msg .= " T=<$1>";
    }
    if ($txt =~ /\/V$refpat/) {
      $bead{V} = $1;
      $msg .= " V=<$1>";
    }
    if ($txt =~ /\/N$refpat/) {
      $bead{N} = $1;
      $msg .= " N=<$1>";
    }
    if ($txt =~ /\/P$refpat/) {
      $bead{P} = $1;
      $msg .= " P=<$1>";
    }
    if ($txt =~ /\/R$refpat/) {
      $bead{R} = $1;
      $msg .= " R=<$1>";
      GetObj $1;
    }
    Debug "thread $i <$no>, bead $bead_count <$bead_N>:$msg";
    if ($bead_count == 0) {
      exists($bead{T}) or Die "/T (thread) missing";
    }
    exists($bead{V}) or Die "/V (prev) missing";
    exists($bead{N}) or Die "/N (next) missing";
    exists($bead{P}) or Die "/P (page) missing";
    exists($bead{R}) or Die "/R (rect) missing";
    $bead_refs[$bead_count] = \%bead;
    $bead_count++;
    $bead_N = $bead{N};
  }
  while ($bead_N != $thread_F[$i]);
  $thread_beads_ref[$i] = \@bead_refs;
}

# Pages
$obj_txt[$root_no] =~ /\/Pages$refpat/ or Die "/Pages not found!\n";
$pages_no = $1;
Debug "/Pages: <$pages_no> [$obj_off[$pages_no]]";
GetObj $pages_no;

# Pages list
{
  my $txt = $obj_txt[$pages_no];
  $txt =~ /\/Type\s*\/Pages/ or Die "Pages dict not found";
  $txt =~ /\/Count\s*(\d+)\D/ or Die "Pages: /Count not found";
  $pages_count = $1;
  $pages_count > 0 or Die "No pages (nothing to do)";
  {
    my $vrb = "$pages_count page";
    $vrb .= "s" if $pages_count > 1;
    $vrb .= " with $threads_count thread";
    $vrb .= "s" if $threads_count > 1;
    Info "$vrb:";
  }

  $txt =~ /\/Kids\s*\[($arraypat*)\]\s*/ or Die "Pages: /Kids not found";
  my @Kids = split(/\s+0\s+R\s*/, $1);
  Debug "Kids: @Kids";
  $i = 0; # page counter
  while (@Kids)
  {
    my $no = shift @Kids;
    GetObj $no;

    if ($obj_txt[$no] =~ /\/Type\s*\/Pages/)
    {
      $obj_txt[$no] =~ /\/Kids\s*\[($arraypat*)\]\s*/ or
        Die "Pages: /Kids not found";
      unshift(@Kids, split(/\s+0\s+R/, $1));
      Debug "Kids: @Kids";
      next;
    }

    $obj_txt[$no] =~ /\/Type\s*\/Page/ or Die "Page not found";
    $GetPage[$no] = $i;
    $page_no[$i] = $no;
    my $txt = $obj_txt[$no];
    my @page_beads = ();
    if ($txt =~ /\/B\s*\[($arraypat*)\]/)
    {
      $txt = $1;
      my $dbg = "";
      my $vrb = "";
      while ($txt =~ s/$refpat//)
      {
        my $bobj = $1;
        $page_beads[@page_beads] = $bobj;
        my $tno = $GetThread[$bobj] + 1;
        my $bno = $GetBead[$bobj] + 1;
        $dbg .= " <$bobj>";
        $vrb .= " ";
        $vrb .= "\#$tno" if $threads_count > 1;
        $vrb .= "\#$bno";
      }
      my $page_beads_count = @page_beads;
      Debug "/B page $i:$dbg";
      Info sprintf("%d %s on page \#%d:%s",
        $page_beads_count,
        (($page_beads_count>1) ? "beads" : "bead"),
        $i+1, $vrb);
    }
    $page_beads_ref[$i] = \@page_beads;
    $i++;
  }
  $i == $pages_count or Die "Pages (/Count) != Pages (/Kids)";
  my $store = $";
  $" = "> <";
  Debug "Pages ($pages_count): <@page_no>";
  $" = $store;
}

# list threads
for ($i=0; $i<$threads_count; $i++)
{
  my @bead_refs = @{$thread_beads_ref[$i]};
  my $bead_count = @bead_refs;
  my $msg = $i+1; $msg = "\#$msg";
  $msg = " $i <obj=$thread_no[$i]>" if $::opt_debug;
  Verbose "Thread $msg ($thread_title[$i]) with $bead_count beads:";

  my $b;
  for ($b=0; $b<@bead_refs; $b++)
  {
    my %bead = %{$bead_refs[$b]};
    my $msg = "";
    if (exists($bead{T})) {
      $bead{T} == $thread_no[$i] or Die "Wrong bead thread reference";
      $msg .= "Thread=<obj $bead{T}>, ";
    }
    $msg .= "Prev=<$bead{V}>, Next=<$bead{N}>, " .
            "Page=<$bead{P}>, Rect=<$bead{R}>";
    my $rect = $obj_txt[$bead{R}];
    $rect =~ /^$rectpat$/ or Die "Rect array not found";
    my @r = ($1, $2, $3, $4);
    $msg .= ",\n  rect = [$r[0] $r[1] $r[2] $r[3]]";
    my $factor = 25.4 / 72;
    $msg .= sprintf(" [%.1fmm + %.1fmm, %.1fmm + %.1fmm]",
      $r[0]*$factor, ($r[2]-$r[0])*$factor,
      $r[1]*$factor, ($r[3]-$r[1])*$factor);
    my $ord_bead = $b + 1;
    Debug "bead $b <$bead{obj}>: $msg";

    my $pg = $GetPage[$bead{P}];
    my $txt = $obj_txt[$bead{P}];
    $msg = "";
    if ($txt =~ /\/MediaBox$rectpat/) {
      my @mb = ($1, $2, $3, $4);
      @MediaBox = @mb;
      my $x = $3-$1;
      my $y = $4-$2;
      $x > 0 or Die "Negative MediaBox width";
      $y > 0 or Die "Negative MediaBox height";
      $x = $x/100;
      $y = $y/100;
      $msg = sprintf(
        ", [%4.1f-%4.1f%%, %4.1f-%4.1f%%], size = %4.1f%% x %4.1f%%",
        $r[0]/$x, $r[2]/$x, $r[1]/$y, $r[3]/$y,
        ($r[2]-$r[0])/$x, ($r[3]-$r[1])/$y
      );
    }
    Verbose sprintf("Bead \#%i on page \#%i%s", $b+1, $pg+1, $msg);
  }
}

Debug "MediaBox: [$MediaBox[0] $MediaBox[1] $MediaBox[2] $MediaBox[3]]";

close(PDF);



####################

my $LOG = $PDF;
$LOG =~ s/\.pdf$//i;
$LOG .= '.log';

open(LOG, $LOG) or die "$Error Cannot open '$LOG'!\n";


my %Log;
$Log{HeadY} = 0;
$Log{HeadHeight} = 0;
$Log{FootY} = 0;
$Log{FootHeight} = 0;
my $LogThreadCount = 0;
my @LogThreadRef = ();
my $LogBeadCount = 0;
my @LogBeadRef = ();

sub PTtoBP
{
  my $result = $_[0];
  $result *= 72/72.27;
  return $result;
}

sub GetLogThread
{
  my $Title = $_[0];
  my $i;
  for ($i=0; $i<$LogThreadCount; $i++)
  {
    my %Thread = %{$LogThreadRef[$i]};
    if ($Thread{Title} eq $Title)
    {
      return $i;
    }
  }
  Die "Cannot find thread ($Title)";
  return -1;
}


while (<LOG>)
{
  next unless /hothread/;
  if (s/^Package hothread Info: //)
  {
    if (/^\/(Title) \((.*)\)$/)
    {
      my %NewThread;
      $NewThread{$1} = $2;
      Verbose "Thread $LogThreadCount: Title = ($2)";
      do
      {
        $_ = <LOG>;
        /^\(hothread\)\s+\/(.+)\s+\((.*)\)[\.]?$/ or
          Die "Reading \\newthread info";
        $NewThread{$1} = $2;
        Verbose "       $LogThreadCount: $1 = ($2)";
      }
      while (!/\.$/);
      $LogThreadRef[$LogThreadCount] = \%NewThread;
      $LogThreadCount++;
      next;
    }

    if (/^\/(HeadY)\s+([\d\.]+)pt$/)
    {
      $Log{$1} = PTtoBP($2);
      Verbose "$1: $Log{$1}";
      do
      {
        $_ = <LOG>;
        /^\(hothread\)\s+\/(.+)\s+([\d\.]+)pt[\.]?$/ or
          Die "Reading head/foot info";
        $Log{$1} = PTtoBP($2);
        Verbose "$1: $Log{$1}";
      }
      while (!/\.$/);
      next;
    }

    if (/^\/Thread\s+\[(\d+)\]\s+\((.*)\)\.$/)
    {
      my %LogBead;
      my $b = GetLogThread($2);
      $LogBead{Thread} = $b;
      $LogBead{StartPage} = $1;
      while (<LOG>)
      {
        if (/\/EndThread\s+\[(\d+)\]\.$/)
        {
          $LogBead{EndPage} = $1;
          last;
        }
      }
      Verbose "Bead $LogBeadCount: Thread: $b, " .
              "Page $LogBead{StartPage}" .
              (($LogBead{StartPage}==$LogBead{EndPage}) ?
              "": "-$LogBead{EndPage}");
      $LogBeadRef[$LogBeadCount] = \%LogBead;
      ${$LogThreadRef[$b]}{Used} = 1;
      $LogBeadCount++;
      next;
    }
  }
}

################


my @FreeObj = ();
my @NewObj = ();
my $NewSize = $size;
my @NewPageObj = ();
my @NewPageB = ();

my $NewThreadCount = 0;
my (@NewThreadObj, @NewThreadLogNo, @NewThreadTitle, @NewThreadSubject,
    @NewThreadAuthor, @NewThreadKeywords, @NewThreadFirst);
my @GetNewThreadNo = ();
my $NewBeadCount = 0;
my (@NewBeadObj, @NewBeadTNo,
    @NewBeadT, @NewBeadV, @NewBeadN, @NewBeadP, @NewBeadR);

for ($i=0; $i<@LogThreadRef; $i++)
{
  my %T = %{$LogThreadRef[$i]};
  if (exists($T{Used}))
  {
    $NewThreadLogNo   [$NewThreadCount] = $i;
    $GetNewThreadNo[$i] = $NewThreadCount;
    $NewThreadTitle   [$NewThreadCount] = $T{Title};
    $NewThreadSubject [$NewThreadCount] = $T{Subject};
    $NewThreadAuthor  [$NewThreadCount] = $T{Author};
    $NewThreadKeywords[$NewThreadCount] = $T{Keywords};
    $NewThreadCount++;
  }
}
$NewThreadCount > 0 or Die "No new threads used";
Debug "$NewThreadCount thread(s) in the log used.";

$NewThreadObj[0] = $thread_no[0];
$NewObj[@NewObj] = $thread_no[0];
Info "New thread 0: $NewThreadTitle[0]";
for ($i=1; $i<$NewThreadCount; $i++)
{
  Info "New thread $i: $NewThreadTitle[$i]";
  $NewThreadObj[$i] = $NewSize;
  $NewObj[@NewObj] = $NewSize;
  $NewSize++;
}

my $OldBeadCount = @{$thread_beads_ref[0]};
my @OldBeadRef = @{$thread_beads_ref[0]};

my $Overflow = 0;
my $FootMax = $Log{FootY};
my $FootMin = $Log{FootY} - $Log{FootHeight};
my $HeadMax = $Log{HeadY} + $Log{HeadHeight};
my $HeadMin = $Log{HeadY};
my $l = 0;
for ($i=0; $i<$OldBeadCount; $i++)
{
  Debug "pdf bead $i, log bead $l";
  my %OldBead = %{$OldBeadRef[$i]};
  my $Rect = $obj_txt[$OldBead{R}];
  $Rect =~ /$rectpat/ or Die "Cannot get rect";
  my @R = ($1,$2,$3,$4);
  if (abs($HeadMax-$4)<0.1 and abs($HeadMin-$2)<0.1)
  {
    Debug "Ignoring bead in head line: \#$i";
    $FreeObj[@FreeObj] = $OldBead{obj};
    $NewPageObj[@NewPageObj] = $OldBead{P};
    next;
  }
  if (abs($FootMax-$4)<0.1 and abs($FootMin-$2)<0.1)
  {
    Debug "Ignoring bead in foot line: \#$i";
    $FreeObj[@FreeObj] = $OldBead{obj};
    $NewPageObj[@NewPageObj] = $OldBead{P};
    next;
  }

  $l < $LogBeadCount or Die "No more log beads";
  my %LogBead = %{$LogBeadRef[$l]};
  $NewBeadObj[$NewBeadCount] = $OldBead{obj};
  $NewObj[@NewObj] = $NewBeadObj[$NewBeadCount];
  $NewBeadTNo[$NewBeadCount] = $GetNewThreadNo[$LogBead{Thread}];
  $NewBeadT[$NewBeadCount]   = $NewThreadObj[$NewBeadTNo[$NewBeadCount]];
  $NewBeadP[$NewBeadCount]   = $OldBead{P};
  $NewBeadR[$NewBeadCount]   = $OldBead{R};
  $NewBeadCount++;
  $l++;

  if ($Overflow)
  {
    $Overflow = 0;
    next;
  }
  if ($LogBead{StartPage} != $LogBead{EndPage})
  {
    $l--;
    $Overflow = 1;
  }
}

# remove double pages
{
  my $last = 0;
  my @P = @NewPageObj;
  @NewPageObj = ();
  for ($i=0; $i<@P; $i++)
  {
    next if $P[$i] == $last;
    $last = $P[$i];
    $NewPageObj[@NewPageObj] = $last;
  }
}

for ($i=0; $i<$NewThreadCount; $i++)
{
  my $b;
  my @list = ();
  my $first = 0;
  for ($b=0; $b<$NewBeadCount; $b++)
  {
    next if $NewBeadTNo[$b] != $i;
    $list[@list] = $b;
  }
  @list > 0 or Die "No beads found for Thread $i";
  my $store = $";
  $" = ", \#";
  Debug "Beads of thread \#$i: \#@list";
  $" = $store;

  $NewThreadFirst[$i] = $NewBeadObj[$list[0]];
  my $txt = "/Title ($NewThreadTitle[$i])\n";
  $txt .= "/Subject ($NewThreadSubject[$i])\n" if $NewThreadSubject[$i];
  $txt .= "/Author ($NewThreadAuthor[$i])\n" if $NewThreadAuthor[$i];
  $txt .= "/Keywords ($NewThreadKeywords[$i])\n" if $NewThreadKeywords[$i];
  chomp $txt;
  $obj_txt[$NewThreadObj[$i]] = "<< /F $NewThreadFirst[$i] 0 R\n" .
    "/I << $txt >>\n>>";
  Debug "New thread obj \#$i <$NewThreadObj[$i]>:\n" .
    $obj_txt[$NewThreadObj[$i]];

  $NewBeadV[$list[0]] = $NewBeadObj[$list[@list-1]];
  $NewBeadN[$list[@list-1]] = $NewBeadObj[$list[0]];
  if (@list > 1)
  {
    my $b;
    for ($b=0; $b<@list-1; $b++)
    {
      $NewBeadV[$list[$b+1]] = $NewBeadObj[$list[$b]];
      $NewBeadN[$list[$b]] = $NewBeadObj[$list[$b+1]];
    }
  }

  for ($b=0; $b<@list; $b++)
  {
    $txt = "";
    $txt = "/T $NewBeadT[$list[$b]] 0 R\n" unless $b;
    $txt .= "/V $NewBeadV[$list[$b]] 0 R\n";
    $txt .= "/N $NewBeadN[$list[$b]] 0 R\n";
    $txt .= "/P $NewBeadP[$list[$b]] 0 R\n";
    $txt .= "/R $NewBeadR[$list[$b]] 0 R\n";
    $obj_txt[$NewBeadObj[$list[$b]]] = "<< $txt>>";
    Debug "Bead <$NewBeadObj[$list[$b]]>: " .
      "$obj_txt[$NewBeadObj[$list[$b]]]";

    my $p;
    for ($p=0; $p<@NewPageObj; $p++)
    {
      next unless $NewPageObj[$p] == $NewBeadP[$list[$b]];
      if ($NewPageB[$p])
      {
        $NewPageB[$p] .= " $NewBeadObj[$list[$b]] 0 R";
      }
      else
      {
        $NewPageB[$p] = "$NewBeadObj[$list[$b]] 0 R";
      }
    }
  }
}

for ($i=0; $i<@NewPageObj; $i++)
{
  $NewObj[@NewObj] = $NewPageObj[$i];
  if ($NewPageB[$i])
  {
    $obj_txt[$NewPageObj[$i]] =~
      s/\s*\/B\s*[$arraypat*]\s*/\n\/B [$NewPageB[$i]]\n/;
  }
  else
  {
    $obj_txt[$NewPageObj[$i]] =~ s/\s*\/B\s*[$arraypat*]\s*/\n/;
  }
  Debug "New page obj <$NewPageObj[$i]>: " .
    "$obj_txt[$NewPageObj[$i]]";
}

$NewObj[@NewObj] = $threads_no;
{
  my $store = $";
  $" = " 0 R ";
  $obj_txt[$threads_no] = "[@NewThreadObj 0 R]";
}
Debug "Threads <$threads_no>: $obj_txt[$threads_no]";


#######

Debug "New size: $NewSize";

my @NewObjType;
for ($i=0; $i<@NewObj; $i++)
{
  $NewObjType[$NewObj[$i]] = "n";
}
for ($i=0; $i<@FreeObj; $i++)
{
  $NewObjType[$FreeObj[$i]] = "f";
}
@NewObj = ();
@FreeObj = ();
for ($i=0; $i<$NewSize; $i++)
{
  next unless $NewObjType[$i];
  $NewObj[@NewObj] = $i if $NewObjType[$i] eq "n";
  $FreeObj[@FreeObj] = $i if $NewObjType[$i] eq "f";
}
{
  my $store = $";
  $"="> <";
  Debug "New obj: <@NewObj>";
  Debug "Free obj: <@FreeObj>" if @FreeObj;
  $" = $store;
}

open(PDF, ">>$PDF") or Die "Cannot open $PDF";
binmode(PDF);
seek(PDF,0,2);
Info "Updating '$PDF'";
my @NewAdr = ();
for ($i=0; $i<@NewObj; $i++)
{
  $NewAdr[$NewObj[$i]] = tell(PDF);
  my $txt = $obj_txt[$NewObj[$i]];
  if ($txt =~ s/^<<\s/<<\n/)
  { $txt = " $txt "; }
  else
  { $txt = "\n$txt\n"; }
  print PDF "$NewObj[$i] 0 obj${txt}endobj\n";
}
my $newstartxref = tell(PDF);
print PDF "xref\n";
$NewObjType[0] = "f";
my $NextFree = shift(@FreeObj);
for ($i=0; $i<$NewSize; $i++)
{
  next unless $NewObjType[$i];
  my $l = $i+1;
  while ($NewObjType[$l])
  {
    $l++;
  }
  print PDF sprintf("%d %d\n", $i, $l-$i);
  for (; $i<$l; $i++)
  {
    if ($NewObjType[$i] eq "n")
    {
      print PDF sprintf("%010d 00000 n \n", $NewAdr[$i]);
    }
    else
    {
      $NextFree = 0 unless $NextFree;
      print PDF sprintf("%010d %s f \n",
        $NextFree, (($i) ? "00001" : "65535"));
      $NextFree = shift(@FreeObj);
    }
  }
}

my $NewTrailer = "/Prev $startxref\n$trailer_txt";
$NewTrailer =~ s/\/Size\s*\d+(\D)/\/Size $NewSize$1/;
chomp $NewTrailer;
Debug "Trailer: $NewTrailer";
print PDF "trailer\n<<\n$NewTrailer\n>>\nstartxref\n$newstartxref\n%%EOF";
close(PDF);

Info "ready.";

__END__
