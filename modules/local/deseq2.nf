process DESEQ2 {
    tag "${meta}"

    conda '/opt/miniconda/envs/asthma_classifier'
    publishDir "result/", mode: 'copy'

    input:
    tuple val(meta), path(meta_train), path(count_train)

    output:
    tuple val(meta), path("*MA_plot.png")                       , emit: ma_plot
    tuple val(meta), path("*volcano_plot.png")                  , emit: volcano_plot
    tuple val(meta), path("*normalized_counts.csv")             , emit: normalized_counts
    tuple val(meta), path("*DESeq_results.csv")                 , emit: deseq2_results

    script:
    """
    #!/usr/bin/env Rscript

    suppressMessages(library(DESeq2))
    suppressMessages(library(caret))

    meta_train <- read.csv("${meta_train}", row.names=1)
    count_train <- read.csv("${count_train}", row.names=1)
    fdr_cutoff <- as.numeric("0.05")
    lfc_cutoff <- as.numeric("0")

    dds <- DESeqDataSetFromMatrix(
        countData=count_train,
        colData=meta_train,
        design= ~ group,
    )
    
    dds <- dds[rowSums(counts(dds)) >= 10,]
    dds <- DESeq(dds)
    res <- results(dds)

    # Write the result
    write.csv(res, "${meta}_DESeq_results.csv", quote=FALSE)

    # Plot MA & Volcano plot
    png("${meta}_MA_plot.png", width=800, height=600)
    plotMA(res, ylim=c(-5, 5), main="MA Plot")
    dev.off()

    volcano_data <- data.frame(
        log2FoldChange = res\$log2FoldChange,
        negLogP = -log10(res\$pvalue),
        padj = res\$padj
    )
    png("${meta}_volcano_plot.png", width=800, height=600)
    ggplot(volcano_data, aes(x=log2FoldChange, y=negLogP)) +
        geom_point(aes(color=padj < 0.05), alpha=0.6, size=1) +
        scale_color_manual(values=c("black", "red")) +
        labs(title="Volcano Plot", x="Log2 Fold Change", y="-Log10 P-value") +
        theme_minimal() +
        theme(legend.position="none")
    dev.off()

    # Export normalized counts
    normalized_counts <- counts(dds, normalized=FALSE)
    log_norm <- assay(varianceStabilizingTransformation(dds))
    write.csv(log_norm, "${meta}_normalized_counts.csv")
    """

}