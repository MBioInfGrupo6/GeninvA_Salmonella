# R/01_carga.R
# Carga, normalización y unión de fuentes (Tareas A09 y A10 - P3)

library(tidyverse)
library(janitor)

# Diccionario de sinónimos (Tarea A09)
DICCIONARIO <- c(
  "Assembly" = "accesion_genoma",
  "Assembly.Accession" = "accesion_genoma",
  "Serovar" = "serovar",
  "Location" = "pais",
  "Isolation source" = "fuente",
  "AMR genotypes" = "ram_genotipos",
  "Create date" = "fecha"
)

# Función para listar archivos (mencionada en el manual)
listar_archivos_raw <- function() {
  archivos <- list.files("data/raw", pattern = "\\.(tsv|csv)$", full.names = TRUE)
  if (length(archivos) == 0) {
    message("⚠️ No hay archivos en data/raw. Usando modo demostración.")
    return(NULL) 
  }
  return(archivos)
}

cargar_y_normalizar <- function(archivos) {
  if (is.null(archivos)) {
    stop("No hay archivos para cargar. Por favor, coloca el archivo ncbi_pathogen_isolates.tsv en data/raw/")
  }
  
  archivo_principal <- archivos[grep("ncbi_pathogen", archivos)][1]
  
  if (is.na(archivo_principal)) {
    stop("No se encontró el archivo principal de NCBI en data/raw.")
  }
  
  cat("Leyendo archivo de NCBI...\n")
  datos <- read_tsv(archivo_principal, show_col_types = FALSE) %>%
    clean_names()
  
  # Renombrar columnas usando el diccionario
  nombres_estandar <- janitor::make_clean_names(names(DICCIONARIO))
  valores_estandar <- unname(DICCIONARIO)
  
  for (i in seq_along(nombres_estandar)) {
    if (nombres_estandar[i] %in% names(datos)) {
      names(datos)[names(datos) == nombres_estandar[i]] <- valores_estandar[i]
    }
  }
  
  return(datos)
}

# ==========================================
# EJECUCIÓN DE LA CARGA
# ==========================================
cat("Iniciando carga de datos...\n")
archivos_raw <- listar_archivos_raw()
datos_integrados <- cargar_y_normalizar(archivos_raw)

# Guardar como RDS en data/processed
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
saveRDS(datos_integrados, "data/processed/aislamientos.rds")
cat("✅ Datos guardados en data/processed/aislamientos.rds\n")