# config.R
# Parámetros globales del proyecto

# Filtros de datos
filtro_pais <- NULL # Ejemplo: c("Colombia", "Spain")
filtro_anio_min <- 2015
filtro_serovar <- NULL
filtro_fuente <- NULL
qc_min_campos_completos <- 3

# Parámetros de selección
n_cepas_propuestas <- 20
max_por_serovar <- 3
max_por_cluster <- 2
semilla <- 1234

# Pesos de la puntuación (deben sumar 1)
pesos <- c(
  representatividad = 0.25,
  diversidad = 0.25,
  ram = 0.20,
  metadatos = 0.20,
  disponibilidad = 0.10
)