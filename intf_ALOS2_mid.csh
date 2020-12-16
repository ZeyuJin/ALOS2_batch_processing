#!/bin/tcsh -f
# Modified by Zeyu Jin on Jul. 2020

if ($#argv != 2) then
  echo ""
  echo "Usage: intf_ALOS2_mid.csh  lineNo  intf_alos.cmd"
  exit 1
endif

set lineNo = $1
set argu_file = $2

set arguments = `awk -v lineNo=$lineNo 'NR==lineNo {print $0}' $argu_file`
set file1 = `echo $arguments | awk '{print $1}'`
set file2 = `echo $arguments | awk '{print $2}'`
set config = `echo $arguments | awk '{print $3}'`
set swath = `echo $arguments | awk '{print $4}'`
set logfile = `echo $arguments | awk '{print $5}'`

intf_ALOS2_p2p_new.csh $file1 $file2 $config $swath >& $logfile 

mv $logfile  F$swath
