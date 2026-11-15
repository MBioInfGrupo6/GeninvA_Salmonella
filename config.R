# config.R
config <- list(
  dir_raw       = "data/raw",
  dir_processed = "data/processed",
  dir_figuras   = "resultados/figuras",
  dir_tablas    = "resultados/tablas",
  filtro_pais        = NULL,
  filtro_anio_min    = 2015,
  filtro_serovar     = NULL,
  filtro_fuente      = NULL,
  qc_min_campos_completos  = 3,
  n_cepas_propuestas = 20,
  pesos = list(
    representatividad = 0.25,
    diversidad        = 0.25,
    ram               = 0.20,
    metadatos         = 0.20,
    disponibilidad    = 0.10
  ),
  max_por_serovar = 3,
  max_por_cluster = 2,
  semilla = 1234
)