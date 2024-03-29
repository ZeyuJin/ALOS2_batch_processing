# ALOS2_batch_processing
**This repo is used to process ALOS-2 time-series interferograms.**

**Note: some scripts could be found in $YOURPATH/GMTSAR/bin** 

---

### Step 0: add current cshell path to `~/.bashrc` or `~/.cshrc`.

### Step 1: convert the original data (CEOS format) to SLC and LED formats:
```shell
preproc_ALOS2_batch_new.csh  LED.list  batch.config  [n1]  [n2]
# n1 and n2 represent the number of ALOS-2 subswath, n2 >= n1
# LED.list should be located in the raw/ directory
```

### Step 2: align all slave images to the supermaster image.
```shell
# first need to make empty directories from F(n1) to F(n2)

align_ALOS2_swath_new.csh  align.in  n_swath  batch.config
# the first line of align.in represents the supermaster file
# n_swath represents the number of ALOS-2 subswath
# unlike Sentinel-1 data, the master date of ALOS-2 data is 
# defined as last 6 digits of yyyymmdd
```
**In order to merge each subswath using the "merge_batch.csh" later on,
we upsample each SLC file to enforce each subswath to have the same
range sampling rate and PRF (azimuth) (using "samp_slc.csh").**


### Step 3: generate "topo_ra.grd" and "trans.dat" for each subswath.
``` shell
dem2topo_ra_swath.csh  n_swath  batch.config
```

### Step 4: make pairs of interferograms between any two pairs.
```shell
intf_ALOS2_batch_firkin.csh  intf.in  batch.config  start_swath  end_swath  Ncores
# intf_ALOS2_batch_new.csh maps all processes to multiple CPUs across multiple nodes.
# It's better to use intf_ALOS2_batch_new.csh on the supercomputer that has multiple nodes
```
Because ALOS-2 has a better orbit precision and alignment than ALOS-1, we could construct any 
interferograms between the reference and repeat date of data acquisitions. The phase closure 
could be as small as zero.

### Step 5: merge the filtered phase, correlation and mask grid files
```shell
merge_swath_ALOS2_list.csh  dir.list  dates.run  batch.config
# this command generate the necessary file list that will be used in merge_batch.csh
# dir.list in the form of directory of each subswath:
# ../F1/intf
# ../F2/intf
# ../F3/intf
# ...
# dates.run are date pairs between reference and repeat interferograms.

merge_batch_five.csh  inputfile  batch.config
# input file is generated from executing merge_swath_ALOS2_list.csh
# the merging step would also generate merged "trans.dat" to be used in geocoding.
```
**Merging subswaths of ALOS-2 is similar to merging those of Sentinel-1.
You need to run "merge_swath" twice. To merge the topo_ra.grd, you need to
consider two extra factors:**
1. gmt FLIPUD each topo_ra.grd of each subswath (Because SLC indexs from upper left).
2. subtract the difference of Earth radius of each subswath.

### Step 6: unwrap each interferogram and geocode them.
```shell
unwrap_parallel.csh  dates.run  threshold  Ncores
# threshold means the coherence threshold of SNAPHU unwrapping 

geocode_batch.csh dates.run resolution grdfiles corr_threshold [Ncores]
# grdfiles saves the stem names of each product: unwrap/phasefilt
# resolution is set to the same resolution of DEM
```
