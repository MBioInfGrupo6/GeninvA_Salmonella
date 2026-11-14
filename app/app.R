# app/app.R
# Interfaz Shiny (Tarea A11 - P3)

library(shiny)
library(DT)
library(tidyverse)

# Cargar los datos procesados (usando ../ para salir de la carpeta app)
cargar_datos_seguro <- function() {
  ruta <- file.path("..", "data", "processed", "aislamientos.rds")
  if (file.exists(ruta)) {
    return(readRDS(ruta))
  } else {
    return(NULL) 
  }
}

ui <- fluidPage(
  titlePanel("Proyecto Salmonella en R - Interfaz P3"),
  
  sidebarLayout(
    sidebarPanel(
      h4("1. Subir datos"),
      fileInput("archivo_ncbi", "Sube el archivo TSV de NCBI:", accept = ".tsv"),
      hr(),
      h4("2. Parámetros"),
      numericInput("anio_min", "Año mínimo:", value = 2015),
      numericInput("n_cepas", "Número de cepas propuestas:", value = 20),
      numericInput("max_serovar", "Tope por serovar:", value = 3),
      hr(),
      actionButton("ejecutar", "▶ Ejecutar flujo completo", class = "btn-primary"),
      br(), br(),
      downloadButton("descargar_res", "Descargar Resultados (CSV)")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Estado del Flujo", verbatimTextOutput("log_consola")),
        tabPanel("Tabla de Datos", DTOutput("tabla_datos")),
        tabPanel("Top Serovares", plotOutput("grafico_serovares"))
      )
    )
  )
)

server <- function(input, output, session) {
  
  datos <- reactive({
    cargar_datos_seguro()
  })
  
  observeEvent(input$ejecutar, {
    output$log_consola <- renderText({
      "Iniciando ejecución... (La lógica completa se conectará cuando P4, P5 y P6 suban sus scripts)."
    })
  })
  
  output$tabla_datos <- renderDT({
    if (is.null(datos())) {
      return(datatable(data.frame(Mensaje = "No hay datos. Ejecuta R/01_carga.R primero.")))
    }
    datatable(head(datos(), 1000), options = list(pageLength = 10, scrollX = TRUE))
  })
  
  output$grafico_serovares <- renderPlot({
    req(datos())
    
    top_serovares <- datos() %>%
      count(serovar, sort = TRUE) %>%
      top_n(10, n)
    
    ggplot(top_serovares, aes(x = reorder(serovar, n), y = n, fill = serovar)) +
      geom_col(show.legend = FALSE) +
      coord_flip() +
      theme_minimal() +
      labs(x = "Serovar", y = "Frecuencia", title = "Top 10 Serovares")
  })
  
  output$descargar_res <- downloadHandler(
    filename = function() { "resultados_salmonella.csv" },
    content = function(file) {
      if (is.null(datos())) {
        write.csv(data.frame(Error = "No hay datos cargados"), file)
      } else {
        write.csv(datos(), file)
      }
    }
  )
}

shinyApp(ui, server)