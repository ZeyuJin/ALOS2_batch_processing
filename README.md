# ALOS2_batch_processing
This repo is used to process ALOS-2 time-series interferograms.

Step 0: add current cshell path to `~/.bashrc` or `~/.cshrc`.

Step 1: convert the original data (CEOS format) to SLC and LED formats:
```shell
preprocess_alos2_batch.csh  LED.list  batch.config  [n1]  [n2]
# n1 and n2 represent the number of ALOS-2 subswath, n2 >= n1
```

Step 2: align all slave images to the supermaster image.
```shell
align_ALOS2_swath.csh  align.in  n_swath  batch.config
# the first line of align.in represents the supermaster file
# n_swath represents the number of ALOS-2 subswath
```
**In order to merge each subswath using the merge_batch.csh later on,
we upsample each SLC file to enforce each subswath to have the same
range sampling rate and PRF (azimuth) (using samp_slc.csh).**

<!-- *italic* 

## subtitle
---
![image name](image.jpg)
[url title](url)-->

Step 3: make pairs of interferograms between any two pairs.
```shell
intf_ALOS2_batch_new.csh  intf.in  batch.config  start_swath  end_swath  Ncores
```
Because ALOS-2 has a better orbit precision than ALOS-1, we could construct any 
interferograms between the reference and repeat date of data acquisitions.
