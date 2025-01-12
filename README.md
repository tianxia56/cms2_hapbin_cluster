# cms2_hapbin_cluster

run with env: selscan, python3, R

need prepared 

.par file

.recom file

double check cosi image

```apptainer build cosi.sif docker://docker.io/tx56/cosi```

edit ```config.json```
then run ```main_sbatch_array.sh```

update partition and runtime by editing ```zzz-update-runtime.py```

install hapbin https://github.com/evotools/hapbin  to run xpehh as in ```hapbin.notes.txt```

added upload final stats to gcloud
