include { PREDICT                                          } from "${projectDir}/modules/local/predict.nf"
include { PREDICT_SIGNATURES                               } from "${projectDir}/modules/local/predict_signatures.nf"

workflow INFERENCE {
    
    take:
        ch_combined_inference_counts
        ch_inference_meta
        classification_model
        xgboost_model
        random_forest_model

    main:

        PREDICT(
            ch_combined_inference_counts,
            ch_inference_meta,
            xgboost_model,
            random_forest_model,
        )

        PREDICT_SIGNATURES(
            ch_combined_inference_counts,
            ch_inference_meta,
            classification_model
        )

}