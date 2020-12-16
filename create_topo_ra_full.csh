#!/usr/bin/csh -f
# written by Xiaohua (Eric) Xu to merge topo_ra.grd
# from three subswaths, work both for Sentinel and ALOS2
# if needed for five subswaths, use merge_swath twice

cp ../../F1/topo/master.PRM ./t1.PRM
cp ../../F2/topo/master.PRM ./t2.PRM
cp ../../F3/topo/master.PRM ./t3.PRM

set r1 = `grep earth_radius t1.PRM | awk '{print $3}'`
set r2 = `grep earth_radius t2.PRM | awk '{print $3}'`
set r3 = `grep earth_radius t3.PRM | awk '{print $3}'`

echo "computing difference between reference earth radius ..."
set d1 = `echo $r1 $r2 | awk '{printf("%.6f",$1-$2)}'`
set d2 = `echo $r1 $r3 | awk '{printf("%.6f",$1-$2)}'`

echo "copying original toop_ra.grd-s and make adjustment ..."
gmt grdmath ../../F1/topo/topo_ra.grd FLIPUD = t1.grd
gmt grdmath ../../F2/topo/topo_ra.grd $d1 SUB FLIPUD = t2.grd
gmt grdmath ../../F3/topo/topo_ra.grd $d2 SUB FLIPUD = t3.grd

echo "t1.PRM:t1.grd" > topolist
echo "t2.PRM:t2.grd" >> topolist
echo "t3.PRM:t3.grd" >> topolist

merge_swath topolist topo_ra.grd

