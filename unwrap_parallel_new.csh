#!/bin/csh -f
# 
# By Xiaohua XU, 03/12/2018
#
# Unwrap interferograms parallelly using GNU parallel
#
# IMPORTANT: put a script called unwrap_intf.csh in the current folder
# e.g. 
#   cd $1
#   snaphu[_interp].csh 0.1 0 
#   cd ..
#

if ($#argv != 3) then
  echo ""
  echo "Usage: unwrap_parallel.csh intflist threshold Ncores"
  echo ""
  echo "    Run unwrapping jobs parallelly. Need to install GNU parallel first."
  echo "    Note, run this in the intf_all folder where all the interferograms are stored. "
  echo ""
  exit
endif

set ncores = $3
set threshold = $2
set d1 = `date`

rm -f unwrap.cmd

foreach line (`awk '{print $0}' $1`)
  echo "unwrap_intf.csh $line $threshold >& log_$line.txt" >> unwrap.cmd
end

parallel --jobs $ncores < unwrap.cmd

echo ""
echo "Finished all unwrapping jobs..."
echo ""

set d2 = `date`

echo "parallel --jobs $ncores < intf_tops.cmd" | mail -s "Unwrapping finished" "zej011@ucsd.edu" 
