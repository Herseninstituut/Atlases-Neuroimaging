#!/bin/bash

# bd=/Users/luser/GoogleDrive/data/atlases/Schaefer100_Thalamus_Striatum
bd=`pwd`
segdir=${bd}/fastMNI
cd ${bd}

# Remove previous versions
rm Schaefer100_ribbon_subcort_*.nii.gz

# Carry out the segmentation
echo Carrying out segmentation of the MNI 2mm template
echo
fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -g \
    -o ${segdir}/MNI152_T1_2mm_brain \
       ${segdir}/MNI152_T1_2mm_brain


# Give proper names to the segmented volumes
mv ${segdir}/MNI152_T1_2mm_brain_seg_0.nii.gz ${segdir}/CSF_seg.nii.gz
mv ${segdir}/MNI152_T1_2mm_brain_seg_1.nii.gz ${segdir}/GM_seg.nii.gz
mv ${segdir}/MNI152_T1_2mm_brain_seg_2.nii.gz ${segdir}/WM_seg.nii.gz


# Create ribbon - a box of 8mm instead of the default kernel 3D is necessary
# to get comprehensive sampling of regions where the default method would
# discard any grey matter voxel. Try e.g. to inspect the insula if
# the -kernel 3D option is chosen instead of -kernel box 8
fslmaths ${segdir}/WM_seg.nii.gz -kernel box 8 -dilD -mul ${segdir}/GM_seg ${segdir}/ribbon


# Prepare CSF termination mask
fslmaths ${segdir}/CSF_seg \
         -add ${segdir}/GM_seg \
         -bin \
         -sub ${segdir}/ribbon \
         ${segdir}/CSF_termination


# Select ribbon voxels in the Schaefer100 atlas
fslmaths Schaefer100 -mul ${segdir}/ribbon Schaefer100_ribbon


# Separate left from right and subtract 50 to the RH
# to have RH and LH atlases both with labels from 1..50
fslmaths Schaefer100_ribbon -roi 45 45 0 109 0 91 0 1 \
         Schaefer100_ribbon_LH
         
fslmaths Schaefer100_ribbon -roi  0 45 0 109 0 91 0 1 \
         -sub 50 -thr 0 \
         Schaefer100_ribbon_RH


# Create Ribbon, Striatum, Thalamus and HO_Subcortical (i.e. Amygdala
# and Hippocampus) mask for the tests below
fslmaths Schaefer100_ribbon -bin Schaefer100_ribbon_mask

fslmaths Thalamus-maxprob-thr25-2mm -add 0 Thalamus
fslmaths Thalamus -bin Thalamus_mask

fslmaths striatum-con-label-thr50-7sub-2mm -add 0 Striatum
fslmaths Striatum -bin Striatum_mask

fslmaths HarvardOxford-sub-maxprob-thr50-2mm -add 0 HO_Subcortical
fslmaths HO_Subcortical -bin HO_Subcortical_mask


# No voxels are shared between Thalamus and ribbon.
# Some voxels (N=4) are assigned both to the striatum and to the ribbon, but
# they likely belong to the cortical ribbon. Remove them from the Striatum.
fslmaths Schaefer100_ribbon -bin Schaefer100_ribbon_mask

fslmaths Schaefer100_ribbon_mask \
         -mul Striatum_mask -sub 1 -mul -1 Striatum_selection_mask
         
fslmaths Striatum \
         -mul Striatum_selection_mask \
         Striatum
         
fslmaths Striatum -bin Striatum_mask  # update the mask of the Striatum

# # test with the following
# fslmaths Striatum_mask.nii.gz -mul Schaefer100_ribbon_mask.nii.gz test
# fslstats test -V


# some voxels (N=7) in the Striatum are also present in the Thalamus, but they likely
# belong to the Striatum. Remove the shared Thalamus/Striatum voxels from the Thalamus
fslmaths Thalamus_mask -mul Striatum_mask -sub 1 -mul -1 Thalamus_selection_mask
fslmaths Thalamus -mul Thalamus_selection_mask Thalamus
fslmaths Thalamus -bin Thalamus_mask # recreate a mask of the TH after excluding the Striatal voxels

# # test with the following
# fslmaths Striatum_mask -mul Thalamus_mask.nii.gz test
# fslstats test -V


# Separate RH and LH Thalamus
fslmaths Thalamus -roi  0 45 0 109 0 91 0 1 Thalamus_RH
fslmaths Thalamus -roi 45 45 0 109 0 91 0 1 Thalamus_LH


# Separate RH and LH Striatum
fslmaths Striatum -roi  0 45 0 109 0 91 0 1 Striatum_RH
fslmaths Striatum -roi 45 45 0 109 0 91 0 1 Striatum_LH





