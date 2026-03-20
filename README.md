# Nextflow_GCP

Small example Nextflow DSL2 pipeline for calculating BMI from a CSV samplesheet, with profiles for local execution and Google Cloud Batch.

## What This Repo Does

The pipeline reads a samplesheet with `sample`, `weight_kg`, and `height_cm` columns, runs one BMI calculation per sample in parallel using an R script, and publishes:

- `results/per_sample/*.csv`: one output file per sample
- `results/bmi_summary.csv`: combined summary table

The main workflow lives in `main.nf`, and runtime profiles are defined in `nextflow.config`.

## Repository Layout

- `main.nf`: pipeline entry point
- `nextflow.config`: local and GCP execution settings
- `data/samplesheet.csv`: example input
- `scripts/calc_bmi.R`: per-sample BMI calculation

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

The `gcp` profile is configured for Google Batch and Docker. Run the pipeline directly from GitHub:

```bash
nextflow run micpreuss/Nextflow_GCP -profile gcp
```

To pull the latest version before running:

```bash
nextflow run micpreuss/Nextflow_GCP -profile gcp -latest
```

To resume a failed or interrupted run (reuses cached results from completed tasks):

```bash
nextflow run micpreuss/Nextflow_GCP -profile gcp -latest -resume
```

### Prerequisites

The GCS bucket must exist before running the pipeline (one-time setup):

```bash
gcloud storage buckets create gs://northwell-nextflow --project=lencz-lab-cogent-1 --location=us-central1
```

### GCP Defaults

- Google project: `lencz-lab-cogent-1`
- Region: `us-central1`
- Shared bucket root: `gs://northwell-nextflow`
- Project slug: `nextflow-gcp`
- Work directory pattern: `gs://northwell-nextflow/nextflow-gcp/work/$USER`
- Output directory pattern: `gs://northwell-nextflow/nextflow-gcp/results/$USER`

This keeps cached work isolated by user while still steering everyone in the group toward a common bucket layout.

### Viewing Results on GCS

List your published results:

```bash
gcloud storage ls gs://northwell-nextflow/nextflow-gcp/results/<your-username>/
```

Quick-peek at a file without downloading:

```bash
gcloud storage cat gs://northwell-nextflow/nextflow-gcp/results/<your-username>/bmi_summary.csv
```

Replace `<your-username>` with your system username (the value of `$USER`).

### Overrides

Override the shared bucket at runtime if needed:

```bash
nextflow run micpreuss/Nextflow_GCP -profile gcp --gcp_bucket gs://my-team-bucket
```

## How It Works

1. `main.nf` reads the samplesheet from `params.samplesheet`
2. Each CSV row is converted into a tuple of sample metadata
3. The `calc_bmi` process runs `scripts/calc_bmi.R` once per sample (in parallel)
4. The `merge_results` process concatenates all per-sample CSVs into `bmi_summary.csv`
5. Results are published through the centralized `output {}` block

## Notes For Contributors

- Most of the project logic is concentrated in `main.nf`
- The pipeline is currently more of a compact example than a production-ready workflow
- The existing `results/` and `work/` directories are runtime artifacts from prior executions
