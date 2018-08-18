
setwd("/home/fabio/Documentos/Mestrado/Pesquisa/Hipp")
# setwd("/home/fabio/Documents/Pesquisa/Hipp")

source("hipp.R");
source("shared/Evaluate_Projection.R");
source("shared/text_mining.R");

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
  
  if(seed_value > 0)
    set.seed(seed_value);  
  
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

#==============================================================================================================================#

PATH = "~/Documentos/Mestrado/Pesquisa/data/all_30_1000_paper.csv"
# PATH = "~/Documents/Pesquisa/data/AP_BBC_CNN_Reuters_nosource_nodate_novo.csv"
#OPERATION = "cluster_projection"
OPERATION = "projection_cluster"
PROJECTION = "tsne"
CLUSTER = "kmeans"
QT.CLUSTER = 0

seed_value = 2102;
processing.text = FALSE;

if(OPERATION == "from_cluster")
{
  data = read_json(PATH)[[1]]
}else
{
  # data = read.csv(input$userFile$datapath, fileEncoding = "ISO-8859-1", stringsAsFactors = FALSE, header = TRUE);
  data = read.csv(PATH, stringsAsFactors = FALSE, header = TRUE);
  processing.text = (nrow(data) > 0) && !is.null(data[1, "name"]) && (tools::file_ext(data[1, "name"]) == "txt");
}

tree = HiPP(data,
            OPERATION,
            cluster.algorithm = CLUSTER,
            projection.algorithm = PROJECTION,
            qt_cluster = QT.CLUSTER,                      
            spread = FALSE,
            threshold = 0.1,
            frac = 4.0,
            max.iteration = 20,
            processing.text = processing.text,
            summary.path = "www/data/aux2");

tree$seed_value = seed_value;
tree$order      = OPERATION;
tree$cluster_algorithm = CLUSTER;
tree$projection_algorithm = PROJECTION;
# tree$qt_cluster = qt_cluster;
tree$threshold = 0.1;
tree$frac = 4.0;
tree$max_iteration = 20;


if(OPERATION == "from_cluster")
  data = tree2table(data, by.data = TRUE)$dataset;

tree = evaluate(tree, data, tree$qt_cluster);

# if(processing.text && !is.null("data/text/") && !is.na("data/text/") && length(list.files("data/text/", pattern = ".txt")) > 0)
if(processing.text && length(list.files("www/data/text", pattern = ".txt")) > 0)
  tree = extract.tree.topics.new(tree, "www/data/text", data = data, topic.as.group = TRUE)

s_json = toJSON(tree, pretty = TRUE, auto_unbox = TRUE);

jsonlite::write_json(s_json, get.file.path(basename(PATH)));
