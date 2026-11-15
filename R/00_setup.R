## ---------------------------------------------------------------------------
## 00_setup.R  -  Dependencias, carpetas y utilidades comunes
## ---------------------------------------------------------------------------

## 1. Paquetes ---------------------------------------------------------------
paquetes_necesarios <- c(
  "tidyverse",   # manipulación y gráficos
  "janitor",     # limpieza de nombres de columnas
  "readr",
  "stringr",
  "scales",
  "knitr",
  "rmarkdown"
)

paquetes_opcionales <- c(
  "vegan",       # índices de diversidad
  "ape",         # árboles / dendrogramas
  "pheatmap",    # mapas de calor
  "shiny",       # carga interactiva de archivos
  "DT"
)

instalar_si_falta <- function(pkgs) {
  faltan <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(faltan) > 0) {
    message("Instalando: ", paste(faltan, collapse = ", "))
    install.packages(faltan, repos = "https://cloud.r-project.org")
  }
  invisible(TRUE)
}

if (interactive() && !isTRUE(getOption("salmonella.skip_install"))) {
  instalar_si_falta(paquetes_necesarios)
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
})

tiene_paquete <- function(p) requireNamespace(p, quietly = TRUE)

## 2. Configuración y carpetas ----------------------------------------------
if (!exists("config")) source("config.R")

for (d in c(config$dir_raw, config$dir_processed,
            config$dir_figuras, config$dir_tablas,
            file.path(config$dir_raw, "secuencias"))) {
  if (!dir.exists(d)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

set.seed(config$semilla)

## 3. Utilidades -------------------------------------------------------------

#' Mensaje de etapa, para seguir el flujo en consola
paso <- function(n, texto) {
  cat("\n", strrep("=", 70), "\n",
      "PASO ", n, ": ", texto, "\n",
      strrep("=", 70), "\n", sep = "")
}

#' Guardar un data frame como CSV en resultados/tablas
guardar_tabla <- function(df, nombre) {
  ruta <- file.path(config$dir_tablas, paste0(nombre, ".csv"))
  # write_excel_csv añade la marca BOM: Excel muestra bien las tildes y la ñ
  readr::write_excel_csv(df, ruta)
  message("  -> tabla guardada: ", ruta)
  invisible(ruta)
}

#' Guardar un gráfico ggplot en resultados/figuras
guardar_figura <- function(plot, nombre, ancho = 9, alto = 6) {
  ruta <- file.path(config$dir_figuras, paste0(nombre, ".png"))
  ggplot2::ggsave(ruta, plot, width = ancho, height = alto, dpi = 300, bg = "white")
  message("  -> figura guardada: ", ruta)
  invisible(ruta)
}

#' Escala 0-1 robusta (devuelve 0 si no hay variación)
escalar_01 <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x[is.na(x)] <- 0
  rango <- range(x, na.rm = TRUE)
  if (!is.finite(diff(rango)) || diff(rango) == 0) return(rep(0, length(x)))
  (x - rango[1]) / diff(rango)
}

#' Tema gráfico común
tema_proyecto <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title    = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position  = "right"
    )
}

message("Setup completado. R ", getRversion())
