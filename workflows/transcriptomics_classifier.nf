include { PREPROCESS                                              } from "${projectDir}/modules/local/preprocess.nf"
include { COMBINE_RAW_COUNTS as COMBINE_TRAIN                     } from "${projectDir}/modules/local/combine_raw_counts.nf"
include { COMBINE_RAW_COUNTS as COMBINE_TEST                      } from "${projectDir}/modules/local/combine_raw_counts.nf"

include { COMBINE_COUNTS                                          } from "${projectDir}/modules/local/combine_counts.nf"
include { COMBINE_GENES                                           } from "${projectDir}/modules/local/combine_genes.nf"

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
    ch_meta_human           = Channel.of(params.meta_human)
    ch_meta_viral           = Channel.of(params.meta_viral)
    ch_metadata             = ch_meta_human.combine(Channel.fromPath(params.design, checkIfExists: true))
    ch_human_countdata      = ch_meta_human.combine(Channel.fromPath(params.human_countdata, checkIfExists: true))
    ch_viral_countdata      = ch_meta_viral.combine(Channel.fromPath(params.viral_countdata, checkIfExists: true))

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

    FEATURE_SELECTION_PADJ_VIRAL(
        PREPROCESS.out.viral_train_set,
        DESEQ2_VIRAL.out.normalized_counts,
        DESEQ2_VIRAL.out.deseq2_results
    )

    FEATURE_SELECTION_PADJ_HUMAN(
        PREPROCESS.out.human_train_set,
        DESEQ2_HUMAN.out.normalized_counts,
        DESEQ2_HUMAN.out.deseq2_results
    )

    if ( params.data_type == "viral") {

        CLASSIFICATION(
            FEATURE_SELECTION_PADJ_VIRAL.out.top_genes,
            FEATURE_SELECTION_PADJ_VIRAL.out.norm_train_count,
            PREPROCESS.out.viral_train_set,
            PREPROCESS.out.viral_test_set
        )

        XGBOOST(
            PREPROCESS.out.viral_train_set,
            PREPROCESS.out.viral_test_set
        )
        
        RANDOM_FOREST(
            PREPROCESS.out.viral_train_set,
            PREPROCESS.out.viral_test_set
        )
    }

    if ( params.data_type == "human") {

        CLASSIFICATION(
            FEATURE_SELECTION_PADJ_HUMAN.out.top_genes,
            FEATURE_SELECTION_PADJ_HUMAN.out.norm_train_count,
            PREPROCESS.out.human_train_set,
            PREPROCESS.out.human_test_set
        )

        XGBOOST(
            PREPROCESS.out.human_train_set,
            PREPROCESS.out.human_test_set
        )

        RANDOM_FOREST(
            PREPROCESS.out.human_train_set,
            PREPROCESS.out.human_test_set
        )
    }

    if ( params.data_type == "combined" ) {

        COMBINE_TRAIN(
            "train",
            PREPROCESS.out.human_train_set,
            PREPROCESS.out.viral_train_set
        )
        ch_combined_train_counts = COMBINE_TRAIN.out.merged

        COMBINE_TEST(
            "test",
            PREPROCESS.out.human_test_set,
            PREPROCESS.out.viral_test_set
        )
        ch_combined_test_counts = COMBINE_TEST.out.merged

        COMBINE_COUNTS(
            ch_meta,
            DESEQ2_HUMAN.out.normalized_counts,
            DESEQ2_VIRAL.out.normalized_counts
        )
        ch_combined_normalized_counts = COMBINE_COUNTS.out.merged

        COMBINE_GENES(
            ch_meta,
            FEATURE_SELECTION_PADJ_HUMAN.out.top_genes,
            FEATURE_SELECTION_PADJ_VIRAL.out.top_genes
        )
        ch_combined_top_genes = COMBINE_GENES.out.merged

        CLASSIFICATION(
            ch_combined_top_genes,
            ch_combined_normalized_counts,
            ch_combined_train_counts,
            ch_combined_test_counts
        )

        XGBOOST(
            ch_combined_train_counts,
            ch_combined_test_counts
        )

        RANDOM_FOREST(
            ch_combined_train_counts,
            ch_combined_test_counts
        )
    }
    
}