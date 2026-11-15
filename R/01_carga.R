# R/01_carga.R
# Carga, normalización y unión de fuentes (Tareas A09 y A10 - P3)

library(tidyverse)
library(janitor)

# 1. Función para listar archivos (con modo demo de respaldo)
listar_archivos_raw <- function() {
  if (!dir.exists("data/raw")) dir.create("data/raw", recursive = TRUE)
  
  archivos <- list.files("data/raw", pattern = "\\.(tsv|csv)$", full.names = TRUE)
  
  if (length(archivos) == 0) {
    message("⚠️ No hay archivos en data/raw. Usando modo demostración.")
    return("data/demo/demo_isolates.tsv")
  }
  return(archivos)
}

# 2. Función principal de carga
cargar_datos <- function() {
  archivos <- listar_archivos_raw()
  
  # Si estamos en modo demo
  if (length(archivos) == 1 && grepl("demo", archivos[1])) {
    message("Usando archivo DEMO...")
    datos <- read_tsv(archivos[1], show_col_types = FALSE) %>% clean_names()
  } else {
    # Si estamos usando datos reales
    archivo_principal <- archivos[grep("ncbi_pathogen", archivos)][1]
    message("Leyendo archivo real de NCBI (esto puede tardar unos segundos)...")
    datos <- read_tsv(archivo_principal, show_col_types = FALSE) %>% clean_names()
  }
  
  # Diccionario de nombres de columnas
  if ("location" %in% names(datos)) datos <- datos %>% rename(pais = location)
  if ("isolation_source" %in% names(datos)) datos <- datos %>% rename(fuente = isolation_source)
  if ("amr_genotypes" %in% names(datos)) datos <- datos %>% rename(ram_genotipos = amr_genotypes)
  if ("asm_acc" %in% names(datos)) datos <- datos %>% rename(accesion_genoma = asm_acc)
  
  # Crear carpeta processed si no existe y guardar el archivo
  if (!dir.exists("data/processed")) dir.create("data/processed", recursive = TRUE)
  saveRDS(datos, "data/processed/aislamientos.rds")
  
  cat("✅ Datos guardados exitosamente en data/processed/aislamientos.rds\n")
  return(datos)
}

# 3. Ejecutar la función (¡Esta era la línea que faltaba!)
cargar_datos()