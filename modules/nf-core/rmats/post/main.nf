process RMATS_POST {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/rmats:4.3.0--py310ha9d9618_5':
        'quay.io/biocontainers/rmats:4.3.0--py310ha9d9618_5' }"

    input:
    tuple val(meta), path(genome_bam)
    tuple val(meta2), path(reference_gtf)
    path (rmats_prep)
    val read_length

    output:
    tuple val(meta), path("${prefix}_rmats_post"), emit: q-value
    tuple val(meta), path("*.{}"), emit: p-value
    tuple val("${task.process}"), val('rmats'), eval('rmats.py --version | sed -e "s/v//g"'), emit: versions_rmats, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo ${genome_bam} > ${prefix}.post.b1.txt
    mkdir -p rmats_tmp
    mv ${rmats_prep} rmats_tmp

    rmats \\
        --task post \\
        ${args} \\
        --nthread ${task.cpus} \\
        --b1 ${prefix}.post.b1.txt \\
        --readLength ${read_length} \\
        --tmp rmats_tmp \\
        --od ${prefix}_rmats_post
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args

    mkdir -p ${prefix}_rmats_post

    touch ${prefix}_rmats_post/rmats_dummy
    touch ${prefix}_rmats_post/rmats_dummy.log
    """
}
