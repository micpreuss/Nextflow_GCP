# Nextflow_GCP

Small example Nextflow DSL2 pipeline for calculating BMI from a CSV samplesheet, with profiles for local execution and Google Cloud Batch.

## What This Repo Does

The pipeline reads a samplesheet with `sample`, `weight_kg`, and `height_cm` columns, runs one BMI calculation per sample in parallel using an R script, and publishes:

- `results/per_sample/*.csv`: one output file per sample
- `results/per_sample/manifest.csv`: index of published per-sample files
- `results/bmi_summary.csv`: combined summary table

The main workflow lives in `main.nf`, and runtime profiles are defined in `nextflow.config`.

## Repository Layout

- `main.nf`: pipeline entry point
- `nextflow.config`: local and GCP execution settings
- `data/samplesheet.csv`: example input
- `scripts/calc_bmi.R`: per-sample BMI calculation
- `scripts/hello.R`: unused helper/example script

Generated run artifacts such as `work/`, `results/`, `.nextflow/`, and `.nextflow.log*` are intentionally ignored by Git.

## Requirements

- Nextflow with DSL2 support
- Docker
- R is provided through the container image `rocker/r-ver:4.4.0`, so no local R install is required for normal runs

This pipeline uses the script-level `output {}` block in `main.nf`, which requires a recent Nextflow release.

## Input Format

Default input: `data/samplesheet.csv`

Expected columns:

```csv
sample,weight_kg,height_cm
sample01,72.5,175
sample02,85.3,180
```

You can supply a different file at runtime with `--samplesheet`.

## Run Locally

Run the included example with the local profile:

```bash
nextflow run main.nf -profile test
```

Run with a custom samplesheet:

```bash
nextflow run main.nf -profile test --samplesheet /path/to/samplesheet.csv
```

Local runs use:

- `process.executor = 'local'`
- `docker.enabled = true`
- `workDir = 'work'`

## Run On GCP

The `gcp` profile is configured for Google Batch and Docker:

```bash
nextflow run main.nf -profile gcp
```

The committed defaults are designed for shared use within one project group:

- Google project: `lencz-lab-cogent-1`
- Region: `us-east1`
- Shared bucket root: `gs://northwell-nextflow`
- Project slug: `nextflow-gcp`
- Work directory pattern: `gs://northwell-nextflow/nextflow-gcp/work/$USER`
- Output directory pattern: `gs://northwell-nextflow/nextflow-gcp/results/$USER/<runName>`

This keeps cached work isolated by user while still steering everyone in the group toward a common bucket layout.

Override the shared bucket at runtime if needed:

```bash
nextflow run main.nf -profile gcp --gcp_bucket gs://my-team-bucket
```

You can also create an untracked `nextflow.local.config` for personal overrides. The repository will load it automatically if present.

Example:

```groovy
params {
  gcp_bucket = 'gs://my-team-bucket'
  user = 'alice'
}

google {
  project = 'my-gcp-project'
  location = 'us-central1'
}
```

## How It Works

1. `main.nf` reads the samplesheet from `params.samplesheet`
2. Each CSV row is converted into a tuple of sample metadata
3. The `calc_bmi` process runs `scripts/calc_bmi.R` once per sample
4. Per-sample CSV outputs are collected into a single `bmi_summary.csv`
5. Results are published through the centralized `output {}` block

## Notes For Contributors

- Most of the project logic is concentrated in `main.nf`
- The pipeline is currently more of a compact example than a production-ready workflow
- `scripts/hello.R` is not referenced by the workflow
- The existing `results/` and `work/` directories are runtime artifacts from prior executions
- Personal config belongs in `nextflow.local.config`, which is ignored by Git
