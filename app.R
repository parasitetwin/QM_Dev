##Shiny app###
library(shiny)
library(shinyjs)
library(shinydashboard)
library(shinydashboardPlus)
library(shinyFiles)
library(shinyWidgets)
library(data.table)
library(future)
library(RSQLite)
library(xcms)
library(openxlsx) #probably not needed
library(tidyverse)
library(slackr)
library(promises)
library(cpc)
library(heatmaply)
library(ipc)
library(processx)
library(htmlwidgets)

oldWD<-getwd()
setwd("R/")
source.list<-list.files()
sapply(source.list, source)
setwd(oldWD)

plan(sequential)
colors<-c("green", "red", "darkblue", "orange", "black")
#colors<-setNames(colors,"green", "red", "darkblue", "orange", "black")

# Defining UI ---
ui<-dashboardPage(
  skin="yellow",
  dashboardHeader(title="QualiMon"),

  dashboardSidebar(
    sidebarMenu(
      menuItem("Tutorial", tabName="tutorial", icon=icon("book")),
      menuItem("Setup", tabName="setup", icon=icon("desktop"), startExpanded=F,
               menuSubItem("Find LaMas & New DB", tabName="findLamas", icon=icon("search")),
               menuSubItem("Set-up Wizard", tabName="configWiz", icon=icon("magic")),
               menuSubItem("Find S&H limits", tabName="findLimits", icon=icon("grip-lines"))
      ),
      menuItem("Monitor data", tabName="monitorData", icon=icon("signal"), startExpanded=F,
               menuSubItem("Live monitor", tabName="liveMonitor", icon=icon("signal")),
               menuSubItem("LaMa chromatograms", tabName="chroms", icon=icon("chart-area"))
      ),
      menuItem("Review old data", tabName="oldData", icon=icon("chart-line")),
      menuItem("Run batch", tabName="runBatch", icon=icon("boxes"))
    )
  ),

  dashboardBody(
    tabItems(
      tabItem("tutorial", tutorialUI("tutorial")),
      tabItem("findLamas", findLamasUI("findLamas")), #findLamasUI("findLamas")
      tabItem("configWiz", configWizUI("configWiz")),
      tabItem("runBatch", runBatchUI("runBatch")),
      tabItem("findLimits", findLimitsUI("findLimits")),
      tabItem("liveMonitor", monitorUI("monitor")),
      tabItem("oldData", examineDataUI("examineData")),
      tabItem("chroms", chromatogramUI("chroms"))
    )
  )
)

# Main app server ---
server <- function(input, output, session){
  r<-reactiveValues()

  plan(multisession)

  r$configWiz<-reactiveValues()
  r$monitor<-reactiveValues()
  #r$mainTabs<-reactive({input$mainTabs})
  r$examineData<-reactiveValues()
  observe({
    r$configWiz$roots<-getVolumes()()
  })
  r$chroms <- reactiveValues()
  r$findLamas <- reactiveValues()
  r$runBatch <- reactiveValues()




  ###Running module servers
  configWizServer("configWiz", r)
  monitorServer("monitor", r)
  examineDataServer("examineData", r)
  chromatogramServer("chroms", r)
  tutorialServer("tutorial", r)
  findLamasServer("findLamas", r)
  runBatchServer("runBatch", r)
  findLimitsServer("findLimits", r)


  ###Session end
  onSessionStart = isolate({
    r$runBatch$running <- F
    r$monitor$start <- F
  })

  session$onSessionEnded(function() {
    plan(sequential)
    stopApp()
  })
}

# Run the app ----
shinyApp(ui = ui, server = server)
