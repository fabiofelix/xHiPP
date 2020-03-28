#================================================================================#
#Shiny server to test xHiPP algorithm
#
#Changed: 03/27/2020
#         Change: passing seed value to xHiPP function
#Changed: 12/10/2017
#         Added option to define number of clusters
#Changed: 11/15/2017
#         Removed definition of fileEncoding = "ISO-8859-1" when opening .csv file 
#Changed: 11/13/2017
#         Involke extract.tree.topics.new just when file exists into directory
#         get.file.path didn't generate correct names for .json files
#Changed: 10/04/2017
#         Function evaluate was added
#
#Created    : 05/17/2017
#================================================================================#


library(shiny)
source("xhipp.R");
source("shared/Evaluate_Projection.R");
source("shared/text_mining.R");

# O padrão de upload do shiny é de 5MB (5 * 1024^2 B)
options(shiny.maxRequestSize = 30 * 1024^2);

get.file.path = function(name)
{
  name = tools::file_path_sans_ext(name);
  file.name = name;
  list.names = list.files("www/data/json/", pattern = paste(name, "_hippTree[[:digit:]_]*.json", sep = "") )
  count = "1";
  
  if(length(list.names) > 0)
  {
    list.names = list.names[sort(order(list.names))];
    file.name  = tools::file_path_sans_ext(list.names[length(list.names)]);
    file.name  = unlist(strsplit(file.name, "_hippTree"));
    
    if(length(file.name) > 1)
    {
      count = file.name[length(file.name)];
      count = as.numeric(count);
      count = as.character(ifelse(is.na(count), 2, count + 1));
      file.name = file.name[-length(file.name)]
    }  
  }
  
  return(paste("www/data/json/", file.name, "_hippTree", stringr::str_pad(count, 3, side = "left", pad = "0"), ".json", sep = ""));
}  

my.set.seed = function(value)
{
  seed_value = as.numeric(value);
  
  if(seed_value == -1)
    seed_value = 0
  else if(seed_value == 0)
  {
    seed_value = timestamp(suffix = "", prefix = "", quiet = TRUE);
    seed_value = unlist(strsplit(seed_value, " "));
    seed_value = seed_value[length(seed_value) - 1];
    seed_value = unlist(strsplit(seed_value, ":"));
    seed_value = as.numeric(paste(seed_value[1], seed_value[2], sep = ""));
  }
  
  # if(seed_value > 0)
  #   set.seed(seed_value);  
  
  return(seed_value);
}  

evaluate = function(tree, data, qt_cluster)
{
  projection = tree2table(tree);
  labels = c("black");
  
  if("group" %in% colnames(data))
    labels = data[, "group"];
  
  labels  = as.factor(labels);
  columns = get.numeric.columns(data);
  metrics = calc.metrics(dataset = data[, columns], 
                         data.projection = projection, 
                         projection.name = NULL, 
                         labels = labels, 
                         verbose = FALSE, 
                         qt_cluster = ifelse(qt_cluster == 0, NA, qt_cluster));

  tree$stress = metrics$stress.value;
  tree$np     = metrics$np.value;  
  tree$silhouette = metrics$silhouette.avg;
  tree$nh     = metrics$nh.value;
  
  return(tree);
}

function(input, output, session) 
{
  handle = reactive(
  {
    input$POG; #Permite que seja recarregado sem que algo tenha sido modificado na tela
    input$seed;
    
    s_json    = "[ERROR]: ";
    has_error = FALSE;

    if(is.null(input$userFile))
    {
      s_json = paste(s_json, "Arquivo não encontrado")
    }else
    {
      s_json = tryCatch(
      {
          seed_value = my.set.seed(input$seed);
          operation = input$order;
          process.type = process.types$ordinary;
          qt_cluster = ifelse(is.null(input$qt_cluster) || is.na(input$qt_cluster) || input$qt_cluster == "", 
                              0, as.numeric(input$qt_cluster));
          
          if(input$userFile$type == "application/json" || tools::file_ext(input$userFile$name) == "json")
            operation = "from_cluster";
          if(operation == "from_cluster")
            data = read_json(input$userFile$datapath)[[1]]
          else
          {
            # data = read.csv(input$userFile$datapath, fileEncoding = "ISO-8859-1", stringsAsFactors = FALSE, header = TRUE);
            data = read.csv(input$userFile$datapath, stringsAsFactors = FALSE, header = TRUE);

            if((nrow(data) > 0) && !is.null(data[1, "name"]))
            {
              if(tools::file_ext(data[1, "name"]) == "txt")
                process.type = process.types$text
              else if(tools::file_ext(data[1, "name"]) %in% c("mp3", "wav", "flac"))
                process.type = process.types$audio
              else if(tools::file_ext(data[1, "name"]) %in% c("png", "jpg", "jpeg"))
                process.type = process.types$image;              
            }
          }
          
          tree = xHiPP(data,
                      operation,
                      cluster.algorithm = input$cluster_algorithm,
                      projection.algorithm = input$projection_algorithm,
                      qt_cluster = qt_cluster,                      
                      spread = FALSE,
                      threshold = as.numeric(input$threshold),
                      frac = as.numeric(input$frac),
                      max.iteration = as.numeric(input$max_iteration),
                      process.type = process.type,
                      summary.path = "www/data/aux2",
                      seed = seed_value);

          tree$seed_value = seed_value;
          tree$order      = input$order;
          tree$cluster_algorithm = input$cluster_algorithm;
          tree$projection_algorithm = input$projection_algorithm;
          # tree$qt_cluster = qt_cluster;
          tree$threshold = input$threshold;
          tree$frac = input$frac;
          tree$max_iteration = input$max_iteration;
          
          
          if(operation == "from_cluster")
            data = tree2table(data, by.data = TRUE)$dataset;
          
          tree = evaluate(tree, data, tree$qt_cluster);
          
          if(process.type == process.types$text && !is.null(input$text_path) && !is.na(input$text_path) && length(list.files(input$text_path, pattern = ".txt")) > 0)
            tree = extract.tree.topics.new(tree, input$text_path, data = data, topic.as.group = !("group" %in% colnames(data)))

          toJSON(tree, pretty = TRUE, auto_unbox = TRUE);
      },
      error = function(e)
      {
        has_error = TRUE;
        paste(s_json, e);
      }
      );
    }

    if(!has_error & !is.null(input$userFile))
      jsonlite::write_json(s_json, get.file.path(input$userFile$name));

    session$sendCustomMessage(type = "myCallBackHandler", s_json);
  });

  observeEvent(input$load_button, handle());
  observeEvent(input$load_button_group, handle());
}
