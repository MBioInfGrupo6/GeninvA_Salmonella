## ---------------------------------------------------------------------------
## 01_carga.R  -  Carga e integración de los archivos descargados
##
## Reconoce TSV/CSV del NCBI Pathogen Detection, EnteroBase y NCBI Datasets,
## normaliza los nombres de columna y construye una única tabla de trabajo.
## ---------------------------------------------------------------------------

if (!exists("config")) source("config.R")
if (!exists("paso"))   source("R/00_setup.R")

## --- Diccionario de sinónimos de columnas ----------------------------------
## clave = nombre estándar interno ; valor = posibles nombres en los archivos
DICCIONARIO <- list(
  id_aislamiento = c("isolate", "isolate_identifiers", "strain", "uberstrain",
                     "name", "assembly_accession", "biosample"),
  serovar        = c("serovar", "serotype", "computed_types", "serovar_cdc",
                     "predicted_serotype", "serovar_antigenic_formula"),
  pais           = c("location", "country", "geographic_location", "geo_loc_name",
                     "source_niche_country"),
  anio           = c("collection_date", "create_date", "year", "collection_year",
                     "date", "isolation_year"),
  fuente         = c("isolation_source", "source_details", "source_type",
                     "source_niche", "host"),
  tipo_muestra   = c("isolation_type", "source_niche", "sample_type"),
  cluster_snp    = c("snp_cluster", "pdg_cluster", "snp_cluster_id", "hc100"),
  min_dif        = c("min_diff", "min_distance_to_different", "mindiff"),
  min_igual      = c("min_same", "mindsame", "min_distance_to_same"),
  genes_ram      = c("amr_genotypes", "amr_genotypes_core", "amr_genes",
                     "resistance_genes"),
  genes_virulencia = c("virulence_genotypes", "virulence_genes"),
  fenotipo_ast   = c("ast_phenotypes", "amr_phenotypes"),
  accesion_genoma = c("asm_acc", "assembly", "assembly_accession",
                      "genbank_accession", "refseq_accession"),
  st_mlst        = c("st", "mlst_st", "sequence_type", "achtman_7_gene_st")
)

#' Renombra las columnas de un data frame al vocabulario interno
normalizar_columnas <- function(df) {
  # suppressWarnings evita los avisos de transliteración de janitor cuando el
  # sistema no usa una configuración regional UTF-8 (no afecta al resultado)
  df <- suppressWarnings(janitor::clean_names(df))
  actuales <- names(df)
  for (estandar in names(DICCIONARIO)) {
    if (estandar %in% actuales) next
    candidato <- intersect(DICCIONARIO[[estandar]], actuales)
    if (length(candidato) > 0) {
      names(df)[names(df) == candidato[1]] <- estandar
      actuales <- names(df)
    }
  }
  df
}

#' Lee CSV o TSV detectando el separador
leer_tabla <- function(ruta) {
  ext <- tolower(tools::file_ext(ruta))
  if (ext %in% c("tsv", "txt", "tab")) {
    readr::read_tsv(ruta, show_col_types = FALSE, guess_max = 10000,
                    na = c("", "NA", "null", "-", "missing"))
  } else {
    readr::read_csv(ruta, show_col_types = FALSE, guess_max = 10000,
                    na = c("", "NA", "null", "-", "missing"))
  }
}

#' Muestra qué archivos hay en data/raw y qué espera el proyecto
listar_archivos_raw <- function(dir = config$dir_raw) {
  esperados <- c("ncbi_pathogen_isolates.tsv",
                 "enterobase_strains.csv",
                 "ncbi_genomes.csv")
  presentes <- list.files(dir, pattern = "\\.(csv|tsv|txt)$", ignore.case = TRUE)
  
  cat("\nArchivos encontrados en ", dir, ":\n", sep = "")
  if (length(presentes) == 0) {
    cat("  (ninguno) -> lee data/raw/INSTRUCCIONES_DESCARGA.md\n")
  } else {
    for (f in presentes) {
      tam <- round(file.size(file.path(dir, f)) / 1024, 1)
      cat(sprintf("  [OK] %-40s %8s KB\n", f, tam))
    }
  }
  faltan <- setdiff(esperados, presentes)
  if (length(faltan) > 0) {
    cat("\nNo encontrados (opcionales salvo el primero):\n")
    for (f in faltan) cat("  [ - ] ", f, "\n", sep = "")
  }
  invisible(list(presentes = presentes, faltan = faltan))
}

#' Extrae el año de cadenas de fecha heterogéneas
extraer_anio <- function(x) {
  x <- as.character(x)
  anio <- stringr::str_extract(x, "(18|19|20)\\d{2}")
  as.integer(anio)
}

#' Limpia el país a partir de campos tipo "Colombia: Bogota"
extraer_pais <- function(x) {
  x <- as.character(x)
  x <- stringr::str_split_fixed(x, ":", 2)[, 1]
  x <- stringr::str_trim(x)
  x[x == "" | is.na(x)] <- NA_character_
  x
}

#' Limpia la etiqueta de serovar
limpiar_serovar <- function(x) {
  x <- as.character(x)
  x <- stringr::str_remove_all(x, "(?i)salmonella enterica( subsp\\.? \\w+)?")
  x <- stringr::str_remove_all(x, "(?i)serovar|serotype|=|\\bspp\\.?")
  x <- stringr::str_trim(stringr::str_squish(x))
  x[x == "" | is.na(x)] <- "No determinado"
  x
}

