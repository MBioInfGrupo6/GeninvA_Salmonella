## ---------------------------------------------------------------------------
## 04_ram.R  -  Perfil de resistencia a antimicrobianos y de virulencia
##
## Trabaja únicamente con las anotaciones YA PUBLICADAS por el repositorio
## (columnas "AMR genotypes" / "Virulence genotypes"). No predice ni infiere
## resistencias nuevas: resume lo que la base de datos declara.
## ---------------------------------------------------------------------------

if (!exists("config")) source("config.R")

#' Convierte el campo de genotipos en una tabla larga id - gen
expandir_genes <- function(datos, columna = "genes_ram") {
  if (!columna %in% names(datos)) return(tibble::tibble())
  datos |>
    dplyr::select(id_aislamiento, serovar, valor = dplyr::all_of(columna)) |>
    dplyr::filter(!is.na(valor), valor != "") |>
    dplyr::mutate(valor = stringr::str_split(valor, ",")) |>
    tidyr::unnest(valor) |>
    dplyr::mutate(
      gen = valor |>
        stringr::str_trim() |>
        stringr::str_remove("=.*$") |>      # quita "=COMPLETE", "=PARTIAL"
        stringr::str_remove("\\*$")
    ) |>
    dplyr::filter(gen != "") |>
    dplyr::distinct(id_aislamiento, serovar, gen)
}

analizar_ram <- function(datos, top_n = 25) {

  paso(5, "Perfil de resistencia y virulencia")

  resultado <- list()

  genes_largo <- expandir_genes(datos, "genes_ram")

  if (nrow(genes_largo) == 0) {
    message("El archivo no trae columna de genotipos de RAM: se omite el paso 5.")
    return(resultado)
  }

  ## --- 1. Frecuencia de determinantes -------------------------------------
  t_genes <- genes_largo |>
    dplyr::count(gen, sort = TRUE, name = "n_aislamientos") |>
    dplyr::mutate(prevalencia_pct = round(100 * n_aislamientos /
                                            dplyr::n_distinct(datos$id_aislamiento), 2))
  guardar_tabla(t_genes, "frecuencia_genes_ram")
  resultado$genes <- t_genes

  g1 <- t_genes |>
    dplyr::slice_head(n = top_n) |>
    ggplot2::ggplot(ggplot2::aes(reorder(gen, n_aislamientos), n_aislamientos)) +
    ggplot2::geom_col(fill = "#B3454F") +
    ggplot2::coord_flip() +
    ggplot2::labs(title = "Determinantes de resistencia más frecuentes",
                  subtitle = "Según las anotaciones del repositorio público",
                  x = NULL, y = "Número de aislamientos") +
    tema_proyecto()
  guardar_figura(g1, "05_genes_ram_frecuentes")

  ## --- 2. Matriz de presencia/ausencia (gen x serovar) --------------------
  top_genes <- t_genes$gen[seq_len(min(top_n, nrow(t_genes)))]
  top_sv <- datos |> dplyr::count(serovar, sort = TRUE) |>
    dplyr::slice_head(n = 15) |> dplyr::pull(serovar)

  matriz <- genes_largo |>
    dplyr::filter(gen %in% top_genes, serovar %in% top_sv) |>
    dplyr::count(serovar, gen, name = "n") |>
    dplyr::left_join(dplyr::count(datos, serovar, name = "total"), by = "serovar") |>
    dplyr::mutate(prevalencia = round(100 * n / total, 1))
  guardar_tabla(matriz, "matriz_ram_serovar")
  resultado$matriz <- matriz

  g2 <- ggplot2::ggplot(matriz, ggplot2::aes(gen, serovar, fill = prevalencia)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::scale_fill_gradient(low = "#F6E7E6", high = "#8C1C24",
                                 limits = c(0, 100)) +
    ggplot2::labs(title = "Prevalencia de determinantes de RAM por serovar",
                  x = NULL, y = NULL, fill = "% aislamientos") +
    tema_proyecto() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 60, hjust = 1))
  guardar_figura(g2, "06_mapa_calor_ram", ancho = 11, alto = 7)

  ## --- 3. Carga de resistencia por aislamiento ----------------------------
  carga <- datos |>
    dplyr::select(id_aislamiento, serovar, n_genes_ram) |>
    dplyr::mutate(categoria = dplyr::case_when(
      n_genes_ram == 0      ~ "Sin determinantes",
      n_genes_ram <= 2      ~ "1-2",
      n_genes_ram <= 5      ~ "3-5",
      n_genes_ram <= 9      ~ "6-9",
      TRUE                  ~ ">=10"
    ))
  t_carga <- dplyr::count(carga, categoria, name = "n")
  guardar_tabla(t_carga, "carga_ram_por_aislamiento")
  resultado$carga <- t_carga

  g3 <- carga |>
    dplyr::filter(serovar %in% top_sv) |>
    ggplot2::ggplot(ggplot2::aes(reorder(serovar, n_genes_ram, median),
                                 n_genes_ram)) +
    ggplot2::geom_boxplot(fill = "#E3B23C", outlier.size = 0.6) +
    ggplot2::coord_flip() +
    ggplot2::labs(title = "Número de determinantes de RAM por serovar",
                  x = NULL, y = "Genes declarados por aislamiento") +
    tema_proyecto()
  guardar_figura(g3, "07_carga_ram_por_serovar")

  ## --- 4. Virulencia -------------------------------------------------------
  vir_largo <- expandir_genes(datos, "genes_virulencia")
  if (nrow(vir_largo) > 0) {
    t_vir <- vir_largo |> dplyr::count(gen, sort = TRUE, name = "n_aislamientos")
    guardar_tabla(t_vir, "frecuencia_genes_virulencia")
    resultado$virulencia <- t_vir
  }

  resultado$genes_largo <- genes_largo
  resultado
}
