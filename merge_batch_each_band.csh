#!/bin/csh -f
#       $Id$
#
#    Xiaohua(Eric) XU, July 7, 2016
#    Modified by Zeyu Jin, Jan 31, 2019
#
# Script for merging 3 or 5 subswaths ScanSAR interferograms 
# Used to merge three bands (high, low, mid) for the following
# Ionospheric correction (No need to geocode!)

  if ($#argv != 2) then
    echo ""
    echo "Usage: merge_batch_iono.csh inputfile config_file"
    echo ""
    echo "Note: Inputfiles should be as following:"
    echo ""
    echo "      IF1_Swath1_Path:master.PRM:repeat.PRM,IF1_Swath2_Path:master.PRM:repeat.PRM,IF1_Swath3_Path:master.PRM:repeat.PRM"
    echo "      IF2_Swath1_Path:master.PRM:repeat.PRM,IF2_Swath2_Path:master.PRM:repeat.PRM,IF1_Swath3_Path:master.PRM:repeat.PRM"
    echo "      (Use the repeat PRM which contains the shift information.)"
    echo "      e.g. ../F1/intf_all/2015092_2015128/:S1A20150403_ALL_F1.PRM:S1A20150509_ALL_F1.PRM,../F2/intf_all/2015092_2015128/:S1A20150403_ALL_F2.PRM:S1A20150509_ALL_F2.PRM,../F3/intf_all/2015092_2015128/:S1A20150403_ALL_F3.PRM:S1A20150509_ALL_F3.PRM"
    echo ""
    echo "      Make sure under each path, the processed phasefilt.grd, corr.grd and mask.grd exist."
    echo "      Also make sure the dem.grd is linked. "
    echo "      If trans.dat exits, recomputation of projection matrix will not proceed."
    echo "      The master image of first line should be the super_master."
    echo ""
    echo "      config_file is the same one used for processing."
    echo ""
    echo "Example: merge_batch_iono.csh filelist batch.config"
    echo ""
    exit 1
  endif

  if (! -f dem.grd) then
    echo "dem.grd is required ..."
    exit 1
  endif

  set input_file = $1
  awk 'NR==1{print $0}' $input_file | awk -F, '{for (i=1;i<=NF;i++) print "../"$i}' | awk -F: '{print $1$2}'> tmpm.filelist 
  
  set now_dir = `pwd`
  
  foreach line (`awk '{print $0}' $input_file`)
    set dir_name = `echo $line | awk -F, '{print $1}' | awk -F: '{print $1}' | awk -F"/" '{print $(NF-1)}'`
    mkdir -p $dir_name
    cd $dir_name
    echo $line | awk -F, '{for (i=1;i<=NF;i++) print "../"$i}' > tmp.filelist
    paste ../tmpm.filelist tmp.filelist | awk '{print $1","$2}' > tmp
    rm tmp.filelist
    
    foreach f_name (`awk '{print $0}' < tmp`)
       set mm = `echo $f_name | awk -F, '{print $1}'`
       set pth = `echo $f_name | awk -F, '{print $2}' | awk -F: '{print $1}'`
       set f1 = `echo $f_name | awk -F, '{print $2}' | awk -F: '{print $2}'`
       set f2 = `echo $f_name | awk -F, '{print $2}' | awk -F: '{print $3}'`
       cp $mm ./supermaster.PRM
       set rshift = `grep rshift $pth$f1 | tail -1 | awk '{print $3}'`
       update_PRM supermaster.PRM rshift $rshift
       set fs1 = `grep first_sample supermaster.PRM | awk '{print $3}'`
       set fs2 = `grep first_sample $pth$f1 | awk '{print $3}'`
       if ($fs2 > $fs1) then
         update_PRM supermaster.PRM first_sample $fs2
       endif
       cp supermaster.PRM $pth
       echo $pth":supermaster.PRM:"$f2 >> tmp.filelist
    end
    
    # if (-f ../trans.dat) ln -s ../trans.dat .
    # if (-f ../raln.grd) ln -s ../raln.grd .
    # if (-f ../ralt.grd) ln -s ../ralt.grd .
    # if (-f ../landmask_ra.grd ) ln -s ../landmask_ra.grd .
    ln -sf ../dem.grd .
    ln -sf ../$2 .
    rm tmp
    
    touch trans.dat  # in avoid of compute trans.dat which costs too much time
    # merge_ScanSAR.csh tmp.filelist $2                 # merge five subswaths
    # merge_unwrap_geocode_tops.csh tmp.filelist $2       # merge three subswaths
    merge_unwrap_topo.csh  tmp.filelist  $2
    # merge_unwrap_topo_four.csh  tmp.filelist  $2   # merge four subswaths
    rm trans.dat

    # if (! -f ../trans.dat && -f trans.dat) then
    #   mv trans.dat ../
    #   ln -s ../trans.dat .
    # endif
    # if (! -f ../landmask_ra.grd && -f landmask_ra.grd ) then
    #   mv landmask_ra.grd  ../
    #   ln -s ../landmask_ra.grd .
    # endif
    # if (! -f ../raln.grd && -f raln.grd) then
    #   mv raln.grd ../
    #   ln -s ../raln.grd .
    # endif
    # if (! -f ../ralt.grd && -f raln.grd) then
    #   mv ralt.grd ../
    #   ln -s ../ralt.grd .
    # endif

    cd $now_dir

  end
