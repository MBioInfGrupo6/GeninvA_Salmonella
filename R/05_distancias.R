## ---------------------------------------------------------------------------
## 05_distancias.R  -  Relaciones entre aislamientos y agrupamiento
##
## Usa la información de tipificación que ya viene en los metadatos públicos
## (clúster SNP del NCBI, ST de MLST de EnteroBase) y construye una matriz de
## distancias sobre los perfiles de genes declarados.
## ---------------------------------------------------------------------------

if (!exists("config")) source("config.R")

#' Asigna un grupo genómico a cada aislamiento con la mejor fuente disponible
asignar_grupos <- function(datos) {

  paso(6, "Tipificación, distancias y agrupamiento")

  ## Garantiza que existan las columnas de tipificación
  for (col in c("cluster_snp", "st_enterobase", "st_mlst")) {
    if (!col %in% names(datos)) datos[[col]] <- NA_character_
  }

  datos <- datos |>
    dplyr::mutate(
      grupo_genomico = dplyr::case_when(
        !is.na(cluster_snp) & cluster_snp != ""     ~ paste0("SNP_", cluster_snp),
        !is.na(st_enterobase) & st_enterobase != "" ~ paste0("ST_", st_enterobase),
        !is.na(st_mlst) & st_mlst != ""             ~ paste0("ST_", st_mlst),
        TRUE                                        ~ paste0("SV_", serovar)
      ),
      fuente_tipificacion = dplyr::case_when(
        !is.na(cluster_snp) & cluster_snp != ""     ~ "Clúster SNP (NCBI)",
        !is.na(st_enterobase) & st_enterobase != "" ~ "MLST (EnteroBase)",
        !is.na(st_mlst) & st_mlst != ""             ~ "MLST",
        TRUE                                        ~ "Serovar (aproximación)"
      )
    )

  t_grupos <- datos |>
    dplyr::count(grupo_genomico, fuente_tipificacion, sort = TRUE, name = "n")
  guardar_tabla(t_grupos, "grupos_genomicos")

  message("Grupos genómicos identificados: ", nrow(t_grupos))
  print(knitr::kable(dplyr::count(datos, fuente_tipificacion, name = "n"),
                     caption = "Origen de la tipificación"))

  datos
}

#' Matriz de distancias (Jaccard) entre serovares a partir de los perfiles de genes
#' Devuelve el objeto dist y el dendrograma
distancias_perfiles <- function(genes_largo, min_aislamientos = 5) {

  if (is.null(genes_largo) || nrow(genes_largo) == 0) {
    message("Sin perfiles de genes: se omite la matriz de distancias.")
    return(NULL)
  }

  ## Serovares con suficiente representación
  sv_validos <- genes_largo |>
    dplyr::distinct(id_aislamiento, serovar) |>
    dplyr::count(serovar, name = "n") |>
    dplyr::filter(n >= min_aislamiento_safe(min_aislamientos)) |>
    dplyr::pull(serovar)

  if (length(sv_validos) < 3) {
    message("Menos de 3 serovares con datos suficientes: se omite el dendrograma.")
    return(NULL)
  }

  ## Matriz binaria serovar x gen (gen presente en >=20 % de sus aislamientos)
  tot <- genes_largo |>
    dplyr::distinct(id_aislamiento, serovar) |>
    dplyr::count(serovar, name = "total")

  mat_df <- genes_largo |>
    dplyr::filter(serovar %in% sv_validos) |>
    dplyr::count(serovar, gen, name = "n") |>
    dplyr::left_join(tot, by = "serovar") |>
    dplyr::mutate(presente = as.integer(n / total >= 0.20)) |>
    dplyr::select(serovar, gen, presente) |>
    tidyr::pivot_wider(names_from = gen, values_from = presente,
                       values_fill = 0L)

  m <- as.matrix(mat_df[, -1, drop = FALSE])
  rownames(m) <- mat_df$serovar
  m <- m[, colSums(m) > 0, drop = FALSE]

  if (ncol(m) < 2) {
    message("Perfiles demasiado homogéneos: se omite el dendrograma.")
    return(NULL)
  }

  d <- stats::dist(m, method = "binary")   # distancia de Jaccard
  hc <- stats::hclust(d, method = "average")

  ruta <- file.path(config$dir_figuras, "08_dendrograma_perfiles_ram.png")
  grDevices::png(ruta, width = 2400, height = 1500, res = 220)
  graphics::par(mar = c(4, 2, 4, 10))
  plot(stats::as.dendrogram(hc), horiz = TRUE,
       main = "Similitud de serovares según su perfil de determinantes de RAM",
       xlab = "Distancia de Jaccard")
  grDevices::dev.off()
  message("  -> figura guardada: ", ruta)

  guardar_tabla(
    tibble::as_tibble(as.matrix(d), rownames = "serovar"),
    "matriz_distancias_serovares"
  )

  list(matriz = m, dist = d, hclust = hc)
}

min_aislamiento_safe <- function(x) max(1, as.integer(x))
