
# INSTRUCCIONES DE DESCARGA

## Proyecto: Análisis bioinformático de Salmonella enterica

### 1. NCBI Pathogen Detection

1. Ingresar a https://www.ncbi.nlm.nih.gov/pathogens/isolates/.
2. Seleccionar Salmonella enterica.
3. Configurar la fecha de colección desde 01/01/2015 hasta 12/11/2026.
4. Mantener todos los países, serovares y fuentes de aislamiento.
5. Seleccionar las columnas disponibles de identificación, serovar, localización, fuente, SNP cluster, BioSample, Assembly y AMR genotypes.
6. Descargar la tabla completa en formato TSV.

Nombre del archivo: ncbi_pathogen_isolates.tsv.

### 2. EnteroBase

Se intentó recuperar información utilizando el esquema Achtman 7 Gene MLST.

La plataforma presentó errores técnicos durante las consultas. Por acuerdo del grupo, esta fuente se omitió del conjunto inicial.

### 3. NCBI Datasets

1. Ingresar a https://www.ncbi.nlm.nih.gov/datasets/genome/.
2. Seleccionar Salmonella enterica.
3. Consultar los genomas disponibles.
4. Seleccionar los metadatos de Assembly, BioSample, GenBank, RefSeq, nivel del ensamblado y fecha de publicación.
5. Utilizar NCBI Datasets CLI para consultar las accesiones mediante archivos de entrada.
6. Convertir los informes JSONL a TSV mediante Dataformat.

Para la prueba inicial se utilizaron 10 accesiones.

### 4. Herramientas utilizadas

- R 4.6.2.
- RStudio Desktop.
- NCBI Datasets CLI.
- NCBI Dataformat.
- EnteroBase.

### 5. Consideraciones

Los archivos de prueba de NCBI Datasets no representan la totalidad de los genomas disponibles.

Se recomienda conservar los datos originales y realizar la depuración en etapas posteriores mediante scripts reproducibles en R.
