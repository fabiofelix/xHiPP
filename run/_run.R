
#Main Hipp directory
xHIPP.PATH = "C:\\Users\\avell\\Desktop\\xHiPP";

#TCP port where shiny server will works. Change in RUN_CLIENT.bat, as well.
SERVER.TCP.PORT = 4907

pkg.dependences = function()
{
  p = installed.packages()
  p = rownames(p)
  needed.packages = c("jsonlite", "mp", "umap", "doParallel", "tm", "topicmodels", "SnowballC", "shiny", "mime",
                      "stringr")
  
  for(i in 1:length(needed.packages))
  { 
    if( !(needed.packages[i] %in%  p))
      install.packages(needed.packages[i])
  }  
}

pkg.dependences();
shiny::runApp(xHIPP.PATH, launch.browser = FALSE, port = SERVER.TCP.PORT);
