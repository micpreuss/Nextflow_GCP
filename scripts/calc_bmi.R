args <- commandArgs(trailingOnly = TRUE)
sample_id <- args[1]
weight_kg <- as.numeric(args[2])
height_cm <- as.numeric(args[3])

height_m <- height_cm / 100
bmi <- weight_kg / (height_m^2)

category <- ifelse(bmi < 18.5, "Underweight",
            ifelse(bmi < 25.0, "Normal",
            ifelse(bmi < 30.0, "Overweight", "Obese")))

result <- data.frame(
  sample    = sample_id,
  weight_kg = weight_kg,
  height_cm = height_cm,
  bmi       = round(bmi, 2),
  category  = category
)

write.csv(result, file = "result.csv", row.names = FALSE)
