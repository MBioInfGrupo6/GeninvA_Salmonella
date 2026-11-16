# config.R
config <- list(
## --- Rutas ------
  dir_raw       = "data/raw",
  dir_processed = "data/processed",
  dir_figuras   = "resultados/figuras",
  dir_tablas    = "resultados/tablas",
## --- Filtros de la colección ----
  filtro_pais        = NULL,
  filtro_anio_min    = 2015,
  filtro_serovar     = NULL,
  filtro_fuente      = NULL,
## --- Control de calidad ------
  qc_eliminar_duplicados  = TRUE,
  qc_anio_minimo_valido  = 1950,
  filtro_anio_max  = NULL,
  qc_min_campos_completos  = 3,
## --- Selección de cepas -----
  n_cepas_propuestas = 20,
## - Los pesos deben sumar 1 --
  pesos = list(
    representatividad = 0.25,
    diversidad        = 0.25,
    ram               = 0.20,
    metadatos         = 0.20,
    disponibilidad    = 0.10
  ),
##-- Máximo de cepas por serovar en la propuesta final
  max_por_serovar = 3,
##-- Máximo de cepas por clúster genómico
  max_por_cluster = 2,
  semilla = 1234
)
##-- Pesos: comprobación
if (abs(sum(unlist(config$pesos)) - 1) > 1e-8) {
  warning("Los pesos de config$pesos no suman 1. Revísalos.")
}