## ---------------------------------------------------------------------------
## Función principal de carga
## ---------------------------------------------------------------------------
cargar_datos <- function(archivo_principal = NULL, dir = config$dir_raw) {
  
  paso(2, "Carga e integración de datos")
  
  ## 1. Archivo principal (NCBI Pathogen Detection u otro que indiques)
  if (is.null(archivo_principal)) {
    candidatos <- list.files(dir, pattern = "(pathogen|isolate).*\\.(tsv|csv|txt)$",
                             ignore.case = TRUE, full.names = TRUE)
    if (length(candidatos) == 0) {
      candidatos <- list.files(dir, pattern = "\\.(tsv|csv)$",
                               ignore.case = TRUE, full.names = TRUE)
    }
    if (length(candidatos) == 0) {
      listar_archivos_raw(dir)
      stop("No hay archivos en ", dir,
           ". Descarga los datos siguiendo data/raw/INSTRUCCIONES_DESCARGA.md")
    }
    archivo_principal <- candidatos[1]
  }
  
  message("Archivo principal: ", basename(archivo_principal))
  datos <- leer_tabla(archivo_principal) |> normalizar_columnas()
  
  ## 2. Asegurar que existan las columnas internas mínimas
  minimas <- names(DICCIONARIO)
  for (col in minimas) {
    if (!col %in% names(datos)) datos[[col]] <- NA
  }
  
  ## 3. Derivar variables limpias
  datos <- datos |>
    dplyr::mutate(
      id_aislamiento = dplyr::coalesce(as.character(id_aislamiento),
                                       paste0("ISO_", dplyr::row_number())),
      serovar  = limpiar_serovar(serovar),
      pais     = extraer_pais(pais),
      anio     = extraer_anio(anio),
      fuente   = stringr::str_to_lower(stringr::str_trim(as.character(fuente))),
      n_genes_ram        = contar_genes(genes_ram),
      n_genes_virulencia = contar_genes(genes_virulencia),
      tiene_genoma       = !is.na(accesion_genoma) &
        as.character(accesion_genoma) != ""
    )
  
  ## 4. Integrar el archivo de genomas, si existe
  f_genomas <- list.files(dir, pattern = "genomes.*\\.(csv|tsv)$",
                          ignore.case = TRUE, full.names = TRUE)
  if (length(f_genomas) > 0) {
    message("Integrando metadatos de genomas: ", basename(f_genomas[1]))
    gen <- leer_tabla(f_genomas[1]) |> normalizar_columnas()
    if ("accesion_genoma" %in% names(gen)) {
      gen <- gen |>
        dplyr::transmute(accesion_genoma = as.character(accesion_genoma),
                         genoma_en_catalogo = TRUE) |>
        dplyr::distinct(accesion_genoma, .keep_all = TRUE)
      datos <- datos |>
        dplyr::mutate(accesion_genoma = as.character(accesion_genoma)) |>
        dplyr::left_join(gen, by = "accesion_genoma") |>
        dplyr::mutate(tiene_genoma = tiene_genoma |
                        !is.na(genoma_en_catalogo))
    }
  }
  
  ## 5. Integrar EnteroBase (ST de MLST), si existe
  f_entero <- list.files(dir, pattern = "enterobase.*\\.(csv|tsv)$",
                         ignore.case = TRUE, full.names = TRUE)
  if (length(f_entero) > 0) {
    message("Integrando EnteroBase: ", basename(f_entero[1]))
    ent <- leer_tabla(f_entero[1]) |> normalizar_columnas()
    if (all(c("id_aislamiento", "st_mlst") %in% names(ent))) {
      ent <- ent |>
        dplyr::transmute(id_aislamiento = as.character(id_aislamiento),
                         st_enterobase  = as.character(st_mlst)) |>
        dplyr::distinct(id_aislamiento, .keep_all = TRUE)
      datos <- dplyr::left_join(datos, ent, by = "id_aislamiento")
    }
  }
  
  ## 6. Registro de la descarga (reproducibilidad)
  registrar_descarga(archivo_principal, nrow(datos))
  
  ## 7. Guardar
  if (!dir.exists(config$dir_processed)) dir.create(config$dir_processed, recursive = TRUE)
  saveRDS(datos, file.path(config$dir_processed, "aislamientos.rds"))
  message("Cargados ", format(nrow(datos), big.mark = ".", decimal.mark = ","),
          " aislamientos y ", ncol(datos), " variables.")
  
  datos
}

#' Cuenta genes en campos del tipo "aac(6')-Iaa=COMPLETE,blaTEM-1=COMPLETE"
contar_genes <- function(x) {
  x <- as.character(x)
  purrr::map_int(x, function(s) {
    if (is.na(s) || s == "") return(0L)
    length(unique(stringr::str_trim(stringr::str_split_1(s, ","))))
  })
}

#' Deja constancia de qué archivo se usó y cuándo
registrar_descarga <- function(ruta, n_filas) {
  reg <- file.path(config$dir_raw, "REGISTRO_DESCARGAS.md")
  if (!file.exists(reg)) {
    writeLines(c("# Registro de descargas", "",
                 "| Fecha de carga | Archivo | Filas |",
                 "|---|---|---|"), reg)
  }
  cat(sprintf("| %s | %s | %d |\n", Sys.Date(), basename(ruta), n_filas),
      file = reg, append = TRUE)
}





