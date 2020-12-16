#!/bin/csh -f
#       $Id$
#
#    Xiaohua(Eric) XU, July 7, 2016
#    Modified by Zeyu Jin, 31, Jan, 2018
#
# Script for merging 5 subswaths ScanSAR mode interferograms. 
#
  if ($#argv != 2) then
    echo ""
    echo "Usage: merge_ScanSAR.csh inputfile config_file"
    echo ""
    echo "Note: Inputfiles should be as following:"
    echo ""
    echo "      Swath1_Path:Swath1_master.PRM:Swath1_repeat.PRM"
    echo "      Swath2_Path:Swath2_master.PRM:Swath2_repeat.PRM"
    echo "              ...:...           ...:...              "
    echo "      Swath5_Path:Swath5_master.PRM:Swath5_repeat.PRM"
    echo "      (Use the repeat PRM which contains the shift information.)"
    echo "      e.g. ../F1/intf/2015016_2015030/:S1A20151012_134357_F1.PRM"
    echo ""
    echo "      Make sure under each path, the processed phasefilt.grd, corr.grd and mask.grd exist."
    echo "      Also make sure the dem.grd is linked. "
    echo ""
    echo "      config_file is the same one used for processing."
    echo ""
    echo "Example: merge_ScanSAR.csh filelist batch.config"
    echo ""
    exit 1
  endif

  if (-f tmp_phaselist) rm tmp_phaselist
  if (-f tmp_corrlist) rm tmp_corrlist
  if (-f tmp_masklist) rm tmp_masklist

  if (! -f dem.grd ) then
    echo "Please link dem.grd to current folder"
    exit 1
  endif

  set region_cut = `grep region_cut $2 | awk '{print $3}'`

  # Creating inputfiles for merging
  foreach line (`awk '{print $0}' $1`)
    set now_dir = `pwd`
    set pth = `echo $line | awk -F: '{print $1}'`
    set prm = `echo $line | awk -F: '{print $2}'`
    set prm2 = `echo $line | awk -F: '{print $3}'`
    cd $pth
    set rshift = `grep rshift $prm2 | tail -1 | awk '{print $3}'`
    set fs1 = `grep first_sample $prm | awk '{print $3}'`
    set fs2 = `grep first_sample $prm2 | awk '{print $3}'`
    cp $prm tmp.PRM
    if ($fs2 > $fs1) then
      update_PRM tmp.PRM first_sample $fs2
    endif
    update_PRM tmp.PRM rshift $rshift
    cd $now_dir

    echo $pth"tmp.PRM:"$pth"phasefilt.grd" >> tmp_phaselist
    echo $pth"tmp.PRM:"$pth"corr.grd" >> tmp_corrlist
    echo $pth"tmp.PRM:"$pth"mask.grd" >> tmp_masklist
  end 

  set pth = `awk -F: 'NR==1 {print $1}' $1`
  set stem = `awk -F: 'NR==1 {print $2}' $1 | awk -F"." '{print $1}'`
  #echo $pth $stem

  ## since ALOS2 has 5 subswaths, need to use merge_swath twice
  echo ""
  echo "Merging START"
  head -3 tmp_phaselist > first_phase.txt
  head -3 tmp_corrlist > first_corr.txt
  head -3 tmp_masklist > first_mask.txt
  merge_swath first_phase.txt first_phase.grd first
  merge_swath first_corr.txt first_corr.grd
  merge_swath first_mask.txt first_mask.grd

  # echo "first.PRM:first_phase.grd" > second_phase.txt
  # tail -2 tmp_phaselist >> second_phase.txt
  # echo "first.PRM:first_corr.grd" > second_corr.txt
  # tail -2 tmp_corrlist >> second_corr.txt
  # echo "first.PRM:first_mask.grd" > second_mask.txt
  # tail -2 tmp_masklist >> second_mask.txt

  # used for Pamir region (merge 4 subswaths)
  echo "first.PRM:first_phase.grd" > second_phase.txt
  tail -1 tmp_phaselist >> second_phase.txt
  echo "first.PRM:first_corr.grd" > second_corr.txt
  tail -1 tmp_corrlist >> second_corr.txt
  echo "first.PRM:first_mask.grd" > second_mask.txt
  tail -1 tmp_masklist >> second_mask.txt

  merge_swath second_phase.txt phasefilt.grd $stem
  merge_swath second_corr.txt corr.grd
  merge_swath second_mask.txt mask.grd
  echo "Merging END"
  echo ""
  rm first* second*

#  set iono = `grep correct_iono $2 | awk '{print $3}'`
#  set skip_iono = `grep iono_skip_est $2 | awk '{print $3}'`
#  if ($iono != 0 & $skip_iono == 0) then
#    if (! -f ph_iono_orig.grd) then
#      echo "Need ph_iono_orig.grd to correct ionosphere ..."
#    else
#      echo "Correcting ionosphere ..."
#      gmt grdsample ph_iono_orig.grd -Rphasefilt.grd -Gtmp.grd
#      gmt grdmath phasefilt.grd tmp.grd SUB PI ADD 2 PI MUL MOD PI SUB = tmp2.grd
#      mv phasefilt.grd phasefilt_orig.grd
#      mv tmp2.grd phasefilt.grd
#      rm tmp.grd
#    endif
#  endif

  
  # This step is essential, cut the DEM so it can run faster.
  if (! -f trans.dat) then
    set led = `grep led_file $pth$stem".PRM" | awk '{print $3}'`
    cp $pth$led .
    echo "Recomputing the projection LUT..."
  # Need to compute the geocoding matrix with supermaster.PRM with rshift set to 0
    set rshift = `grep rshift $stem".PRM" | tail -1 | awk '{print $3}'`
    update_PRM $stem".PRM" rshift 0
    gmt grd2xyz --FORMAT_FLOAT_OUT=%lf dem.grd -s | SAT_llt2rat $stem".PRM" 1 -bod > trans.dat
  # Set rshift back for other usage
    update_PRM $stem".PRM" rshift $rshift
  endif

  # Read in parameters
  set threshold_snaphu = `grep threshold_snaphu $2 | awk '{print $3}'`
  set threshold_geocode = `grep threshold_geocode $2 | awk '{print $3}'`
  set region_cut = `grep region_cut $2 | awk '{print $3}'`
  set switch_land = `grep switch_land $2 | awk '{print $3}'`
  set defomax = `grep defomax $2 | awk '{print $3}'`
  set near_interp = `grep near_interp $2 | awk '{print $3}'`

  # Unwrapping
  if ($region_cut == "") then
    set region_cut = `gmt grdinfo phasefilt.grd -I- | cut -c3-20`
  endif
  if ($threshold_snaphu != 0 ) then
    if ($switch_land == 1) then
      if (! -f landmask_ra.grd) then
        landmask.csh $region_cut
      endif
    endif

    echo ""
    echo "SNAPHU.CSH - START"
    echo "threshold_snaphu: $threshold_snaphu"
    if ($near_interp == 1) then
      snaphu_interp.csh $threshold_snaphu $defomax $region_cut
    else
      snaphu.csh $threshold_snaphu $defomax $region_cut
    endif
    echo "SNAPHU.CSH - END"
  else
    echo ""
    echo "SKIP UNWRAP PHASE"
  endif

  # Geocoding 
  #if (-f raln.grd) rm raln.grd
  #if (-f ralt.grd) rm ralt.grd
 
  if ($threshold_geocode != 0) then
    echo ""
    echo "GEOCODE-START"
    proj_ra2ll.csh trans.dat phasefilt.grd phasefilt_ll.grd
    proj_ra2ll.csh trans.dat corr.grd corr_ll.grd
    gmt makecpt -Crainbow -T-3.15/3.15/0.05 -Z > phase.cpt
    set BT = `gmt grdinfo -C corr.grd | awk '{print $7}'`
    gmt makecpt -Cgray -T0/$BT/0.05 -Z > corr.cpt
    grd2kml.csh phasefilt_ll phase.cpt
    grd2kml.csh corr_ll corr.cpt

    if (-f unwrap.grd) then
      gmt grdmath unwrap.grd mask.grd MUL = unwrap_mask.grd
      proj_ra2ll.csh trans.dat unwrap.grd unwrap_ll.grd
      proj_ra2ll.csh trans.dat unwrap_mask.grd unwrap_mask_ll.grd
      set BT = `gmt grdinfo -C unwrap.grd | awk '{print $7}'`
      set BL = `gmt grdinfo -C unwrap.grd | awk '{print $6}'`
      gmt makecpt -T$BL/$BT/0.5 -Z > unwrap.cpt
      grd2kml.csh unwrap_mask_ll unwrap.cpt
      grd2kml.csh unwrap_ll unwrap.cpt
    endif
    
    echo "GEOCODE END"
  endif 

  rm tmp_phaselist tmp_corrlist tmp_masklist *.eps *.bb
