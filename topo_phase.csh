#!/bin/csh -f

  if ($#argv != 4 && $#argv != 6) then
errormessage:
    echo ""
    echo "Usage: topo_phase.csh master.PRM slave.PRM filter decimation [rng_dec azi_dec]"
    echo ""
    echo " Apply gaussian filter to amplitude and phase images."
    echo " "
    echo " filter -  wavelength of the filter in meters (0.5 gain)"
    echo " decimation - (1) better resolution, (2) smaller files"
    echo " "
    echo "Example: topo_phase.csh IMG-HH-ALPSRP055750660-H1.0__A.PRM IMG-HH-ALPSRP049040660-H1.0__A.PRM 300  2"
    echo ""
    exit 1
  endif
  echo "topo_phase.csh"

#
# define filter and decimation variables
#

  set sharedir = `gmtsar_sharedir.csh`
  set filter3 = $sharedir/filters/fill.3x3
  set filter4 = $sharedir/filters/xdir
  set filter5 = $sharedir/filters/ydir
  set dec  = $4
  set az_lks = 4
  set PRF = `grep PRF *.PRM | awk 'NR == 1 {printf("%d", $3)}'`
  if( $PRF < 1000 ) then
     set az_lks = 1
  endif
#
# look for range sampling rate
#
  set rng_samp_rate = `grep rng_samp_rate $1 | awk 'NR == 1 {printf("%d", $3)}'`
#
# set the range spacing in units of image range pixel size
#
  if ($?rng_samp_rate) then
    if ($rng_samp_rate > 110000000) then
      set dec_rng = 4
      set filter1 = $sharedir/filters/gauss15x5
    else if ($rng_samp_rate < 110000000 && $rng_samp_rate > 20000000) then
      set dec_rng = 2
      set filter1 = $sharedir/filters/gauss15x5
#
# special for TOPS mode
#
      if($az_lks == 1) then
        set filter1 = $sharedir/filters/gauss5x5
      endif
    else
      set dec_rng = 1
      set filter1 = $sharedir/filters/gauss15x3
    endif
  else
    echo "Undefined rng_samp_rate in the master PRM file"
    exit 1
  endif
#
# set az_lks and dec_rng to 1 for odd decimation
#
  if($#argv == 6) then
    set jud = `echo $6 | awk '{if($1%2 == 0) print 1;else print 0}'`
    if ($jud == 0) then
      set az_lks = 1
    endif
    set jud = `echo $5 | awk '{if($1%2 == 0) print 1;else print 0}'`
    if ($jud == 0) then
      set dec_rng = 1
    endif
  endif
#
#  make the custom filter2 and set the decimation
#
  make_gaussian_filter $1 $dec_rng $az_lks $3 > ijdec
  set filter2 = gauss_$3
  set idec = `cat ijdec | awk -v dc="$dec" '{ print dc*$1 }'`
  set jdec = `cat ijdec | awk -v dc="$dec" '{ print dc*$2 }'`
  if($#argv == 6) then
    set idec = `echo $6 $az_lks | awk '{printf("%d",$1/$2)}'`
    set jdec = `echo $5 $dec_rng | awk '{printf("%d",$1/$2)}'`
    echo "setting range_dec = $5, azimuth_dec = $6"
  endif
  echo "$filter2 $idec $jdec ($az_lks $dec_rng)"
#
# make topographic phase by phasediff_topo
#

# which satellite
# add baseline information
#
  set SC = `grep SC_identity $1 | awk '{print $3}'`
  if ($SC == 1 || $SC == 2 || $SC == 4 || $SC == 6 || $SC == 5) then
     SAT_baseline $1 $2 | tail -n9 >> $2
  else if ($SC > 6) then
     SAT_baseline $1 $2 | tail -n9 >> $2
  else
     echo "Incorrect satellite id in prm file"
     exit 0   
  endif

  # update the command to calculate topo phase
  phasediff_get_topo_phase  $1  $2  -topo  topo_ra.grd  # generate real.grd
  conv $az_lks $dec_rng $filter1 real.grd=bf topo.grd=bf
  conv $idec $jdec $filter2 topo.grd=bf topo_filt.grd

  rm -f topo.grd imag.grd  # imag.grd are all zeros
