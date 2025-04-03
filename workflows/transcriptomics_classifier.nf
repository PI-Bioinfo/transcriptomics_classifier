include { PREPROCESS                                              } from "${projectDir}/modules/local/preprocess.nf"
include { COMBINE_RAW_COUNTS as COMBINE_TRAIN                     } from "${projectDir}/modules/local/combine_raw_counts.nf"
include { COMBINE_RAW_COUNTS as COMBINE_TEST                      } from "${projectDir}/modules/local/combine_raw_counts.nf"

include { COMBINE_COUNTS                                          } from "${projectDir}/modules/local/combine_counts.nf"
include { COMBINE_COUNTS as COMBINE_INFERENCE_COUNTS              } from "${projectDir}/modules/local/combine_counts.nf"
include { COMBINE_GENES                                           } from "${projectDir}/modules/local/combine_genes.nf"

include { DESEQ2 as DESEQ2_HUMAN                                  } from "${projectDir}/modules/local/deseq2.nf"
include { DESEQ2 as DESEQ2_VIRAL                                  } from "${projectDir}/modules/local/deseq2.nf"
include { NORMALIZE_COUNT                                         } from "${projectDir}/modules/local/normalize_counts.nf"
// include { NORMALIZE_INFERENCE_COUNT                               } from "${projectDir}/modules/local/normalize_inference.nf"
include { NORMALIZE_COMBINE_COUNT                                 } from "${projectDir}/modules/local/normalize_combined_counts.nf"

include { FEATURE_SELECTION_PADJ as FEATURE_SELECTION_PADJ_HUMAN  } from "${projectDir}/modules/local/feature_selection_padj.nf"
include { FEATURE_SELECTION_PADJ as FEATURE_SELECTION_PADJ_VIRAL  } from "${projectDir}/modules/local/feature_selection_padj.nf"

include { CLASSIFICATION                                          } from "${projectDir}/modules/local/classification_model.nf"
include { RANDOM_FOREST                                           } from "${projectDir}/modules/local/random_forest.nf"
include { XGBOOST                                                 } from "${projectDir}/modules/local/XGboost.nf"
include { MULTIQC                                                 } from "${projectDir}/modules/local/multiqc.nf"

include { INFERENCE                                               } from "${projectDir}/subworkflows/inference.nf"

