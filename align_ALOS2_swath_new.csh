#!/bin/tcsh -f
# modified by Zeyu Jin on Jan. 2019
# align all the slave image to the supermaster
# due to the precise orbit, all the interferograms
# could be generated with the reference and repeat images

if ($#argv != 3) then
  echo ""
  echo "align_ALOS2_swath.csh  align.in  n_swath  config.alos.txt"
  echo "The first line of align.in is the supermaster"
  echo "IMG-HH-ALOS2129992850-161019-WBDR1.1__D"
  echo "..."
  echo ""
  exit 1
endif

set align_list = $1
set subswath = $2
set conf = $3
set iono = `grep correct_iono $conf | awk '{print $3}'`
cd F$subswath
cp ../$align_list .

mkdir -p intf SLC
if ($iono == 1) then
   mkdir -p SLC_L
   mkdir -p SLC_H
endif
cleanup.csh SLC
rm -rf SLC_L/*
rm -rf SLC_H/*

echo ""
echo "Alignment started on "`date`
echo ""

set master = `awk 'NR==1 {print $0}' $align_list`
set master = $master-F$subswath
cd SLC
cp ../../raw/$master.PRM .
ln -sf ../../raw/$master.SLC .
ln -sf ../../raw/$master.LED .
# upsampling is the key
samp_slc.csh $master 3350 0
if ($iono == 1) then
   split_spectrum $master.PRM > params1
   mv SLCH ../SLC_H/$master.SLC
   mv SLCL ../SLC_L/$master.SLC
endif

cd ../SLC_L
set wl1 = `grep low_wavelength ../SLC/params1 | awk '{print $3}'`
cp ../SLC/$master.PRM .
ln -s ../../raw/$master.LED .
sed "s/.*wavelength.*/radar_wavelength    = $wl1/g" $master.PRM > tmp
mv tmp $master.PRM

cd ../SLC_H
set wh1 = `grep high_wavelength ../SLC/params1 | awk '{print $3}'`
cp ../SLC/$master.PRM .
ln -s ../../raw/$master.LED .
sed "s/.*wavelength.*/radar_wavelength    = $wh1/g" $master.PRM > tmp
mv tmp $master.PRM

cd ..

# coregister all images to one supermaster
# sample to the same PRF
foreach slave (`awk 'NR>1 {print $0}' $align_list`)
   if ($slave != "" && $master != "") then
      echo " "
      echo "subswath: $subswath"
      set slave = $slave-F$subswath
      echo "Align $slave to $master - START"
      cd SLC
      cp ../../raw/$slave.PRM .
      ln -sf ../../raw/$slave.SLC .
      ln -sf ../../raw/$slave.LED .
      samp_slc.csh $slave 3350 0

      if ($iono == 1) then
         split_spectrum $slave.PRM > params2
         mv SLCH ../SLC_H/$slave.SLC
         mv SLCL ../SLC_L/$slave.SLC

         cd ../SLC_L
         set wl2 = `grep low_wavelength ../SLC/params2 | awk '{print $3}'`
         cp ../SLC/$slave.PRM .
         ln -s ../../raw/$slave.LED .
         sed "s/.*wavelength.*/radar_wavelength    = $wl2/g" $slave.PRM > tmp
         mv tmp $slave.PRM

         cd ../SLC_H
         set wh2 = `grep high_wavelength ../SLC/params2 | awk '{print $3}'`
         cp ../SLC/$slave.PRM .
         ln -s ../../raw/$slave.LED .
         sed "s/.*wavelength.*/radar_wavelength    = $wh2/g" $slave.PRM > tmp
         mv tmp $slave.PRM

         cd ../SLC
      endif
      
      # # check the range sampling rate
      # # if images do not match, convert the FBD image to FBS
      # set rng_samp_rate_m = `grep rng_samp_rate $master.PRM | awk 'NR == 1 {printf("%d",$3)}'`
      # set rng_samp_rate_s = `grep rng_samp_rate $slave.PRM | awk 'NR == 1 {printf("%d",$3)}'`
      # set t = `echo $rng_samp_rate_m $rng_samp_rate_s | awk '{printf("%1.1f\n",$1/$2)}'`
      # if ($t == 1.0) then
      #    echo "The range sampling rate for master and slave images are: "$rng_samp_rate_m
      # else if ($t == 2.0) then
      #    echo "Convert the slave image from FBD to FBS mode"
      #    ALOS_fbd2fbs_SLC $slave.PRM $slave"_FBS.PRM"
      #    echo "Overwriting the old slave image"
      #    mv $slave"_FBS.PRM" $slave.PRM
      #    update_PRM.csh $slave.PRM input_file $slave.SLC
      #    mv $slave"_FBS.SLC" $slave.SLC
      # else if ($t == 0.5) then
      #    echo "Convert the master image from FBD to FBS mode"
      #    ALOS_fbd2fbs_SLC $master.PRM $master"_FBS.PRM"
      #    echo "Overwriting the old master image"
      #    mv $master"_FBS.PRM" $master.PRM
      #    update_PRM.csh $master.PRM input_file $master.SLC
      #    mv $master"_FBS.SLC" $master.SLC
      # else
      #    echo "The range sampling rate for master and slave images are not convertable!"
      #    exit 1
      # endif

      # put in the alignment parameters
      cp $slave.PRM $slave.PRM0 
      SAT_baseline $master.PRM $slave.PRM0 >> $slave.PRM
      xcorr $master.PRM $slave.PRM -xsearch 32 -ysearch 256 -nx 32 -ny 128
      awk '{print $4}' < freq_xcorr.dat > tmp.dat
      set amedian = `sort -n tmp.dat | awk ' { a[i++]=$1; } END { print a[int(i/2)]; }'`
      set amax = `echo $amedian | awk '{print $1+3}'`
      set amin = `echo $amedian | awk '{print $1-3}'`
      awk '{if($4 > '$amin' && $4 < '$amax') print $0}' < freq_xcorr.dat > freq_alos2.dat
      fitoffset.csh 2 3 freq_alos2.dat 10 >> $slave.PRM
      mv freq_xcorr.dat "xcorr_"$master"_"$slave.dat0
      # refocus the second image
      echo "resamp slave"
      resamp $master.PRM $slave.PRM $slave.PRMresamp $slave.SLCresamp 4
      rm $slave.SLC
      mv $slave.SLCresamp $slave.SLC
      mv $slave.PRMresamp $slave.PRM

      if ($iono == 1) then
         cd ../SLC_L
         cp $slave.PRM $slave.PRM0
         ln -sf ../SLC/freq_alos2.dat .
         fitoffset.csh 2 3 freq_alos2.dat 10 >> $slave.PRM
         resamp $master.PRM $slave.PRM $slave.PRMresamp $slave.SLCresamp 4
         rm $slave.SLC
         mv $slave.SLCresamp $slave.SLC
         mv $slave.PRMresamp $slave.PRM
         rm -f freq_alos2.dat

         cd ../SLC_H
         cp $slave.PRM $slave.PRM0
         ln -sf ../SLC/freq_alos2.dat .
         fitoffset.csh 2 3 freq_alos2.dat 10 >> $slave.PRM
         resamp $master.PRM $slave.PRM $slave.PRMresamp $slave.SLCresamp 4
         rm $slave.SLC
         mv $slave.SLCresamp $slave.SLC
         mv $slave.PRMresamp $slave.PRM
         rm -f freq_alos2.dat

         cd ../SLC
         rm -f freq_alos2.dat
      endif

      cd ..
      echo "Align $slave to $master - END"
   else
      echo ""
      echo "Wrong format in align.in"
      exit 1
   endif
end

rm -f $align_list
cd ..
echo "Alignment finished on "`date`
