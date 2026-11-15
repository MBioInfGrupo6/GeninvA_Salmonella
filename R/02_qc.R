## ---------------------------------------------------------------------------
## 02_qc.R  -  Control de calidad, depuración y filtrado
## ---------------------------------------------------------------------------

if (!exists("config")) source("config.R")

#' Control de calidad de la tabla de aislamientos
#' @return lista con `datos` (tabla depurada) y `log` (trazabilidad del QC)
control_calidad <- function(datos) {

  paso(3, "Control de calidad y depuración")

  log_qc <- tibble::tibble(etapa = character(), n = integer(), eliminados = integer())
  registrar <- function(log, etapa, n_actual, n_previo) {
    dplyr::bind_rows(log, tibble::tibble(etapa = etapa, n = n_actual,
                                         eliminados = n_previo - n_actual))
  }

  n0 <- nrow(datos)
  log_qc <- registrar(log_qc, "Entrada", n0, n0)

  ## 1. Registros sin identificador utilizable
  datos <- dplyr::filter(datos, !is.na(id_aislamiento), id_aislamiento != "")
  log_qc <- registrar(log_qc, "Con identificador", nrow(datos), n0)

  ## 2. Duplicados
  if (isTRUE(config$qc_eliminar_duplicados)) {
    n <- nrow(datos)
    datos <- dplyr::distinct(datos, id_aislamiento, .keep_all = TRUE)
    log_qc <- registrar(log_qc, "Sin duplicados", nrow(datos), n)
  }

  ## 3. Años imposibles -> NA
  anio_actual <- as.integer(format(Sys.Date(), "%Y"))
  datos <- datos |>
    dplyr::mutate(anio = dplyr::if_else(
      !is.na(anio) & (anio < config$qc_anio_minimo_valido | anio > anio_actual),
      NA_integer_, anio))

  ## 4. Completitud de metadatos clave
  claves <- c("serovar", "pais", "anio", "fuente")
  completo <- function(x) {
    x <- as.character(x)
    !is.na(x) & x != "" & x != "No determinado"
  }
  datos$n_metadatos <- Reduce(`+`, lapply(claves, function(k) as.integer(completo(datos[[k]]))))

  n <- nrow(datos)
  datos <- dplyr::filter(datos, n_metadatos >= config$qc_min_campos_completos)
  log_qc <- registrar(log_qc, "Metadatos suficientes", nrow(datos), n)

  ## 5. Filtros definidos por el usuario en config.R
  aplicar_filtro <- function(d, columna, valores, etiqueta) {
    if (is.null(valores) || !columna %in% names(d)) return(d)
    n <- nrow(d)
    d <- d[!is.na(d[[columna]]) &
             stringr::str_detect(stringr::str_to_lower(as.character(d[[columna]])),
                                 stringr::str_c(stringr::str_to_lower(valores),
                                                collapse = "|")), ]
    log_qc <<- registrar(log_qc, etiqueta, nrow(d), n)
    d
  }

  datos <- aplicar_filtro(datos, "pais",    config$filtro_pais,    "Filtro país")
  datos <- aplicar_filtro(datos, "serovar", config$filtro_serovar, "Filtro serovar")
  datos <- aplicar_filtro(datos, "fuente",  config$filtro_fuente,  "Filtro fuente")

  if (!is.null(config$filtro_anio_min)) {
    n <- nrow(datos)
    datos <- dplyr::filter(datos, is.na(anio) | anio >= config$filtro_anio_min)
    log_qc <- registrar(log_qc, "Filtro año mínimo", nrow(datos), n)
  }
  if (!is.null(config$filtro_anio_max)) {
    n <- nrow(datos)
    datos <- dplyr::filter(datos, is.na(anio) | anio <= config$filtro_anio_max)
    log_qc <- registrar(log_qc, "Filtro año máximo", nrow(datos), n)
  }

  if (nrow(datos) == 0) {
    stop("El QC dejó 0 registros. Relaja los filtros de config.R.")
  }

  log_qc <- registrar(log_qc, "Salida", nrow(datos), nrow(datos))

  print(knitr::kable(log_qc, caption = "Trazabilidad del control de calidad"))
  guardar_tabla(log_qc, "log_control_calidad")
  saveRDS(datos, file.path(config$dir_processed, "aislamientos_qc.rds"))

  list(datos = datos, log = log_qc)
}
