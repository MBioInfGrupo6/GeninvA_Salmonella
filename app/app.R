# app/app.R
library(shiny)
library(DT)

ui <- fluidPage(
  titlePanel("Proyecto Salmonella - Interfaz"),
  sidebarLayout(
    sidebarPanel(
      fileInput("archivo", "Sube tu archivo TSV de NCBI", accept = ".tsv"),
      numericInput("anio", "Año mínimo", value = 2015),
      numericInput("cepas", "Número de cepas", value = 20),
      actionButton("run", "Ejecutar flujo completo"),
      downloadButton("descargar", "Descargar cepas propuestas")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Consola", verbatimTextOutput("log")),
        tabPanel("Cepas Propuestas", DTOutput("tabla"))
      )
    )
  )
)

server <- function(input, output) {
  observeEvent(input$run, {
    # Lógica para cuando P3/P6 integren todo
    output$log <- renderText({"Ejecutando flujo..."})
  })
  output$tabla <- renderDT({
    data.frame(Mensaje = "Los datos se mostrarán aquí.")
  })
  output$descargar <- downloadHandler(
    filename = function() { "cepas_propuestas.csv" },
    content = function(file) { write.csv(data.frame(), file) }
  )
}
shinyApp(ui, server)