process FEATURE_SELECTION_PADJ {
    tag "${meta}"

    conda '/opt/miniconda/envs/asthma_classifier'

    input:
    tuple val(meta), path(meta_train), path(count_train)
    tuple val(meta), path(normalized_counts)             
    tuple val(meta), path(deseq2_results)

    output:
    tuple val(meta), path("*top_genes.csv")                   , optional: true, emit: top_genes
    tuple val(meta), path("*norm_train_count.csv")            , optional: true, emit: norm_train_count

    script:
    """
    #!/usr/bin/env Rscript
    suppressMessages(library(caret))
    suppressMessages(library(pROC))
    suppressMessages(library(ggplot2))
    suppressMessages(library(glmnet))

    # Loading data
    normalized_counts <- read.csv("${normalized_counts}", row.names=1)
    deseq2_results <- read.csv("${deseq2_results}", row.names=1)

    meta_train <- read.csv("${meta_train}", row.names=1)
    count_train <- read.csv("${count_train}", row.names=1)

    # meta_train\$Sex <- as.factor(meta_train\$Sex)
    deseq2_results <- deseq2_results[order(deseq2_results\$padj), ]

    # Selecting top genes from p-adj
    top_genes <- rownames(deseq2_results)[1:1000]
    top_genes <- top_genes[!is.na(top_genes)]
    norm_train_count <- normalized_counts[top_genes, rownames(meta_train)]

    # Exporting signatures
    write.csv(top_genes, "${meta}_top_genes.csv")
    write.csv(norm_train_count, "${meta}_norm_train_count.csv")
    """
}