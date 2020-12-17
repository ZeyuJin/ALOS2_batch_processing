#!/bin/tcsh -f
# Modified by Zeyu Jin on Jan. 2019

if ($#argv < 3) then
  echo ""
  echo "Usage: intf_ALOS2_batch_new.csh intf.in batch.config swath Ncores"
  echo ""
  echo "     Format for intf.in:"
  echo "     reference1_name:repeat1_name"
  echo "     reference2_name:repeat2_name"
  echo "     reference3_name:repeat3_name"
  echo "     ......"
  echo ""
  echo "     Example of intf.in for ALOS2 ScanSAR"
  echo "IMG-HH-ALOS2101532950-160409-WBDR1.1__D:IMG-HH-ALOS2149142950-170225-WBDR1.1__D"
  echo "IMG-HH-ALOS2101532950-160409-WBDR1.1__D:IMG-HH-ALOS2155352950-170408-WBDR1.1__D"
  echo ""
  exit 1
endif

# set comm_path = "/home/class239/work/zeyu/software/shells/csh/"

rm -f intf_alos.cmd

set t1 = `date`
if ($#argv < 4) then
   set ncores = 4
else 
   set ncores = $4
endif

set swath = $3
# cd F$swath
# mkdir -p intf
# cleanup.csh intf
# cd ..

foreach intf (`cat $1`)
   set file1 = `echo $intf|awk -F":" '{print $1}'`
   set file2 = `echo $intf|awk -F":" '{print $2}'`
   set date1 =  `echo $file1 |awk -F"-" '{print $4}'`
   set date2 =  `echo $file2 |awk -F"-" '{print $4}'`
   set logfile = "intf_"$date1"_"$date2"_F"$swath".log"
   echo "intf_ALOS2_p2p_new.csh $file1 $file2 $2 $swath >& $logfile" >> intf_alos.cmd
end

parallel --jobs $ncores < intf_alos.cmd
mv "intf_"*"F$swath.log" F$swath

set t2 = `date`
set dir0 = `pwd`
echo "Job started on $t1 and finished on $t2 at $dir0/F$swath "|mail -s "Job finished" zej011@ucsd.edu
