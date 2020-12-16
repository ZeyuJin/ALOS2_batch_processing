#!/bin/tcsh -f
# Modified by Zeyu Jin on Jan. 2019

if ($#argv < 4 || $#argv > 5) then
  echo ""
  echo "Usage: intf_ALOS2_batch_new.csh intf.in batch.config start_swath end_swath Ncores"
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

set t1 = `date`
if ($#argv < 5) then
   set ncores = 4
else 
   set ncores = $5
endif

@ start_swath = $3
@ end_swath = $4
if ($start_swath > $end_swath) then
   echo "Error: The first swath must be larger than the end swath!"
   exit 1
else
#   set nswath = `echo $start_swath $end_swath | awk '{print $2-$1+1}'`
   @ next_swath = $start_swath
   set all_swath = ($start_swath)
   while ($next_swath < $end_swath)
      @ next_swath ++
      set all_swath = ($all_swath $next_swath)
   end
endif

# cd F$swath
# mkdir -p intf
# cleanup.csh intf
# cd ..

@ count = 0
rm -f intf_alos.cmd
foreach intf (`cat $1`)
   foreach swath (`echo $all_swath`)
      set file1 = `echo $intf|awk -F":" '{print $1}'`
      set file2 = `echo $intf|awk -F":" '{print $2}'`
      set date1 =  `echo $file1 |awk -F"-" '{print $4}'`
      set date2 =  `echo $file2 |awk -F"-" '{print $4}'`
      set logfile = "intf_"$date1"_"$date2"_F"$swath".log"
#      echo "intf_ALOS2_p2p_new.csh $file1 $file2 $2 $swath >& $logfile" >> intf_alos.cmd
#      echo "$file1 $file2 $2 $swath >& $logfile" >> intf_alos.cmd
      echo $file1 $file2 $2 $swath $logfile >> intf_alos.cmd
      @ count ++
   end
end

# parallel computing both subswaths and pairs
# assign number of nodes to each subswath
# assign number of CPUs of each node to each date pairs
seq $count | parallel -j $ncores -u --sshloginfile $PBS_NODEFILE \
"cd $PWD; intf_ALOS2_mid.csh {} intf_alos.cmd"
# cat $intf_alos.cmd | parallel -j $ncores -u --sshloginfile $PBS_NODEFILE \
# "cd $PWD; intf_ALOS2_p2p_new.csh {}"

# mv "intf_"*"F$swath.log" F$swath

set t2 = `date`
set dir0 = `pwd`
echo "Job started on $t1 and finished on $t2 at $dir0/F$swath "
