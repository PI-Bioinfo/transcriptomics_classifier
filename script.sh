nextflow run main.nf --model "XGboost" \
    -resume 2>&1 | tee headnode.log