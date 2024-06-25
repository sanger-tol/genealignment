/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { SAMTOOLS_FAIDX         } from '../modules/nf-core/samtools/faidx/main'

include { YAML_INPUT             } from '../subworkflows/local/yaml_input'
include { GENERATE_GENOME        } from '../subworkflows/local/generate_genome'
include { GENE_ALIGNMENT         } from '../subworkflows/local/gene_alignment'

include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_genealignment_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GENEALIGNMENT {

    take:
    ch_yaml // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()

    Channel
        .fromPath( "${projectDir}/assets/gene_alignment/assm_*.as", checkIfExists: true)
        .map { it ->
            tuple ([ type    :   it.toString().split('/')[-1].split('_')[-1].split('.as')[0] ],
                    file(it)
                )}
        .set { gene_alignment_asfiles }


    //
    // SUBWORKFLOW: PARSE THE INPUT YAML INTO USABLE CHANNELS
    //
    YAML_INPUT (
        ch_yaml
    )


    //
    // SUBWORKFLOW: GENERATE THE DOT GENOME FILE (EFFECTIVELY A FAI)
    //
    GENERATE_GENOME(
        YAML_INPUT.out.reference_ch
    )
    ch_versions = ch_versions.mix(GENERATE_GENOME.out.versions)


    //
    // SUBWORKFLOW: Takes input fasta to generate BB files containing alignment data
    //
    GENE_ALIGNMENT (
        GENERATE_GENOME.out.dot_genome,
        YAML_INPUT.out.reference_ch,
        GENERATE_GENOME.out.ref_index,
        YAML_INPUT.out.align_data_dir,
        YAML_INPUT.out.align_geneset,
        YAML_INPUT.out.intron_size,
        gene_alignment_asfiles
    )
    ch_versions     = ch_versions.mix(GENE_ALIGNMENT.out.versions)


    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'nf_core_pipeline_software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
