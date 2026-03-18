#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.sample = 'sample1'

process run_r_script {
  container 'rocker/r-ver:4.4.0'

  input:
  val sampleId
  path script

  output:
  stdout

  script:
  """
  Rscript ${script} ${sampleId}
  """
}

workflow {
  r_script = file("${projectDir}/scripts/hello.R")
  run_r_script(params.sample, r_script)
  run_r_script.out.view()
}
