#!/bin/tcsh -f
# Modified by Zeyu Jin on Jan. 2019

if ($#argv != 4) then
    echo ""
    echo "Usage: intf_ALOS2_p2p_new.csh IMG-HH-ALOS2059163050-150628-WBDR1.1__D IMG-HH-ALOS2129543050-161016-WBDR1.1__D  batch_intf.config swath"
    echo ""
    exit 1
endif


if (! -f $3) then
  echo "no config file: "$3
  exit 1
endif

set swath = $4
set ref = $1"-F"$swath
set rep = $2"-F"$swath

# set stem1 = `echo $1|cut -c 4-`
# set stem2 = `echo $2|cut -c 4-`
# set led1 = $ref.LED
# set led2 = $rep.LED

set filter = `grep filter_wavelength $3 | awk '{print $3}'`
if ( "x$filter" == "x" ) then
   set filter = 200
   echo " "
   echo "WARNING filter wavelength was not set in config.txt file"
   echo "        please specify wavelength (e.g., filter_wavelength = 200)"
   echo "        remove filter1 = gauss_alos_200m"
endif

set dec = `grep dec_factor $3 | awk '{print $3}'`
set topo_phase = `grep topo_phase $3 | awk '{print $3}'`
set shift_topo = `grep shift_topo $3 | awk '{print $3}'`
set threshold_snaphu = `grep threshold_snaphu $3 | awk '{print $3}'`
set threshold_geocode = `grep threshold_geocode $3 | awk '{print $3}'`
set region_cut = `grep region_cut $3 | awk '{print $3}'`
set switch_land = `grep switch_land $3 | awk '{print $3}'`
set defomax = `grep defomax $3 | awk '{print $3}'`
set range_dec = `grep range_dec $3|awk '{print $3}'`
set azimuth_dec = `grep azimuth_dec $3|awk '{print $3}'`
set iono = `grep correct_iono $3 | awk '{print $3}'`
set iono_dsamp = `grep iono_dsamp $3 | awk '{print $3}'`

set str1 = `grep SC_clock_start "F$swath"/SLC/$ref".PRM" | awk '{printf("%d",int($3))}' `
set str2 = `grep SC_clock_start "F$swath"/SLC/$rep".PRM" | awk '{printf("%d",int($3))}'`
set ref_id = `day2date.csh $str1`
set rep_id = `day2date.csh $str2`

# start from making and filtering the interferogram
    cd F$swath
    mkdir -p intf
#    Stale file handle (delete the intf/ but parallel processing others)
#    cleanup.csh intf  
    echo ""
    echo "INTF.CSH, FILTER.CSH - START"
    cd intf
    mkdir $ref_id"_"$rep_id
    cd $ref_id"_"$rep_id
    ln -s ../../../raw/$ref.LED .
    ln -s ../../../raw/$rep.LED .
    ln -s ../../SLC/$ref.SLC .
    ln -s ../../SLC/$rep.SLC .
    cp ../../SLC/$ref.PRM .
    cp ../../SLC/$rep.PRM .

    if($topo_phase == 1) then
      if ($shift_topo == 1) then
         ln -s ../../topo/topo_shift.grd .
         intf.csh $ref.PRM $rep.PRM -topo topo_shift.grd
         filter.csh $ref.PRM $rep.PRM $filter $dec $range_dec $azimuth_dec
##         filter.csh $ref.PRM $rep.PRM $filter $dec
      else
         ln -s ../../topo/topo_ra.grd .
         intf.csh $ref.PRM $rep.PRM -topo topo_ra.grd
         filter.csh $ref.PRM $rep.PRM $filter $dec $range_dec $azimuth_dec
##         filter.csh $ref.PRM $rep.PRM $filter $dec
      endif
    else
       echo "NO TOPOGRAPHIC PHASE REMOVAL PORFORMED"
       intf.csh $ref.PRM $rep.PRM
       filter.csh $ref.PRM $rep.PRM $filter $dec $range_dec $azimuth_dec
##       filter.csh $ref.PRM $rep.PRM $filter $dec
    endif
    cd ../..
    echo "INTF.CSH, FILTER.CSH - END"

    if ($iono == 1) then
       mkdir -p iono_phase
       cd iono_phase
       mkdir -p intf_o intf_h intf_l
       
      set new_incx = `echo $range_dec $iono_dsamp | awk '{print $1*$2}'`
      set new_incy = `echo $azimuth_dec $iono_dsamp | awk '{print $1*$2}'`
      
      echo ""
      cd intf_h
      mkdir -p $ref_id"_"$rep_id 
      cd $ref_id"_"$rep_id
      ln -sf ../../../SLC_H/$ref.SLC .
      ln -sf ../../../SLC_H/$rep.SLC .
      ln -sf ../../../SLC_H/$ref.LED .
      ln -sf ../../../SLC_H/$rep.LED .
      cp ../../../SLC_H/$ref.PRM .
      cp ../../../SLC_H/$rep.PRM .
      # sed "s/.*wavelength.*/radar_wavelength    = 0.242452/g" $ref.PRM > tmp1
      # sed "s/.*wavelength.*/radar_wavelength    = 0.242452/g" $rep.PRM > tmp2
      # mv tmp1 $ref.PRM
      # mv tmp2 $rep.PRM
      cp ../../../SLC/params* .
      ln -sf ../../../topo/topo_ra.grd .    ## added by Zeyu Jin
      intf.csh $ref.PRM $rep.PRM -topo topo_ra.grd
      filter.csh $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      cp phase.grd phasefilt.grd
      echo ""
      echo "Generate the topo phase (high band)"
      topo_phase.csh $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      cd ../..
      
      echo ""
      cd intf_l
      mkdir -p $ref_id"_"$rep_id
      cd $ref_id"_"$rep_id
      ln -sf ../../../SLC_L/$ref.SLC .
      ln -sf ../../../SLC_L/$rep.SLC .
      ln -sf ../../../SLC_L/$ref.LED .
      ln -sf ../../../SLC_L/$rep.LED .
      cp ../../../SLC_L/$ref.PRM .
      cp ../../../SLC_L/$rep.PRM .
      # sed "s/.*wavelength.*/radar_wavelength    = 0.242452/g" $ref.PRM > tmp1
      # sed "s/.*wavelength.*/radar_wavelength    = 0.242452/g" $rep.PRM > tmp2
      # mv tmp1 $ref.PRM
      # mv tmp2 $rep.PRM
      cp ../../../SLC/params* .
      ln -sf ../../../topo/topo_ra.grd .   
      intf.csh $ref.PRM $rep.PRM -topo topo_ra.grd
      filter.csh $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      cp phase.grd phasefilt.grd
      echo ""
      echo "Generate the topo phase (low band)"
      topo_phase.csh $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      cd ../..

      echo ""
      cd intf_o
      mkdir -p $ref_id"_"$rep_id
      cd $ref_id"_"$rep_id
      ln -sf ../../../SLC/$ref.SLC .
      ln -sf ../../../SLC/$rep.SLC .
      ln -sf ../../../SLC/$ref.LED .
      ln -sf ../../../SLC/$rep.LED .
      cp ../../../SLC/$ref.PRM .
      cp ../../../SLC/$rep.PRM .
      ln -sf ../../../topo/topo_ra.grd .
      intf.csh $ref.PRM $rep.PRM -topo topo_ra.grd
      filter.csh $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      cp phase.grd phasefilt.grd
      echo ""
      echo "Generate the topo phase (central band)"
      topo_phase.csh $ref.PRM $rep.PRM 500 $dec $new_incx $new_incy
      cd ../..
    endif

# start unwrap and geocode
    if ($threshold_snaphu != 0) then
	#  cd intf/$ref_id"_"$rep_id
	#  if ((! $?region_cut) || ($region_cut == "")) then
	#	 set region_cut = `gmt grdinfo phase.grd -I- | cut -c3-20`
	#  endif
      
      # apply landmask in /topo of each subswath 
      if ($switch_land == 1) then
         cd topo
         if (! -f landmask_ra.grd) then
           landmask.csh $region_cut
         endif
         cd ../intf
         cd $ref_id"_"$rep_id
         ln -sf ../../topo/landmask_ra.grd .
      endif

      echo ""
      echo "SNAPHU.CSH - START"
      echo "threshold_snaphu: $threshold_snaphu"
      snaphu.csh $threshold_snaphu $defomax $region_cut
      echo "SNAPHU.CSH - END"
      cd ../..

    else
      echo ""
      echo "SKIP UNWRAP PHASE"
    endif

    echo " "
    if ($threshold_geocode != 0) then
       echo "GEOCODE.CSH - START"
       cd intf/
       cd $ref_id"_"$rep_id
       rm -f raln.grd ralt.grd
       rm -f trans.dat
       ln -sf ../../topo/trans.dat .
       echo "threshold_geocode: $threshold_geocode"
       geocode.csh $threshold_geocode
       echo "GEOCODE.CSH - END"
       cd ../../  
    else
       echo "topo_ra is needed to geocode"
       exit 1
    endif
cd ../..    # return to the top directory
echo "That's all folks ..."
