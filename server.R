library(shiny)
library(ggplot2)
library(dplyr)
library(grid)

shinyServer(function(input, output) {
    output$plot <- renderPlot({
        
        # Input from the ui
        inFile <- input$datafile
        if (is.null(inFile))
            return(NULL)
        data <- read.csv(inFile$datapath, header = TRUE, 
                         stringsAsFactors = FALSE)
        drain <- input$drain
        surge_time <- input$time
        
        # Function fo claculate the surge volume. It assimes the liquid flowrate 
        # in bbl/d and it returns the surge in m3
        surge_calc <- function(time, liq, drain) {
            dt <- diff(time)
            mav <- function(x,n=2) {stats::filter(x,rep(1/n,n), sides=2)}
            acc <- (mav(liq) - drain)
            acc[acc<0] <- 0
            cum_acc <- cumsum(acc) * (dt[1]/(24*3600))
            return(cum_acc*0.1589873)
        }
        
        # Here a df for the plotting is created
        surge <- surge_calc(data[, 1], data[, 2], drain*1000)
        df <- data.frame(data)
        df <- cbind(df, 'Surge'=surge)
        df <- cbind(df, 'Surge_12'=surge*1.2)
        df <- cbind(df, 'Surge_08'=surge*0.8)
        
        # Some calcs for the plots
        xintercept = 0.66*surge_time/100*(tail(df['Time'], n=1)/3600)
        discreteXintercept <- findInterval(xintercept, df["Time"][, 1]/3600) 
        s <- df['Surge'][, 1][discreteXintercept]

        # Create the two plots.
        plot1 <- df %>%
            select(Time, Liq) %>%
            na.omit() %>%
            ggplot() +
            geom_line(aes(x = Time/3600, y = Liq/1000, color='Liq. flow'),
                      size = 1.5, alpha = 1) +
            labs(y="Liquid flowrate [kbbl/d]", x="Time [h]",
                 title='Simulated liquid outflow [kbbl/d] (input data)') +
            scale_color_manual(values=c("#CC6666", "#9999CC")) +
            guides(fill=guide_legend(title=NULL)) +
            theme(legend.title=element_blank()) +
            geom_hline(yintercept=drain,
                       linetype="longdash", 
                       color = "blue", size=.75) +
            theme(axis.text=element_text(size=14),
                  axis.title=element_text(size=14,face="bold"))
        plot2 <- df %>%
            select(Time, Surge, Surge_12, Surge_08) %>%
            na.omit() %>%
            ggplot() +
            geom_line(aes(x = Time/3600, y = Surge, color='Surge vol.'), 
                      size = 1.5, alpha = 1) +
            geom_line(aes(x = Time/3600, y = Surge_12, color='Surge vol. + 20%'), 
                      size = 1.5, alpha = 0.75, linetype = "dashed") +
            geom_line(aes(x = Time/3600, y = Surge_08, color='Surge vol. - 20%'), 
                      size = 1.5, alpha = 0.75, linetype = "dotdash") +
            labs(y="Surge [m3]", x="Time [h]", title='Calculated surge volumes') +
            scale_color_manual(values=c("#000000", "#666666", "#666666")) +
            theme(legend.title=element_blank()) +
            geom_vline(xintercept=xintercept,
                       linetype="longdash", 
                       color = "blue", size=.75) +
            theme(axis.text=element_text(size=14),
                  axis.title=element_text(size=14,face="bold"))
        grid.newpage()
        g <- grid.draw(rbind(ggplotGrob(plot1), 
                             ggplotGrob(plot2), size = "last"))
        print(g)
        
        # Data for the table
        surgesValues <- reactive({
            data.frame('Drain' = drain, 'Surge' = s)
        })
        output$surges <- renderTable({
            surgesValues()})
    })
})

