nextflow run main.nf \
    --meta HPV \
    --outdir result/ \
    --data_type combined \
    --design /home/bdkhoi/projects/transcriptomics_classifier/data/112_samples/clean_design.csv \
    --human_countdata /home/bdkhoi/projects/transcriptomics_classifier/data/112_samples/clean_human_counts.csv \
    --viral_countdata /home/bdkhoi/projects/transcriptomics_classifier/data/112_samples/clean_viral_counts.csv \
    --resume 2>&1 | tee headnode.log