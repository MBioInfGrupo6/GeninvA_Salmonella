# R/00_setup.R
paquetes <- c("tidyverse", "janitor", "knitr", "rmarkdown", "shiny", "DT")
for (p in paquetes) {
  if (!require(p, character.only = TRUE)) install.packages(p)
  library(p, character.only = TRUE)
}
cat("Entorno listo.\n")