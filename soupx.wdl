version 1.0
workflow soupx {
    input {
    	String output_directory
        String cellranger_outputs_dir
        #general parameters
        Int cpu = 8
        String memory = "64G"
        Int disk_space = 32
        String docker = "mparikhbroad/soupx:latest"
        Int preemptible = 2
    }

    String output_directory_stripped = sub(output_directory, "/+$", "")

    call run_soupx {
        input:
            output_dir = output_directory_stripped,
            cellranger_outputs_dir = cellranger_outputs_dir,
            cpu=cpu,
            memory=memory,
            disk_space = disk_space,
            docker=docker,
            preemptible=preemptible
    }

    output {
        File soupx_anndata_file = run_soupx.soupx_anndata_file
    }
}

task run_soupx {

    input {
        String output_dir
        String cellranger_outputs_dir
        String memory
        Int disk_space
        Int cpu
        String docker
        Int preemptible
    }

    command <<<
        set -e

        mkdir -p cellranger_outputs
        gsutil -m rsync -r -x '.*bam.*' ~{cellranger_outputs_dir} cellranger_outputs

        Rscript /soupx.R cellranger_outputs/ cellranger_outputs/soupx_counts.mtx

        python <<CODE
        import os
        import scanpy as sc
        import scipy as sci

        soupx_counts = sci.io.mmread('cellranger_outputs/soupx_counts.mtx')
        soupx_counts = soupx_counts.tocsr()
        soupx_counts = soupx_counts.T
        adata = sc.read_10x_h5('cellranger_outputs/filtered_feature_bc_matrix.h5')
        adata.X = soupx_counts
        adata.write('cellranger_outputs/soupx_corrected_adata.h5ad')

        CODE

        gsutil -m rsync -r outputs ~{output_dir}
    >>>

    output {
        File soupx_anndata_file = 'cellranger_outputs/soupx_corrected_adata.h5ad'
    }

    runtime {
        docker: docker
        memory: memory
        bootDiskSizeGb: 12
        disks: "local-disk " + disk_space + " HDD"
        cpu: cpu
        preemptible: preemptible
    }

}