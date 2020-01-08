import numpy as np
import pandas as pd
import nibabel as nib

bd='/Users/luser/Dropbox/__GitHub_repo/atlases/Schaefer100_ribbon_subcort_tracto'

hemi='LH'

atlas_info = pd.read_csv(bd + '/Schaefer100_ribbon_subcort_labels_Yeo17_' + hemi + '.csv')
atlas_info.head()

nii_atlas = nib.load(bd + '/Schaefer100_ribbon_subcort_' + hemi + '.nii.gz')

mat_atlas_yeo7 = nii_atlas.get_data().astype('int')

yeo7_labels = atlas_info['main_label'].unique()

yeo7_labels = ['Vis', 'SomMot', 'DorsAttn', 'SalVentAttn', 'Limbic', 'Cont',
               'Default', 'TempPar', 'Thalamus', 'Striatum', 'Hippocampus', 'Amygdala']

for i,label in enumerate(yeo7_labels):

    # find the nifti values associated with a given yeo17 label
    nifti_values_ith_label = atlas_info[atlas_info['main_label'].str.contains(label)]['nifti_value'].values
    print(label, i+1)
    # print(nifti_values_ith_label)
    # print(' ')
    
    # replace with a sequential number i in the volume
    mat_atlas_yeo7[np.isin(mat_atlas_yeo7, nifti_values_ith_label)] = (i+1)


nii_atlas_yeo7 = nib.Nifti1Image(mat_atlas_yeo7, nii_atlas.affine)

nib.save(nii_atlas_yeo7, bd + '/Yeo7_labels/Schaefer100_ribbon_subcort_' + hemi + '_Yeo7_colors.nii.gz')
