# Cortico-subcortical atlas for tractography based on the Schaefer100 parcellation

To carry out probabilistic tractography for our particular topic of Misophonia, I need an atlas with cortex as well as several subcortical regions - Thalamus, Striatum, Amygdala, Hippocampus.

Here is the [github repo of the final Atlas](https://github.com/leonardocerliani/Atlases-Neuroimaging/tree/master/Schaefer100_Th_Str_Amy_Hippo_tracto).
After downloading the repo, the atlas can be locally recreated using the `do_build_atlas.sh` script, which also explains all the applied procedures


![Schaefer100 ribbon + Thalamus + Striatum + Amygdala + Hippocampus](https://github.com/leonardocerliani/Atlases-Neuroimaging/blob/master/Schaefer100_Th_Str_Amy_Hippo_tracto/img/atlas_preview.png?raw=true)


The [Schaefer100](https://github.com/ThomasYeoLab/CBIG/tree/master/stable_projects/brain_parcellation/Schaefer2018_LocalGlobal/Parcellations/MNI) (paper [here](https://www.researchgate.net/publication/320255795_Local-Global_Parcellation_of_the_Human_Cerebral_Cortex_from_Intrinsic_Functional_Connectivity_MRI) and on [arXiv](https://www.biorxiv.org/content/10.1101/135632v2)) represents a wonderful cortical parcellation, since its parcels are organized hierarchically in 100..1000 parcellations, and they refer at all scales to the original Yeo 7/17 resting state functional networks, therefore at least a tentative functional labelling is provided.
However the Schaefer parcellation is only available for the cerebral cortex.

To include Thalamic and Striatal parcellation which equally bear a tentative functional characterization, I used the following sources:

- The **Oxford thalamic connectivity** atlas ([Behrens 2003 Nat Neurosci](https://www.researchgate.net/publication/10707535_Non-invasive_mapping_of_connections_between_human_thalamus_and_cortex_using_diffusion_imaging)) with 7 subdivisions
- The **Oxford-GSK-Imanova striatal connectivity atlas** ([Tziortzi 2013 Cereb Cortex](https://academic.oup.com/cercor/article/24/5/1165/389376)), also carrying 7 subdivisions
- **The Harvard-Oxford subcortical atlas** for Amygdala and Hippocampus

All of them are available inside FSL.

The Schaefer100 parcellation is thought for functional connectivity in mind. However for tractography we need to reduce the number of voxels, and select locations which minimize the possibility of tractography artifacts.
To this aim, **I created a ribbon at the interface of GM and WM**, by dilating the segmentation of WM in the MNI 2mm. A box of 8mm was used to ensure proper GM sampling also in difficult regions such as the insula.  

**I also ensured that each voxel was uniquely assigned to one label**, i.e. that there were no overlap between the different part of the atlas - there were initially.

**The atlas is split in RH and LH hemisphere**, as interhemispheric probabilistic tractography can lead to several false positives, and is not relevant for the current study. For the same reasons, the Cerebellum was not included. In case you wish to have a whole-brain atlas which discriminates LH and RH parcels, you should change the value of the labels in one of the two hemispheres - i.e. adding the maximum value of the other hemisphere - and update the labels text file.

Each hemisphere contains ~37k voxels, at a 2mm resolution. This means that the final connectivity matrix will be contained to about 1.4GB per subject, as the results of tractography can be stored as uint8.
