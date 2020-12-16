#!/bin/csh -f

if ($#argv != 2) then
   echo ""
   echo "Usage: unwrap_intf.csh dates unwrap_threshold"
   echo ""
   exit 1
endif

set dates = $1
set threshold = $2
cd $dates

snaphu_interp.csh $threshold 0 
# snaphu_interp.csh $threshold 50

cd .. 