workflow TRANSCRIPTOMICS_CLASSIFIER {
    // Loading channels
    ch_meta                 = Channel.of(params.meta)
    ch_meta_human           = Channel.of(params.meta_human)
    ch_meta_viral           = Channel.of(params.meta_viral)
    ch_metadata             = ch_meta_human.combine(Channel.fromPath(params.design, checkIfExists: true))
    ch_human_countdata      = ch_meta_human.combine(Channel.fromPath(params.human_countdata, checkIfExists: true))
    ch_viral_countdata      = ch_meta_viral.combine(Channel.fromPath(params.viral_countdata, checkIfExists: true))
    ch_split_option         = Channel.of(params.split_data_by)

    ch_inference            = Channel.of(params.inference)
    ch_inference_meta       = ch_inference.combine(Channel.fromPath(params.inference_design, checkIfExists: true))
    ch_inference_humandata  = ch_inference.combine(Channel.fromPath(params.inference_humancount, checkIfExists: true))
    ch_inference_viraldata  = ch_inference.combine(Channel.fromPath(params.inference_viralcount, checkIfExists: true))

    // Splitting train & test
    PREPROCESS(
        ch_split_option,
        ch_metadata,
        ch_human_countdata,
        ch_viral_countdata
    )

    ch_human_train_set = PREPROCESS.out.train_set
        .combine(ch_meta_human)
        .map{ meta, meta_file, human_count, viral_count, meta_human -> tuple(meta_human, human_count) }
    ch_viral_train_set = PREPROCESS.out.train_set
        .combine(ch_meta_viral)
        .map{ meta, meta_file, human_count, viral_count, meta_viral -> tuple(meta_viral, viral_count) }
    ch_human_test_set = PREPROCESS.out.test_set
        .combine(ch_meta_human)
        .map{ meta, meta_file, human_count, viral_count, meta_human -> tuple(meta_human, human_count) }
    ch_viral_test_set = PREPROCESS.out.test_set
        .combine(ch_meta_viral)
        .map{ meta, meta_file, human_count, viral_count, meta_viral -> tuple(meta_viral, viral_count) }

    ch_train_metadata = PREPROCESS.out.train_set
        .map{ meta, meta_file, human_count, viral_count -> tuple(meta, meta_file) }
    ch_test_metadata = PREPROCESS.out.test_set
        .map{ meta, meta_file, human_count, viral_count -> tuple(meta, meta_file) }

    NORMALIZE_COUNT(
        ch_human_train_set,
        ch_human_test_set,
        ch_viral_train_set,
        ch_viral_test_set
    )

    if ( params.inference ) {
        NORMALIZE_INFERENCE_COUNT(
            ch_inference_humandata,
            ch_inference_viraldata
        )
    }
    
    DESEQ2_HUMAN(
        ch_human_train_set,
        ch_train_metadata
    )

    DESEQ2_VIRAL(
        ch_viral_train_set,
        ch_train_metadata
    )

    FEATURE_SELECTION_PADJ_VIRAL(
        ch_viral_train_set,
        ch_train_metadata,
        DESEQ2_VIRAL.out.normalized_counts,
        DESEQ2_VIRAL.out.deseq2_results
    )

    FEATURE_SELECTION_PADJ_HUMAN(
        ch_human_train_set,
        ch_train_metadata,
        DESEQ2_HUMAN.out.normalized_counts,
        DESEQ2_HUMAN.out.deseq2_results
    )

    if ( params.data_type == "viral") {

        CLASSIFICATION(
            FEATURE_SELECTION_PADJ_VIRAL.out.top_genes,
            FEATURE_SELECTION_PADJ_VIRAL.out.norm_train_count,
            ch_train_metadata,
            ch_test_metadata,
            ch_viral_test_set
        )

        XGBOOST(
            ch_train_metadata,
            ch_test_metadata,
            NORMALIZE_COUNT.out.viral_train_set,
            NORMALIZE_COUNT.out.viral_test_set
        )
        
        RANDOM_FOREST(
            ch_train_metadata,
            ch_test_metadata,
            NORMALIZE_COUNT.out.viral_train_set,
            NORMALIZE_COUNT.out.viral_test_set
        )

        if ( params.inference ) {

            INFERENCE(
                NORMALIZE_INFERENCE_COUNT.out.viral_set,
                ch_inference_meta,
                CLASSIFICATION.out.coef_matrix,
                XGBOOST.out.model,
                RANDOM_FOREST.out.model
            )

        }
    }

    if ( params.data_type == "human") {

        CLASSIFICATION(
            FEATURE_SELECTION_PADJ_HUMAN.out.top_genes,
            FEATURE_SELECTION_PADJ_HUMAN.out.norm_train_count,
            ch_train_metadata,
            ch_test_metadata,
            ch_human_test_set
        )

        XGBOOST(
            ch_train_metadata,
            ch_test_metadata,
            NORMALIZE_COUNT.out.human_train_set,
            NORMALIZE_COUNT.out.human_test_set
        )

        RANDOM_FOREST(
            ch_train_metadata,
            ch_test_metadata,
            NORMALIZE_COUNT.out.human_train_set,
            NORMALIZE_COUNT.out.human_test_set
        )

        if ( params.inference ) {

            INFERENCE(
                NORMALIZE_INFERENCE_COUNT.out.human_set,
                ch_inference_meta,
                CLASSIFICATION.out.coef_matrix,
                XGBOOST.out.model,
                RANDOM_FOREST.out.model
            )
            
        }
    }

    if ( params.data_type == "combined" ) {

        COMBINE_TRAIN(
            "train",
            ch_human_train_set,
            ch_viral_train_set
        )
        ch_combined_train_counts = COMBINE_TRAIN.out.merged

        COMBINE_TEST(
            "test",
            ch_human_test_set,
            ch_viral_test_set
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
            ch_train_metadata,
            ch_test_metadata,
            ch_combined_test_counts
        )

        NORMALIZE_COMBINE_COUNT(
            ch_combined_train_counts,
            ch_combined_test_counts
        )

        XGBOOST(
            ch_train_metadata,
            ch_test_metadata,
            NORMALIZE_COMBINE_COUNT.out.combined_train_counts,
            NORMALIZE_COMBINE_COUNT.out.combined_test_counts
        )

        RANDOM_FOREST(
            ch_train_metadata,
            ch_test_metadata,
            NORMALIZE_COMBINE_COUNT.out.combined_train_counts,
            NORMALIZE_COMBINE_COUNT.out.combined_test_counts
        )
    }

    if ( params.inference ) {

        COMBINE_INFERENCE_COUNTS(
            ch_meta,
            NORMALIZE_INFERENCE_COUNT.out.human_set,
            NORMALIZE_INFERENCE_COUNT.out.viral_set
        )
        ch_combined_inference_counts = COMBINE_INFERENCE_COUNTS.out.merged

        INFERENCE(
            ch_combined_inference_counts,
            ch_inference_meta,
            CLASSIFICATION.out.coef_matrix,
            XGBOOST.out.model,
            RANDOM_FOREST.out.model
        )
    }
    
}