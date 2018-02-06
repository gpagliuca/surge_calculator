library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
    
    # Application title
    titlePanel("Surge volume calculator"),
    
    # Sidebar
    sidebarLayout(
        sidebarPanel(
            helpText("Use:",
                     br(),
                     "Load sim data and set your drain",
                     br(),
                     br(),
                     "Note:",
                     br(),
                     "- Time must be in seconds",
                     br(),
                     "- Liq. flow must be in bbl/d",
                     br(),
                     "- Drain unit must be in kbbl/d",
                     br(),
                     "- Calculated surges are in m3"),
            br(),
            fileInput('datafile', 'Choose CSV File',
                      accept=c('text/csv', 
                               'text/comma-separated-values,text/plain', 
                               '.csv')),
            sliderInput("drain",
                        "Drain rate [kbbl/d]", min = 0, max = 200,
                        value = 20),
            sliderInput("time",
                        "Time (% of the sim time)", min = 0, max = 100,
                         value = 50),
            br(),
            tableOutput("surges")),

    # Main
    mainPanel(
        plotOutput(outputId = "plot", height = "750px"),
        tableOutput("values")
))))