# extract Amygdala and Hippocampus from the HO Subcortical
# add 1 to the index in the XML
fslmaths HO_Subcortical -thr $((8+1)) -uthr $((9+1)) HO_Limbic_LH
fslmaths HO_Subcortical -thr $((18+1)) -uthr $((19+1)) HO_Limbic_RH

fslmaths HO_Limbic_LH -add HO_Limbic_RH -bin HO_Limbic_mask


# # test overlap with ribbon, Striatum, Thalamus
# for mask in Schaefer100_ribbon_mask Thalamus_mask Striatum_mask; do
#
#   fslmaths HO_Limbic_mask -mul ${mask} test
#   overlap=`fslstats test.nii.gz -V | awk '{print $1}'`
#   echo ${overlap} voxels with ${mask}
#
# done

# remove the shared voxels from the HO_Limbic mask
fslmaths Schaefer100_ribbon_mask \
         -add Striatum_mask \
         -add Thalamus_mask \
         -bin \
         -mul HO_Limbic_mask \
         -sub 1 -mul -1 \
         HO_Limbic_selection_mask
         
for hemi in RH LH; do
  fslmaths HO_Limbic_${hemi} \
           -mul HO_Limbic_selection_mask \
           HO_Limbic_${hemi}
done

fslmaths HO_Limbic_LH -add HO_Limbic_RH -bin HO_Limbic_mask # update Limbic mask

# scale HO_limbic of both hemispheres in the range 1:2
fslmaths HO_Limbic_RH -sub 18 -thr 0 HO_Limbic_RH
fslmaths HO_Limbic_LH -sub  8 -thr 0 HO_Limbic_LH
 


# test exclusivity of each mask
for maski in Schaefer100_ribbon_mask Thalamus_mask Striatum_mask HO_Limbic_mask; do
  for maskj in Schaefer100_ribbon_mask Thalamus_mask Striatum_mask HO_Limbic_mask; do
  
      fslmaths ${maski} -mul ${maskj} test
      overlap=`fslstats test.nii.gz -V | awk '{print $1}'`
      echo ${overlap} voxels shared between ${maski} and ${maskj}
  
  done
  echo
done



# prepare the Thalamus, Striatum and Limbic labels with the correct values
# Schaefer: 1:50
# Thalamus: 51:57 i.e. add 50 and thr to 51 to remove zeros which became 50
# Striatum: 58:64 i.e. add 57 and thr to 58 to remove zeros which became 57
# Amy+Hippo: 65:66 ie. add 64 and thr to 65 to remove zeros which became 64

for hemi in RH LH; do
  fslmaths Thalamus_${hemi} -add 50 -thr 51 Thalamus_${hemi}
done

for hemi in RH LH; do
  fslmaths Striatum_${hemi} -add 57 -thr 58 Striatum_${hemi}
done

for hemi in RH LH; do
  fslmaths HO_Limbic_${hemi} -add 64 -thr 65 HO_Limbic_${hemi}
done


# Check the range before adding them
for hemi in RH LH; do
  for region in Schaefer100_ribbon Thalamus Striatum HO_Limbic; do
    fslmaths ${region}_${hemi} -bin test_mask
    echo ${region}_${hemi} values are in the range \
         `fslstats ${region}_${hemi} -k test_mask -R`
  done
  echo
done


# Create an atlas containing Ribbon, Thalamus, Striatum, Amygdala, Hippocampus
mkdir tmp

for hemi in RH LH; do

  fslmaths Schaefer100_ribbon_${hemi} \
           -add Thalamus_${hemi} \
           -add Striatum_${hemi} \
           -add HO_Limbic_${hemi} \
           tmp/Schaefer100_ribbon_subcort_${hemi}

done


# Test that the values in the atlas range exactly from 1..66.
# This is a further test for the presence of no shared voxels
# among Cortical ribbon, Thalamus, Striatum, Amygdala and Hippocampus
for hemi in RH LH; do

  fslmaths tmp/Schaefer100_ribbon_subcort_${hemi} -bin test_mask
  echo Schaefer100_ribbon_subcort_${hemi} are in the range \
       `fslstats tmp/Schaefer100_ribbon_subcort_${hemi} -k test_mask -R`
  echo

done


# Remove the regions of interest (subcortical) from the CSF_termination_mask
# which was created only on the basis of the Schaefer100 cortical
fslmaths tmp/Schaefer100_ribbon_subcort_RH \
         -add tmp/Schaefer100_ribbon_subcort_LH \
         -bin \
         -mul ${segdir}/CSF_termination \
         sharedWithTermination
         
fslmaths ${segdir}/CSF_termination \
         -sub sharedWithTermination \
         tmp/CSF_termination_mask



# Housekeeping
rm *test*
rm *mask* *RH* *LH*
rm Schaefer100_ribbon.nii.gz Striatum.nii.gz Thalamus.nii.gz HO_Subcortical.nii.gz sharedWithTermination.nii.gz
mv tmp/* .
rmdir tmp
