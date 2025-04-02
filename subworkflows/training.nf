include { PREPROCESS                                              } from "${projectDir}/modules/local/preprocess.nf"
include { COMBINE_RAW_COUNTS as COMBINE_TRAIN                     } from "${projectDir}/modules/local/combine_raw_counts.nf"
include { COMBINE_RAW_COUNTS as COMBINE_TEST                      } from "${projectDir}/modules/local/combine_raw_counts.nf"

include { COMBINE_COUNTS                                          } from "${projectDir}/modules/local/combine_counts.nf"
include { COMBINE_GENES                                           } from "${projectDir}/modules/local/combine_genes.nf"

include { DESEQ2 as DESEQ2_HUMAN                                  } from "${projectDir}/modules/local/deseq2.nf"
include { DESEQ2 as DESEQ2_VIRAL                                  } from "${projectDir}/modules/local/deseq2.nf"
include { NORMALIZE_COUNT                                         } from "${projectDir}/modules/local/normalize_counts.nf"
include { NORMALIZE_COMBINE_COUNT                                 } from "${projectDir}/modules/local/normalize_combined_counts.nf"

include { FEATURE_SELECTION_PADJ as FEATURE_SELECTION_PADJ_HUMAN  } from "${projectDir}/modules/local/feature_selection_padj.nf"
include { FEATURE_SELECTION_PADJ as FEATURE_SELECTION_PADJ_VIRAL  } from "${projectDir}/modules/local/feature_selection_padj.nf"

workflow TRAINING {
    take:
        ch_metadata,
        ch_human_countdata,
        ch_viral_countdata

    main:
    PREPROCESS(
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

    emit:
        ch_train_metadata,
        ch_test_metadata,
        
}