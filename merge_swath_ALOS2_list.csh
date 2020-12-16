#!/usr/bin/tcsh -f
# modified by Zeyu Jin on Jan. 2019
# used to merge swath of ALOS2
# solved the order of pairs (first line should be supermaster)
# for each band of merged grid on 3rd. April, 2019
#

if ($#argv != 3) then
  echo "merge_swath_ALOS2_list.csh  dir.list  dates.run  batch.config"
  exit 
endif

set dir_in = `cat $1`
set F_list = `cat $1|awk -F"/" '{print $2}'`
set Nswath = `echo $#F_list`
echo "Number of swaths to merge: " $Nswath "[" $F_list "]"

set iono = `grep correct_iono $3 | awk '{print $3}'`
set master_date = `grep master_date $3 | awk '{print $3}'`
echo "Super master is: " $master_date
set master_intf = ""

foreach this_date (`cat $2`)
   set date1 = `echo $this_date|cut -c 1-8`
   set date2 = `echo $this_date|cut -c 10-17`

   if ($date1 == $master_date) then
     set master_intf = $this_date
     echo "Found  $master_intf connectting the super master "
     set slave_date = `echo $master_intf|awk -F"_" '{print $2}'`
     break
   endif
end

if ("x"$master_intf == "x") then
  echo "*** NO interferogram connects to the super master..."
  exit 1
endif


rm -f input.list
rm -f high_band.list
rm -f low_band.list
rm -f mid_band.list

set dir_all = `cat $1`
foreach this_intf (`cat $2`)  # date of pair
   set master_date = `echo $this_intf|awk -F"_" '{print $1}'`
   set slave_date = `echo $this_intf|awk -F"_" '{print $2}'`
   
   # change to ALOS2 PRM format in each subswath
   set string = ""
   set str_h = ""
   set str_l = ""
   set str_o = ""
   set curr_dir = `pwd`
   @ num = 1
   foreach F_tmp ($F_list)
   # F_list could range from F1 to F5 (Usually Sentinel has 3, while ALOS-2 has 5)
     if ($num <= $Nswath) then
        set this_dir = `echo $dir_all[$num]`
	cd $this_dir"/"$this_intf
	set master_pattern = `echo $master_date | awk '{print substr($0,3)}'`
	set slave_pattern = `echo $slave_date | awk '{print substr($0,3)}'`
	set master_prm = *"-$master_pattern-"*.PRM
	set slave_prm = *"-$slave_pattern-"*.PRM
	cd $curr_dir
        set string = $string","$this_dir"/"$this_intf"/:"$master_prm":"$slave_prm  # path of general interferogram
    
        if ($iono == 1) then
           set str_h = $str_h",../../"$F_tmp"/iono_phase/intf_h/"$this_intf"/:"$master_prm":"$slave_prm  # high band
           set str_l = $str_l",../../"$F_tmp"/iono_phase/intf_l/"$this_intf"/:"$master_prm":"$slave_prm  # low  band
           set str_o = $str_o",../../"$F_tmp"/iono_phase/intf_o/"$this_intf"/:"$master_prm":"$slave_prm  # mid  band
        endif
     endif
     @ num = $num + 1
   end

   echo $string | cut -c 2- >> input.list     # remove the comma at the beginning
   echo $str_h  | cut -c 2- >> high_band.list
   echo $str_l  | cut -c 2- >> low_band.list
   echo $str_o  | cut -c 2- >> mid_band.list
end

set line_master = `grep $date1 input.list | grep $date2`
echo "The first line should be: " $line_master
grep $line_master input.list > input.list.new
grep -v $line_master input.list >> input.list.new
rm -f input.list

# the first pair must contain the supermaster PRM
# in order to update the first_sample and rshift information
# to compute the right near_range to merge swaths
if ($iono == 1) then
   mkdir -p intf_h
   cd intf_h
   mv ../high_band.list .
   grep $master_intf high_band.list > tmp
   grep -v $master_intf high_band.list >> tmp
   mv tmp high_band.list
   cd ..
   
   mkdir -p intf_l
   cd intf_l
   mv ../low_band.list .
   grep $master_intf low_band.list > tmp
   grep -v $master_intf low_band.list >> tmp
   mv tmp low_band.list
   cd ..
   
   mkdir -p intf_o
   cd intf_o
   mv ../mid_band.list .
   grep $master_intf mid_band.list > tmp
   grep -v $master_intf mid_band.list >> tmp
   mv tmp mid_band.list 
   cd ..
endif
