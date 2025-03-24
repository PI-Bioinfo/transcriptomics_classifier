include { PREPROCESS                                              } from "${projectDir}/modules/local/preprocess.nf"
include { COMBINE_COUNTS                                          } from "${projectDir}/modules/local/combine_counts.nf"

include { DESEQ2 as DESEQ2_HUMAN                                  } from "${projectDir}/modules/local/deseq2.nf"
include { DESEQ2 as DESEQ2_VIRAL                                  } from "${projectDir}/modules/local/deseq2.nf"

include { FEATURE_SELECTION_PADJ as FEATURE_SELECTION_PADJ_HUMAN  } from "${projectDir}/modules/local/feature_selection_padj.nf"
include { FEATURE_SELECTION_PADJ as FEATURE_SELECTION_PADJ_VIRAL  } from "${projectDir}/modules/local/feature_selection_padj.nf"

include { CLASSIFICATION                                          } from "${projectDir}/modules/local/classification_model.nf"
include { RANDOM_FOREST                                           } from "${projectDir}/modules/local/random_forest.nf"
include { XGBOOST                                                 } from "${projectDir}/modules/local/XGboost.nf"
include { INFERENCE                                               } from "${projectDir}/modules/local/inference.nf"
include { MULTIQC                                                 } from "${projectDir}/modules/local/multiqc.nf"

workflow TRANSCRIPTOMICS_CLASSIFIER {
    // Loading channels
    ch_meta                 = Channel.of(params.meta)
    ch_metadata             = ch_meta.combine(Channel.fromPath(params.design, checkIfExists: true))
    ch_human_countdata      = ch_meta.combine(Channel.fromPath(params.human_countdata, checkIfExists: true))
    ch_viral_countdata      = ch_meta.combine(Channel.fromPath(params.viral_countdata, checkIfExists: true))

    // Splitting train & test
    PREPROCESS(
        ch_metadata,
        ch_human_countdata,
        ch_viral_countdata
    )
    
    DESEQ2_HUMAN(
        PREPROCESS.out.human_train_set
    )

    DESEQ2_VIRAL(
        PREPROCESS.out.viral_train_set
    )

    // Features selection
    FEATURE_SELECTION_PADJ_HUMAN(
        PREPROCESS.out.human_train_set,
        DESEQ2_HUMAN.out.normalized_counts,
        DESEQ2_HUMAN.out.deseq2_results
    )

    FEATURE_SELECTION_PADJ_VIRAL(
        PREPROCESS.out.viral_train_set,
        DESEQ2_VIRAL.out.normalized_counts,
        DESEQ2_VIRAL.out.deseq2_results
    )

    // Combining counts
    COMBINE_COUNTS(
        DESEQ2_HUMAN.out.normalized_counts,
        DESEQ2_VIRAL.out.normalized_counts
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
        PREPROCESS.out.test_set
    )
    RANDOM_FOREST(
        PREPROCESS.out.train_set,
        PREPROCESS.out.test_set
    )

    // Inference on unseen data
    // INFERENCE(
    //     ch_inference_set,
    //     CLASSIFICATION.out.selected_features.first(),
    //     CLASSIFICATION.out.coef_matrix.first()
    // )
    
}