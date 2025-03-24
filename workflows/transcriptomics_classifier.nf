include { PREPROCESS                            } from "${projectDir}/modules/local/preprocess.nf"
include { COMBINE_VIRAL                         } from "${projectDir}/modules/local/combine_viral.nf"

include { DESEQ2                                } from "${projectDir}/modules/local/deseq2.nf"
include { FEATURE_SELECTION_PADJ                } from "${projectDir}/modules/local/feature_selection_padj.nf"
include { FEATURE_SELECTION_KBEST               } from "${projectDir}/modules/local/feature_selection_kbest.nf"
include { CLASSIFICATION                        } from "${projectDir}/modules/local/classification_model.nf"
include { RANDOM_FOREST                         } from "${projectDir}/modules/local/random_forest.nf"
include { XGBOOST                               } from "${projectDir}/modules/local/XGboost.nf"
include { INFERENCE                             } from "${projectDir}/modules/local/inference.nf"
include { MULTIQC                               } from "${projectDir}/modules/local/multiqc.nf"

workflow TRANSCRIPTOMICS_CLASSIFIER {
    // Loading channels
    ch_meta             = Channel.of(params.meta)
    ch_metadata         = ch_meta.combine(Channel.fromPath(params.metadata))
    ch_countdata        = ch_meta.combine(Channel.fromPath(params.countdata))

    ch_validation_set   = Channel.fromPath(params.validation_design)
    ch_validation_set
            | splitCsv(header: true)
            | map ( row -> tuple(row["sample"], 
                row["path"] + "/" + row["sample"] + "_metadata.csv", 
                row["path"] + "/" + row["sample"] + "_cleandata.csv") )
            | set { ch_validation_set }

    

    // Splitting train & test
    PREPROCESS(
        ch_metadata,
        ch_countdata
    )
    
    DESEQ2(
        PREPROCESS.out.train_set
    )

    // Features selection
    FEATURE_SELECTION_PADJ(
        PREPROCESS.out.train_set,
        DESEQ2.out.normalized_counts,
        DESEQ2.out.deseq2_results
    )

    // Classification
    CLASSIFICATION(
        FEATURE_SELECTION_PADJ.out.top_genes,
        FEATURE_SELECTION_PADJ.out.count_train,
        PREPROCESS.out.train_set,
        PREPROCESS.out.test_set
    )
    XGBOOST(
        PREPROCESS.out.train_set,
        DESEQ2.out.normalized_counts,
        DESEQ2.out.deseq2_results,
        PREPROCESS.out.test_set
    )
    RANDOM_FOREST(
        PREPROCESS.out.train_set,
        DESEQ2.out.normalized_counts,
        DESEQ2.out.deseq2_results,
        PREPROCESS.out.test_set
    )

    // Inference on unseen data
    INFERENCE(
        ch_validation_set,
        CLASSIFICATION.out.selected_features.first(),
        CLASSIFICATION.out.coef_matrix.first()
    )
    
}