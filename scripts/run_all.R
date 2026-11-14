# scripts/run_all.R
# Script maestro para ejecutar todo el flujo del proyecto (Tarea A29 - P3)

cat("Iniciando flujo de trabajo completo...\n")
tiempo_inicio <- Sys.time()

# 0. Cargar configuración
if (file.exists("config.R")) source("config.R")

# 1. Configurar entorno
source("R/00_setup.R")

# 2. Carga y limpieza inicial (P3)
source("R/01_carga.R")

# 3. Scripts de los compañeros (se ejecutan si existen)
if (file.exists("R/02_qc.R")) source("R/02_qc.R") else cat("⚠️ Falta R/02_qc.R (P4)\n")
if (file.exists("R/03_exploracion.R")) source("R/03_exploracion.R") else cat("⚠️ Falta R/03_exploracion.R (P4)\n")
if (file.exists("R/04_ram.R")) source("R/04_ram.R") else cat("⚠️ Falta R/04_ram.R (P5)\n")
if (file.exists("R/05_distancias.R")) source("R/05_distancias.R") else cat("⚠️ Falta R/05_distancias.R (P5)\n")
if (file.exists("R/06_seleccion.R")) source("R/06_seleccion.R") else cat("⚠️ Falta R/06_seleccion.R (P6)\n")

# 4. Generar el informe (si existe)
if (file.exists("reporte/reporte.Rmd")) {
  rmarkdown::render("reporte/reporte.Rmd", output_file = "reporte_salmonella.html")
} else {
  cat("⚠️ Falta reporte/reporte.Rmd (P6)\n")
}

tiempo_fin <- Sys.time()
cat("\n✅ Flujo completo terminado en", round(difftime(tiempo_fin, tiempo_inicio, units = "secs"), 2), "segundos.\n")