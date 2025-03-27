process PREPROCESS {
    tag "${meta}"

    conda '/opt/miniconda/envs/asthma_classifier'

    input:
    tuple val(meta), path(metadata)
    tuple val(meta_human), path(countdata)  
    tuple val(meta_viral), path(viraldata) 

    output:
    tuple val(meta_human), path("*meta_train.csv"), path("*human_count_train.csv")        , emit: human_train_set
    tuple val(meta_human), path("*meta_test.csv"), path("*human_count_test.csv")          , emit: human_test_set
    tuple val(meta_viral), path("*meta_train.csv"), path("*viral_count_train.csv")        , emit: viral_train_set
    tuple val(meta_viral), path("*meta_test.csv"), path("*viral_count_test.csv")          , emit: viral_test_set

    script:
    def sampling_ratio          = task.ext.sampling_ratio ?: 0.8
    def sampling_seed           = task.ext.sampling_seed ?: 42
    """
    #!/usr/bin/env Rscript

    set.seed(${sampling_seed})
    suppressMessages(library(caret))

    metadata <- read.csv("${metadata}", row.names=1)
    rawdata <- read.csv("${countdata}", row.names=1)
    viraldata <- read.csv("${viraldata}", row.names=1)

    gene_sums <- rowSums(rawdata)
    rawdata <- rawdata[gene_sums > 10, ]

    # Sampling & partition
    train_idx <- createDataPartition(metadata\$group, p = as.numeric(${sampling_ratio}), list = FALSE)

    meta_train <- metadata[train_idx, ]
    meta_test <- metadata[-train_idx, ]
    df_train <- rawdata[, rownames(meta_train)]
    df_test <- rawdata[, rownames(meta_test)]
    df_viral_train <- viraldata[, rownames(meta_train)]
    df_viral_test <- viraldata[, rownames(meta_test)]

    write.csv(meta_train, "meta_train.csv", row.names=TRUE)
    write.csv(meta_test, "meta_test.csv", row.names=TRUE)
    write.csv(df_train, "${meta_human}_count_train.csv", row.names=TRUE)
    write.csv(df_test, "${meta_human}_count_test.csv", row.names=TRUE)
    write.csv(df_viral_train, "${meta_viral}_count_train.csv", row.names=TRUE)
    write.csv(df_viral_test, "${meta_viral}_count_test.csv", row.names=TRUE)
    """
}