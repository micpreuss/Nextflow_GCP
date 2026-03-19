#!/usr/bin/env nextflow
nextflow.enable.dsl=2
params.samplesheet = "${projectDir}/data/samplesheet.csv"

process calc_bmi {
  container 'rocker/r-ver:4.4.0'

  input:
  tuple val(sample), val(weight_kg), val(height_cm)
  path script

  output:
  path "${sample}_bmi.csv"

  script:
  """
  Rscript ${script} ${sample} ${weight_kg} ${height_cm}
  """
}

workflow {
  main:
  ch_samples = channel
    .fromPath(params.samplesheet) 
    .splitCsv(header: true)
    .map { row -> tuple(row.sample, row.weight_kg, row.height_cm) } // Convert each CSV row into a tuple of (sample, weight_kg, height_cm)

  r_script = file("${projectDir}/scripts/calc_bmi.R")
  ch_bmi = calc_bmi(ch_samples, r_script) // Call the calc_bmi process for each sample tuple (parallel), passing the R script as a parameter and collecting the resulting 'result.csv' files into ch_bmi 
  ch_summary = ch_bmi.collectFile(name: 'bmi_summary.csv', keepHeader: true, skip: 1) // Collect all result.csv files into one summary, keeping the header from the first file and skipping it in subsequent files

  publish:
  bmi_results = ch_bmi
  bmi_summary = ch_summary
}

output {
  bmi_results {
    path 'per_sample'
    mode 'copy'
    index {
      path 'per_sample/manifest.csv'
    }
  }
  bmi_summary {
    path '.'
    mode 'copy'
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
// override them at runtime:  nextflow run main.nf --samplesheet '/path/to/sheet.csv'
//
// --- process anatomy ---
//   container  Docker/Singularity image the process runs inside. On GCP
//              (Life Sciences / Batch), Nextflow pulls the image automatically.
//   input:     Declares data the process receives. Two common qualifiers:
//                val   - simple values (strings, numbers), no file staging
//                path  - files; Nextflow stages (copies/links) them into the
//                        process working directory so the script can access
//                        them by filename
//                tuple - groups multiple qualifiers into a single channel item,
//                        keeping related values together (e.g. sample + metadata)
//   output:    Declares data the process produces. 'path' captures files
//              after execution and makes them available as a channel.
//              Glob patterns work too, e.g. path '*.txt'
//   script:    Shell commands in triple-quoted strings ("""). Nextflow
//              variables (${var}) are interpolated before the shell sees the
//              command. Use single-quoted strings (''') to let the shell
//              handle its own variables instead.
//
// --- Channel.fromPath + splitCsv ---
// fromPath() creates a channel from a file path. splitCsv(header: true) parses
// each row into a map keyed by column names. .map {} transforms each row into
// the shape needed by the process (here a tuple of three values).
//
// --- .collect() ---
// Gathers all items emitted by a channel into a single list. Used here to wait
// for all parallel BMI calculations to finish before merging into one summary.
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
// each item — no explicit loop needed. Here, 10 CSV rows = 10 parallel tasks.
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
//   index         Generate a metadata catalog (CSV, JSON, or YAML) listing
//                 all files published under this entry with their paths
//   contentType   Set MIME type (useful for cloud storage)
//   storageClass  Cloud storage class (e.g. 'NEARLINE' on GCP)
//   ignoreErrors  Continue pipeline if publishing fails
//
// The default publish directory is 'results/' in the launch dir. Override
// it globally in nextflow.config or at runtime:
//   nextflow run main.nf --outdir 's3://my-bucket/run1'
// ===========================================================================
