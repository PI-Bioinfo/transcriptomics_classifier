process CLASSIFICATION {
    tag "${meta}"

    conda '/opt/miniconda/envs/asthma_classifier'

    input:
    tuple val(meta), path(top_genes)             
    tuple val(meta), path(count_train)
    tuple val(meta), path(meta_train), path(count_train)
    tuple val(meta), path(meta_test), path(count_test)   

    output:
    tuple val(meta), path("*pred_score.csv")                  , optional: true, emit: predictions
    tuple val(meta), path("*selected_features.csv")           , optional: true, emit: selected_features
    tuple val(meta), path("*coef_matrix.csv")                 , optional: true, emit: coef_matrix
    tuple val(meta), path("*conf_matrix.csv")                 , optional: true, emit: conf_matrix

    script:
    """
    #!/usr/bin/env Rscript
    suppressMessages(library(caret))
    suppressMessages(library(pROC))
    suppressMessages(library(ggplot2))
    suppressMessages(library(glmnet))

    # Loading data
    top_genes <- read.csv("${top_genes}", row.names=1)
    meta_train <- read.csv("${meta_train}", row.names=1)
    count_train <- read.csv("${count_train}", row.names=1)
    meta_test <- read.csv("${meta_test}", row.names=1)
    count_test <- read.csv("${count_test}", row.names=1)

    # Constructing X and y
    # meta_train\$Sex <- as.factor(meta_train\$Sex)
    # meta_test\$Sex <- as.factor(meta_test\$Sex)

    X <- as.matrix(t(count_train))
    y <- factor(meta_train\$group, levels = c("normal", "cancer"))
    y <- as.numeric(y) - 1
    # X <- cbind(X, Age = as.numeric(meta_train\$Age), Sex = as.numeric(meta_train\$Sex) - 1)

    # Performing Lasso regression
    cv_lasso <- cv.glmnet(X, y, family = "binomial", alpha = 1, nfolds = 10)
    lambda_opt <- cv_lasso\$lambda.min
    lasso_model <- glmnet(X, y, family = "binomial", lambda = lambda_opt)
    coef_matrix <- as.matrix(coef(lasso_model))
    selected_features <- rownames(coef_matrix)[coef_matrix[, 1] != 0]

    # Selecting features
    selected_genes <- selected_features[!(selected_features == "(Intercept)" | selected_features == "Age" | selected_features == "Sex")]
    intercept <- coef_matrix["(Intercept)", ]

    beta_gene_values <- coef_matrix[selected_genes, ]
    # beta_demo_value <- coef_matrix["Age", ]
    # demo_values <- as.matrix(as.numeric(as.factor(meta_test\$Age)) - 1)

    # Computing RSRS 
    rsrs <- count_test[selected_genes, ]
    rsrs <- log2(rsrs + 1)

    rsrs_score <- t(as.matrix(beta_gene_values)) %*% as.matrix(rsrs)
    # sex_score <- demo_values %*% beta_demo_value
    # test_pred_score <- intercept + rsrs_score + t(sex_score)
    test_pred_score <- intercept + rsrs_score

    # Generating prediction
    mu <- exp(test_pred_score) / (1 + exp(test_pred_score))
    y_test <- factor(meta_test\$group, levels = c("normal", "cancer"))
    y_test <- as.numeric(y_test) - 1
    true_labels <- t(as.matrix(y_test))

    roc_obj <- roc(true_labels, mu)
    best_cutoff <- coords(roc_obj, "best", ret = "threshold")
    pred_labels <- ifelse(as.vector(mu) < as.numeric(best_cutoff[1]), 0, 1)

    conf_matrix <- confusionMatrix(as.factor(pred_labels), as.factor(true_labels))
    print(conf_matrix\$overall["Accuracy"])
    auc_value <- auc(roc_obj)
    print(paste("AUC:", round(auc_value, 4)))
    png("${meta}_roc_curve.png", width=800, height=600)
    plot(roc_obj, col="blue", main="ROC Curve")
    dev.off()

    # plotting density
    rsrs_score <- as.data.frame(t(rsrs_score), skip = 1)
    colnames(rsrs_score) <- "RSRS"
    meta_test_plot <- meta_test[, "group", drop=FALSE]
    merge_rsrs <- merge(rsrs_score, meta_test_plot, by = 0, sort=FALSE)

    p <- ggplot(merge_rsrs, aes(x = RSRS, fill = group)) +
        geom_density(alpha = 0.5) +
        theme_minimal() +
        labs(title = "Density Plot of RSRS Scores", x = "RSRS Score", y = "Density") +
        scale_fill_manual(values = c("normal" = "turquoise", "cancer" = "pink"))
    ggsave("${meta}_rsrs_density_plot.png", plot = p, width = 8, height = 6, dpi = 300)

    # Exporting results
    write.csv(selected_features, "${meta}_selected_features.csv")
    write.csv(test_pred_score, "${meta}_test_pred_score.csv")
    write.csv(conf_matrix\$table, "${meta}_conf_matrix.csv")
    write.csv(coef_matrix, "${meta}_coef_matrix.csv")
    """
    
}