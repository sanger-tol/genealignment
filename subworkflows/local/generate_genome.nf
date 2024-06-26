#!/usr/bin/env nextflow

//
// MODULE IMPORT BLOCK
//
include { GET_LARGEST_SCAFF             } from '../../modules/local/get_largest_scaff'
include { CUSTOM_GETCHROMSIZES          } from '../../modules/nf-core/custom/getchromsizes/main'
include { GNU_SORT                      } from '../../modules/nf-core/gnu/sort'


workflow GENERATE_GENOME {
    take:
    reference_file  // Channel: tuple

    main:
    ch_versions     = Channel.empty()
    ch_genomesize   = Channel.empty()
    ch_genome_fai   = Channel.empty()

    //
    // MODULE: GENERATE INDEX OF REFERENCE
    //          EMITS REFERENCE INDEX FILE MODIFIED FOR SCAFF SIZES
    //
    CUSTOM_GETCHROMSIZES (
        reference_file,
        "genome"
        )
    ch_versions     = ch_versions.mix( CUSTOM_GETCHROMSIZES.out.versions )


    //
    // MODULE: SORT THE GENOME FILE BASED ON THE LENGTH OF THE SCAFFOLD
    //
    GNU_SORT (
            CUSTOM_GETCHROMSIZES.out.sizes
            )
    ch_versions     = ch_versions.mix( GNU_SORT.out.versions )

    emit:
    dot_genome      = GNU_SORT.out.sorted
    ref_index       = CUSTOM_GETCHROMSIZES.out.fai
    versions        = ch_versions.ifEmpty(null)
}
