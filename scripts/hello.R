args <- commandArgs(trailingOnly = TRUE)
sample_id <- args[1]

cat(sprintf("Hello from R for %s!\n", sample_id))
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf("Running on: %s\n", Sys.info()["nodename"]))
