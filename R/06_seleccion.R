## ---------------------------------------------------------------------------
## 06_seleccion.R  -  Puntuación multicriterio y propuesta de cepas.
## ---------------------------------------------------------------------------

if (!exists("config")) source("config.R")

proponer_cepas <- function(datos, n = config$n_cepas_propuestas) {

  paso(7, "Puntuación multicriterio y propuesta de cepas")

  p <- config$pesos

  ## --- 1. Métricas por aislamiento ----------------------------------------
  frec_serovar <- dplyr::count(datos, serovar, name = "n_serovar")
  frec_fuente  <- dplyr::count(datos, fuente,  name = "n_fuente")
  frec_grupo   <- dplyr::count(datos, grupo_genomico, name = "n_grupo")

  tabla <- datos |>
    dplyr::left_join(frec_serovar, by = "serovar") |>
    dplyr::left_join(frec_fuente,  by = "fuente") |>
    dplyr::left_join(frec_grupo,   by = "grupo_genomico") |>
    dplyr::mutate(
      ## Representatividad: el serovar y la fuente son habituales en la colección
      sc_representatividad = 0.7 * escalar_01(log1p(n_serovar)) +
                             0.3 * escalar_01(log1p(dplyr::coalesce(n_fuente, 0L))),

      ## Diversidad: premia grupos genómicos poco representados (aportan novedad)
      sc_diversidad = 1 - escalar_01(log1p(n_grupo)),

      ## Interés en RAM: número de determinantes declarados
      sc_ram = escalar_01(n_genes_ram),

      ## Calidad de metadatos
      sc_metadatos = escalar_01(n_metadatos),

      ## Disponibilidad de genoma público
      sc_disponibilidad = as.numeric(tiene_genoma),

      ## Puntuación final 0-100
      puntuacion = round(100 * (
        p$representatividad * sc_representatividad +
        p$diversidad        * sc_diversidad +
        p$ram               * sc_ram +
        p$metadatos         * sc_metadatos +
        p$disponibilidad    * sc_disponibilidad
      ), 2)
    ) |>
    dplyr::arrange(dplyr::desc(puntuacion))

  ## --- 2. Selección con cupos (evita redundancia) -------------------------
  seleccion <- tabla |>
    dplyr::group_by(serovar) |>
    dplyr::slice_head(n = config$max_por_serovar) |>
    dplyr::ungroup() |>
    dplyr::group_by(grupo_genomico) |>
    dplyr::slice_head(n = config$max_por_cluster) |>
    dplyr::ungroup() |>
    dplyr::arrange(dplyr::desc(puntuacion)) |>
    dplyr::slice_head(n = n)

  ## --- 3. Justificación legible -------------------------------------------
  seleccion <- seleccion |>
    dplyr::mutate(
      justificacion = paste0(
        "Serovar ", serovar,
        "; grupo ", grupo_genomico,
        " (", fuente_tipificacion, ")",
        "; ", n_genes_ram, " determinantes de RAM declarados",
        "; metadatos completos en ", n_metadatos, "/4 campos",
        dplyr::if_else(tiene_genoma, "; genoma público disponible",
                       "; sin ensamblado público")
      )
    )

  salida <- seleccion |>
    dplyr::select(
      id_aislamiento, serovar, pais, anio, fuente,
      grupo_genomico, fuente_tipificacion,
      n_genes_ram, n_genes_virulencia, n_metadatos,
      accesion_genoma, puntuacion, justificacion,
      dplyr::starts_with("sc_")
    ) |>
    dplyr::mutate(ranking = dplyr::row_number(), .before = 1)

  guardar_tabla(salida, "cepas_propuestas")
  guardar_tabla(
    tabla |> dplyr::select(id_aislamiento, serovar, puntuacion,
                           dplyr::starts_with("sc_")),
    "puntuacion_todos_los_aislamientos"
  )

  ## --- 4. Figuras ----------------------------------------------------------
  g1 <- salida |>
    ggplot2::ggplot(ggplot2::aes(reorder(paste0(ranking, ". ", id_aislamiento),
                                         puntuacion),
                                 puntuacion, fill = serovar)) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::labs(title = "Cepas propuestas y su puntuación multicriterio",
                  x = NULL, y = "Puntuación (0-100)", fill = "Serovar") +
    tema_proyecto()
  guardar_figura(g1, "09_cepas_propuestas", alto = 8)

  g2 <- salida |>
    dplyr::select(id_aislamiento, dplyr::starts_with("sc_")) |>
    tidyr::pivot_longer(-id_aislamiento, names_to = "criterio",
                        values_to = "valor") |>
    dplyr::mutate(criterio = stringr::str_remove(criterio, "sc_")) |>
    ggplot2::ggplot(ggplot2::aes(criterio, id_aislamiento, fill = valor)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::scale_fill_gradient(low = "#EDF2F4", high = "#1D3557",
                                 limits = c(0, 1)) +
    ggplot2::labs(title = "Contribución de cada criterio a la selección",
                  x = NULL, y = NULL, fill = "Puntaje\nnormalizado") +
    tema_proyecto() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1))
  guardar_figura(g2, "10_criterios_por_cepa", alto = 8)

  message("Propuestas ", nrow(salida), " cepas candidatas.")
  print(knitr::kable(
    salida |> dplyr::select(ranking, id_aislamiento, serovar, pais, anio,
                            n_genes_ram, puntuacion) |>
      head(15),
    caption = "Primeras cepas propuestas"))

  list(propuestas = salida, completa = tabla)
}
