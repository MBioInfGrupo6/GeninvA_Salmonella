## ---------------------------------------------------------------------------
## 03_exploracion.R  -  Análisis descriptivo de la colección
## ---------------------------------------------------------------------------

if (!exists("config")) source("config.R")

explorar_coleccion <- function(datos, top_n = 15) {

  paso(4, "Análisis exploratorio descriptivo")

  resumen <- list()

  ## --- 1. Serovares --------------------------------------------------------
  t_serovar <- datos |>
    dplyr::count(serovar, sort = TRUE, name = "n") |>
    dplyr::mutate(porcentaje = round(100 * n / sum(n), 2))
  guardar_tabla(t_serovar, "frecuencia_serovares")
  resumen$serovares <- t_serovar

  g1 <- t_serovar |>
    dplyr::slice_head(n = top_n) |>
    ggplot2::ggplot(ggplot2::aes(x = reorder(serovar, n), y = n)) +
    ggplot2::geom_col(fill = "#2C6E91") +
    ggplot2::coord_flip() +
    ggplot2::labs(title = paste("Serovares más frecuentes (top", top_n, ")"),
                  x = NULL, y = "Número de aislamientos") +
    tema_proyecto()
  guardar_figura(g1, "01_serovares_frecuentes")

  ## --- 2. Distribución temporal -------------------------------------------
  if (any(!is.na(datos$anio))) {
    t_anio <- datos |>
      dplyr::filter(!is.na(anio)) |>
      dplyr::count(anio, name = "n")
    guardar_tabla(t_anio, "aislamientos_por_anio")
    resumen$anios <- t_anio

    g2 <- ggplot2::ggplot(t_anio, ggplot2::aes(anio, n)) +
      ggplot2::geom_col(fill = "#4F9D69") +
      ggplot2::labs(title = "Aislamientos por año de recolección",
                    x = "Año", y = "Número de aislamientos") +
      tema_proyecto()
    guardar_figura(g2, "02_aislamientos_por_anio")
  }

  ## --- 3. Países -----------------------------------------------------------
  if (any(!is.na(datos$pais))) {
    t_pais <- datos |>
      dplyr::filter(!is.na(pais)) |>
      dplyr::count(pais, sort = TRUE, name = "n")
    guardar_tabla(t_pais, "aislamientos_por_pais")
    resumen$paises <- t_pais

    g3 <- t_pais |>
      dplyr::slice_head(n = top_n) |>
      ggplot2::ggplot(ggplot2::aes(reorder(pais, n), n)) +
      ggplot2::geom_col(fill = "#A5673F") +
      ggplot2::coord_flip() +
      ggplot2::labs(title = "Distribución geográfica", x = NULL,
                    y = "Número de aislamientos") +
      tema_proyecto()
    guardar_figura(g3, "03_distribucion_paises")
  }

  ## --- 4. Fuente de aislamiento -------------------------------------------
  if (any(!is.na(datos$fuente))) {
    t_fuente <- datos |>
      dplyr::filter(!is.na(fuente)) |>
      dplyr::count(fuente, sort = TRUE, name = "n") |>
      dplyr::slice_head(n = 25)
    guardar_tabla(t_fuente, "fuentes_aislamiento")
    resumen$fuentes <- t_fuente
  }

  ## --- 5. Diversidad -------------------------------------------------------
  frec <- t_serovar$n
  p <- frec / sum(frec)
  resumen$diversidad <- tibble::tibble(
    riqueza_serovares = length(frec),
    shannon           = round(-sum(p * log(p)), 3),
    simpson           = round(1 - sum(p^2), 3),
    n_total           = sum(frec)
  )
  guardar_tabla(resumen$diversidad, "indices_diversidad")
  print(knitr::kable(resumen$diversidad, caption = "Diversidad de la colección"))

  ## --- 6. Serovar x año (mapa de calor) -----------------------------------
  if (any(!is.na(datos$anio))) {
    top_sv <- t_serovar$serovar[seq_len(min(top_n, nrow(t_serovar)))]
    g5 <- datos |>
      dplyr::filter(serovar %in% top_sv, !is.na(anio)) |>
      dplyr::count(serovar, anio, name = "n") |>
      ggplot2::ggplot(ggplot2::aes(anio, reorder(serovar, n), fill = n)) +
      ggplot2::geom_tile(color = "white") +
      ggplot2::scale_fill_gradient(low = "#DCE9F0", high = "#14415A") +
      ggplot2::labs(title = "Serovares por año", x = "Año", y = NULL,
                    fill = "Aislamientos") +
      tema_proyecto()
    guardar_figura(g5, "04_serovar_por_anio")
  }

  resumen
}
