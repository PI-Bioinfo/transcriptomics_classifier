process PREPROCESS {
    tag "${meta}"

    conda '/opt/miniconda/envs/asthma_classifier'

    input:
    tuple val(meta), path(metadata)
    tuple val(meta), path(countdata)   

    output:
    tuple val(meta), path("*meta_train.csv"), path("*count_train.csv")        , emit: train_set
    tuple val(meta), path("*meta_test.csv"), path("*count_test.csv")          , emit: test_set

    script:
    def sampling_ratio          = task.ext.sampling_ratio ?: 0.8
    def sampling_seed           = task.ext.sampling_seed ?: 42
    """
    #!/usr/bin/env Rscript

    set.seed(${sampling_seed})
    suppressMessages(library(caret))

    metadata <- read.csv("${metadata}", row.names=1)
    rawdata <- read.csv("${countdata}", row.names=1)

    print(dim(rawdata))
    gene_sums <- rowSums(rawdata)
    rawdata <- rawdata[gene_sums > 10, ]
    print(dim(rawdata))

    # Sampling & partition
    train_idx <- createDataPartition(metadata\$group, p = as.numeric(${sampling_ratio}), list = FALSE)

    meta_train <- metadata[train_idx, ]
    meta_test <- metadata[-train_idx, ]
    df_train <- rawdata[, rownames(meta_train)]
    df_test <- rawdata[, rownames(meta_test)]

    write.csv(meta_train, "meta_train.csv", row.names=TRUE)
    write.csv(meta_test, "meta_test.csv", row.names=TRUE)
    write.csv(df_train, "count_train.csv", row.names=TRUE)
    write.csv(df_test, "count_test.csv", row.names=TRUE)
    """
}