#!/usr/bin/csh -f

if ($#argv < 2 || $#argv > 3) then
  echo ""
  echo "Usage: merge_iono_overall.csh inputfile config_file ncores"
  echo ""
  exit 1
endif

if (! -f dem.grd) then
  echo "dem.grd is required ..."
  exit 1
endif

if ($#argv < 3) then
   set ncores = 4
else
   set ncores = $3
endif

set input_file = $1
set config = $2
set iono = `grep correct_iono $config | awk '{print $3}'`

awk -F":" '{print $1}' $input_file | awk -F"/" '{print $4}' > new.pairs
# merge_batch_new.csh $input_file $config  # using 5 subswaths
merge_batch.csh $input_file $config

if ($iono == 1) then
   cd intf_h
   cp ../$config .
   ln -sf ../../topo/dem.grd .
   echo "Merging High Band"
   merge_batch_each_band.csh  high_band.list  $config

   echo "Unwrap High Band Phase"
   cp ../new.pairs .
   unwrap_parallel_new.csh  new.pairs  0.15  $ncores 
 
   echo "Add Topo Phase" 
   echo "phi = phi_disp + phi_topo"
   cat new.pairs | parallel -j $ncores -u --sshloginfile $PBS_NODEFILE \
   "cd $PWD; unwrap_add_topo.csh {}"
   # foreach date ($pair)
   #    cd $date
   #    snaphu_interp.csh 0.05 0 >& unwrap_high.log 
   #    cd ..
   # end
   cd ..
   
   cd intf_l
   cp ../$config .
   ln -sf ../../topo/dem.grd .
   echo "Merging Low Band"
   merge_batch_each_band.csh  low_band.list  $config

   echo "Unwrap Low Band Phase"
   cp ../new.pairs .
   unwrap_parallel_new.csh  new.pairs  0.15  $ncores

   echo "Add Topo Phase"
   echo "phi = phi_disp + phi_topo"
   cat new.pairs | parallel -j $ncores -u --sshloginfile $PBS_NODEFILE \
   "cd $PWD; unwrap_add_topo.csh {}"
   # foreach date ($pair)
   #    cd $date
   #    snaphu_interp.csh 0.05 0 >& unwrap_low.log 
   #    cd ..
   # end
   cd ..

   cd intf_o
   cp ../$config .
   ln -sf ../../topo/dem.grd .
   echo "Merging Mid Band"
   merge_batch_each_band.csh  mid_band.list  $config

   echo "Unwrap Mid Band Phase"
   cp ../new.pairs .
   unwrap_parallel_new.csh  new.pairs  0.15  $ncores

   echo "Add Topo Phase"
   echo "phi = phi_disp + phi_topo"
   cat new.pairs | parallel -j $ncores -u --sshloginfile $PBS_NODEFILE \
   "cd $PWD; unwrap_add_topo.csh {}"
   # foreach date ($pair)
   #    cd $date
   #    snaphu_interp.csh 0.05 0 >& unwrap_mid.log 
   #    cd ..
   # end
   cd ..
endif

rm -f new.pairs
