process INFERENCE {
    tag "${meta}"

    conda '/opt/miniconda/envs/asthma_classifier'
    publishDir "result/", mode: 'copy'

    input:
    tuple val(meta), path(meta_val), path(count_val)
    tuple val(meta2), path(selected_genes)
    tuple val(meta2), path(coef_matrix)             

    output:
    tuple val(meta), path("*pred_score.csv")                  , optional: true, emit: inference
    tuple val(meta), path("*conf_matrix.csv")                 , optional: true, emit: conf_matrix

    script:
    """
    #!/usr/bin/env Rscript

    suppressMessages(library(caret))
    suppressMessages(library(pROC))
    suppressMessages(library(ggplot2))

    meta_val <- read.csv("${meta_val}", row.names=1)
    count_val <- read.csv("${count_val}", row.names=1)
    coef_matrix <- read.csv("${coef_matrix}", row.names=1)
    selected_features <- read.csv("${selected_genes}", row.names=1)

    # select features
    selected_genes <- selected_features\$x
    selected_genes <- selected_features[!(selected_features == "(Intercept)" | selected_features == "sex") | selected_features == "age"]
    # selected_demo <- selected_features[(selected_features == "sex" | selected_features == "age")]

    intercept <- coef_matrix["(Intercept)", ]
    beta_gene_values <- coef_matrix[selected_genes, , drop=FALSE]
    # beta_demo_values <- coef_matrix[selected_demo, , drop=FALSE]
    
    # prediction
    rsrs <- count_val[match(rownames(beta_gene_values), rownames(count_val)), , drop = FALSE]
    rsrs <- rsrs[complete.cases(rsrs), ]
    rsrs <- log2(rsrs + 1)
    beta_gene_values <- beta_gene_values[rownames(rsrs), , drop=FALSE]
    rsrs_score <- t(as.matrix(beta_gene_values)) %*% as.matrix(rsrs)
    val_pred_score <- intercept + rsrs_score

    mu <- exp(val_pred_score) / (1 + exp(val_pred_score))
    y_val <- factor(meta_val\$group, levels = c("normal", "cancer"))
    y_val <- as.numeric(y_val) - 1
    true_labels <- t(as.matrix(y_val))

    roc_obj <- roc(true_labels, mu)
    best_cutoff <- coords(roc_obj, "best", ret = "threshold")
    best_cutoff <- best_cutoff[1, "threshold"]

    pred_labels <- ifelse(as.vector(mu) < as.numeric(best_cutoff), 0, 1)
    conf_matrix <- confusionMatrix(as.factor(pred_labels), as.factor(true_labels))

    print(conf_matrix\$overall["Accuracy"])
    auc_value <- auc(roc_obj)
    print(paste("AUC:", round(auc_value, 4)))
    png("${meta}_roc_curve.png", width=800, height=600)
    plot(roc_obj, col="blue", main="ROC Curve")
    dev.off()

    # export results
    write.csv(beta_gene_values, "${meta}_beta_gene_values.csv")
    write.csv(rsrs, "${meta}_rsrs.csv")
    write.csv(mu, "${meta}_mu.csv")
    write.csv(val_pred_score, "${meta}_val_pred_score.csv")
    write.csv(conf_matrix\$table, "${meta}_conf_matrix.csv")
    """
}