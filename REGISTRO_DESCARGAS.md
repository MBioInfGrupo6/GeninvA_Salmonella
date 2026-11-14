# REGISTRO DE DESCARGAS

## Proyecto: Análisis bioinformático de Salmonella enterica

**Responsable:** P2  
**Fecha de consulta:** 12-13 de noviembre de 2026

### 1. NCBI Pathogen Detection

- Fuente: https://www.ncbi.nlm.nih.gov/pathogens/isolates/
- Organismo: Salmonella enterica.
- Periodo configurado: 01/01/2015 al 12/11/2026.
- Países: todos.
- Serovares: todos.
- Fuentes de aislamiento: todas.
- Registros descargados: 753 638.
- Columnas seleccionadas: 17.
- Formato: TSV.
- Archivo: ncbi_pathogen_isolates.tsv.

### 2. EnteroBase

- Fuente: https://enterobase.warwick.ac.uk/species/index/senterica
- Esquema buscado: Achtman 7 Gene MLST.
- Resultado: no se logró recuperar la información debido a errores técnicos durante las consultas.
- Decisión: se omitió esta fuente con aprobación de P1.
- No se generó una base de datos de EnteroBase.

### 3. NCBI Datasets

- Fuente: https://www.ncbi.nlm.nih.gov/datasets/
- Organismo: Salmonella enterica.
- Genomas disponibles mostrados durante la consulta: 640 968.
- Identificadores Assembly extraídos de la base principal: 505 119 únicos.
- Se realizó una consulta de prueba con 10 accesiones.
- Se recuperaron 10 ensamblados únicos y sus respectivos BioSamples.
- Se identificaron metadatos de fecha de recolección, serovar, aislamiento y nivel del ensamblado.

Archivo de muestra: assembly_test_clean_unique.tsv.

### 4. Herramientas utilizadas

- R 4.6.2.
- RStudio Desktop.
- NCBI Datasets CLI.
- NCBI Dataformat.

### 5. Observaciones y limitaciones

- La base principal se descargó correctamente.
- EnteroBase se omitió por problemas técnicos, con aprobación de P1.
- La descarga completa de los metadatos de NCBI Datasets queda pendiente.
- El archivo de 10 ensamblados corresponde únicamente a una prueba técnica y no representa la colección completa.
- Los archivos originales se conservaron sin modificar.
