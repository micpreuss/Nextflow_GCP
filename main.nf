#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.sample = 'sample1'

process run_r_script {
  container 'rocker/r-ver:4.4.0'

  input:
  val sampleId
  path script

  output:
  path 'result.txt'

  script:
  """
  Rscript ${script} ${sampleId} > result.txt
  """
}

workflow {
  main:
  r_script = file("${projectDir}/scripts/hello.R")
  ch_results = run_r_script(params.sample, r_script)

  publish:
  r_results = ch_results
}

output {
  r_results {
    path '.'      // Publish to the root of the output directory (results/)
    mode 'copy'   // Copy files (default)
  }
}

// ===========================================================================
// REFERENCE NOTES
// ===========================================================================
//
// --- DSL2 (nextflow.enable.dsl=2) ---
// Nextflow's modern syntax (required since v22+). Enables modular code where
// processes are defined independently and wired together in the workflow block.
// Processes can be reused and called multiple times with different inputs.
//
// --- params ---
// Pipeline-level parameters with defaults defined in the script. Users can
// override them at runtime:  nextflow run main.nf --sample 'mySample'
//
// --- process anatomy ---
//   container  Docker/Singularity image the process runs inside. On GCP
//              (Life Sciences / Batch), Nextflow pulls the image automatically.
//   input:     Declares data the process receives. Two common qualifiers:
//                val   - simple values (strings, numbers), no file staging
//                path  - files; Nextflow stages (copies/links) them into the
//                        process working directory so the script can access
//                        them by filename
//   output:    Declares data the process produces. 'path' captures files
//              after execution and makes them available as a channel.
//              Glob patterns work too, e.g. path '*.txt'
//   script:    Shell commands in triple-quoted strings ("""). Nextflow
//              variables (${var}) are interpolated before the shell sees the
//              command. Use single-quoted strings (''') to let the shell
//              handle its own variables instead.
//
// --- workflow block sections ---
//   main:      Pipeline logic — calling processes, applying channel operators
//   publish:   Assigns channels to named outputs for the output block
//   emit:      Exposes channels when this workflow is imported as a
//              sub-workflow by another pipeline
//
// --- file() and ${projectDir} ---
// file() creates a Path object. ${projectDir} is a built-in variable that
// resolves to the directory containing main.nf — always use it instead of
// relative paths to avoid issues when the launch dir differs.
//
// --- process calls and parallelism ---
// Calling a process returns its output channel. If you pass a channel with
// multiple items, Nextflow automatically runs the process in parallel for
// each item — no explicit loop needed.
//
// --- output block (NEW — requires Nextflow 24.10+) ---
// Replaces the older 'publishDir' process directive. Declared at script
// level (outside the workflow). Each named entry must match a channel
// assigned in the workflow's publish: section.
//
// Advantages over publishDir:
//   - Centralised: all publishing logic lives in one place, not scattered
//     across individual process definitions
//   - Declarative: clearly documents what the pipeline produces, separate
//     from how it computes results
//   - Flexible: supports index files, dynamic paths, labels, and more
//
// Available directives inside each output entry:
//   path          Subdirectory to publish into (relative to outdir)
//   mode          'copy' (default), 'move', 'symlink', 'rellink'
//   overwrite     true/false — whether to overwrite existing files
//   enabled       true/false — conditionally skip publishing
//   index         Generate a metadata catalog (CSV, JSON, or YAML)
//   contentType   Set MIME type (useful for cloud storage)
//   storageClass  Cloud storage class (e.g. 'NEARLINE' on GCP)
//   ignoreErrors  Continue pipeline if publishing fails
//
// The default publish directory is 'results/' in the launch dir. Override
// it globally in nextflow.config or at runtime:
//   nextflow run main.nf --outdir 's3://my-bucket/run1'
// ===========================================================================
