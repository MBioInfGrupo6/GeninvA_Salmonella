# scripts/run_all.R
cat("Iniciando flujo...\n")
source("config.R")
source("R/00_setup.R")
source("R/01_carga.R")
d <- cargar_datos()

# Ejecutar scripts de compañeros si existen
if (file.exists("R/02_qc.R")) source("R/02_qc.R")
if (file.exists("R/03_exploracion.R")) source("R/03_exploracion.R")
if (file.exists("R/04_ram.R")) source("R/04_ram.R")
if (file.exists("R/05_distancias.R")) source("R/05_distancias.R")
if (file.exists("R/06_seleccion.R")) source("R/06_seleccion.R")

cat("✅ Flujo base (P3) completado correctamente.\n")