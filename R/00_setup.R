# R/00_setup.R
# Script de configuración del entorno (Tarea A04 - P3)

paquetes_necesarios <- c("tidyverse", "readr", "janitor", "knitr", "rmarkdown", "shiny", "DT")

instalar_si_falta <- function(paquete) {
  if (!require(paquete, character.only = TRUE)) {
    install.packages(paquete, dependencies = TRUE)
    library(paquete, character.only = TRUE)
  }
}

invisible(lapply(paquetes_necesarios, instalar_si_falta))

cat("✅ Entorno listo. Todos los paquetes necesarios están instalados.\n")