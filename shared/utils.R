#================================================================================#
#Set of generic functions
#
#Changed: 08/13/2018
#         Added plot.stem function
#Changed: 08/12/2018
#         Added moving.avg function
#Changed: 05/01/2018
#         Changed evaluate.norm to evaluate distances
#Changed: 04/06/2018
#         Changed function one.hot.encoding: columns description with original name
#Changed: 04/02/2018
#         Added function: one.hot.encoding
#Changed: 12/22/2017
#         Added functions: evaluate.norm
#Changed: 12/02/2017
#         Added functions: format.data2heatmap, convert.filename2datetime
#Changed: 11/25/2017
#         Added function remove.zero.columns
#Changed: 11/20/2017
#         Added function wav2flac.dir
#Changed: 11/15/2017
#         Improviment in norm.stand caculus
#Changed: 10/30/2017
#         Added option "tanh" to norm.stand
#Changed: 10/23/2017
#         Added norm.stand2
#         Added option "maxabs" to norm.stand
#Changed: 10/17/2017
#         Added function: abc
#Changed: 10/10/2017
#         Added convertion to data.frame in get.numeric.columns 
#Changed: 10/06/2017
#         add sigmoidal (sig) normalization
#Changed: 10/04/2017
#         norm.stand doesn't need to receive from and to parameters
#
#Created: 10/04/2017
#================================================================================#

require(seewave)

get.numeric.columns = function(dataset, name.group = NULL)
{
  if(!is.null(dataset))
  {
    dataset = data.frame(dataset);    

    columns = sapply(dataset, function(col)
    {
      return(is.numeric(col));
      # aux = unique(col);
      # return(is.numeric(col) && (length(aux) != 1 || aux != 0));
    });
    
    if(!is.null(name.group) && !is.na(name.group))
    {
      test_name  = !grepl(name.group[1], colnames(dataset));
      test_group = !grepl(name.group[2], colnames(dataset));
      
      columns = as.numeric(which(columns & test_name & test_group));
    }else
      columns = as.numeric(which(columns));
    
    return(columns)
  }
}


norm.stand = function(dataset, type)
{
  if(class(dataset) != "data.frame" & class(dataset) != "matrix")
    dataset = matrix(dataset);
  
  columns = get.numeric.columns(dataset);  
  
  if(type == "maxabs")
  {
    for(i in columns)
    {
      MAX = max(abs(dataset[, i]));
      dataset[, i] = dataset[, i] / ifelse(MAX == 0, 1, MAX);
    }
  }else if(type == "minmax")
  {
    for(i in columns)
    {
      MAX = max(dataset[, i]);
      MIN = min(dataset[, i]);
      dataset[, i] = (dataset[, i] - MIN) / ifelse(MIN == MAX, 1, MAX - MIN)        
    }
  }else if(type == "square")
  {
    for(i in columns)
    {
      MIN = min(dataset[, i]);
      
      if(MIN < 0)
      {
        dataset[, i] = dataset[, i] + abs(MIN)
        MIN = 0
      }                                 
      
      MAX = max(dataset[, i]);
      dataset[, i] = (sqrt(dataset[, i]) - sqrt(MIN)) / 
        ifelse(sqrt(MIN) == sqrt(MAX), 1, sqrt(MAX) - sqrt(MIN) )        
    }    
  }else if(type == "log")
  {
    for(i in columns)
    {
      MAX = max(dataset[, i]);
      MIN = min(dataset[, i]);
      dataset[, i] = (log10(dataset[, i] + 1) - log10(MIN + 1)) / 
        ifelse(log10( MIN + 1 ) == log10(MAX + 1), 1, log10(MAX + 1) - log10(MIN + 1))              
    }  
  }else if(type == "vecnorm")
  {  
    for(i in columns)
    {
      dataset[, i] = dataset[, i] / sqrt(sum(dataset[, i]**2))
    }      
  }else if(type == "zscore")
  {
    for(i in columns)
    {
      SD = sd(dataset[, i]);
      dataset[, i] = (dataset[, i] - mean(dataset[, i])) / ifelse(SD == 0, 1, SD)
    }      
  }else if(type == "sig")
  {
    dataset = norm.stand(dataset, "zscore");
    dataset[, columns] = 1 / (1 + exp(-dataset[, columns]));
  }else if(type == "tanh")
  {
    dataset = norm.stand(dataset, "zscore");
    dataset[, columns] = tanh(dataset[, columns]);
  }
  
  return(dataset);
}

norm.stand2 = function(dataset, type, min.vector = NA, max.vector = NA, mean.vector = NA, sd.vector = NA)
{
  columns = get.numeric.columns(dataset);
  
  if(type == "minmax")
  {
    for(i in columns)
    {
      dataset[, i] = (dataset[, i] - min.vector[i]) / 
        ifelse(min.vector[i] == max.vector[i], 1, max.vector[i] - min.vector[i])
    }  
  }else if(type == "zscore")
  {
    for(i in columns)
    {
      dataset[,i] = (dataset[,i] - mean.vector[i]) / ifelse(sd.vector[i] == 0, 1, sd.vector[i])
    }  
  }else if(type == "sig")
  {
    dataset = norm.stand2(dataset, "zscore", mean.vector = mean.vector, sd.vector = sd.vector);
    dataset[, columns] = 1 / (1 + exp(-dataset[, columns]));
  }
  
  return(dataset);
}

#Piecewise Aggregate Approximation. It reduces the dimentionality of a sequence of values
PAA = function(values, window.size = 100, by.median = FALSE, stand = TRUE)
{
  if(stand)
    values = norm.stand(as.matrix(values), "zscore");
  
  qt.window = ceiling(length(values) / window.size) 
  centers = c();
  
  for(i in 1:qt.window)
  {
    first.index = 1 + (window.size * (i - 1))
    last.index  = ifelse(i == qt.window, length(values), i * window.size);    
    
    if(by.median)
      centers = c(centers, median(values[first.index:last.index]))
    else
      centers = c(centers, mean(values[first.index:last.index]));
  }
  
  return(centers);  
}

#Não sei que nome dar pra essa função
abc = function(value)
{
  return(ifelse(is.null(value) || is.na(value), 0, value))
}

wav2flac.dir = function(source.path, reverse.param, target.path = source.path)
{
  if(dir.exists(source.path) & dir.exists(target.path))    
  {
    source.type = ".wav";
    target.type = ".flac";
    
    if(reverse.param)
    {
      source.type = ".flac"
      target.type = ".wav";
    }  
    
    list.item = list.files(source.path, full.names = TRUE, pattern = source.type);  
    
    if(length(list.item) > 0)
    {
      for(i in 1:length(list.item))
      {
        name = basename(list.item[[i]]);
        name = tools::file_path_sans_ext(name);
        wav2flac(list.item[[i]], reverse = reverse.param);        
        
        if(source.path != target.path)
        {
          path1 = dirname(list.item[[i]]);
          path1 = file.path(path1, paste(name, target.type, sep = ""));
          path2 = file.path(target.path, paste(name, target.type, sep = ""));
          file.rename(path1, path2);
        }  
      }
    }
  }
}

remove.zero.columns = function(dataset)
{
  dataset = dataset[, get.numeric.columns(dataset)];
  sum     = colSums(dataset)
  
  for(i in 1:length(sum))
  {
    if(sum[i] == 0)
      dataset = dataset[, -i];
  }
  
  return(dataset)
}

# CostaRica, Purdue => 015089_20150306_114500.flac
# Canada    => ICLISTENHF1288_20150323T003850.952Z.wav
# Ilheus, Laje => 2014.09.18_10.00.01.wav
convert.filename2datetime = function(filename, type)
{
  name.parts = unlist(strsplit(as.character(filename), "_"));
  
  d = name.parts[2];
  h = name.parts[3];
  
  if(type == "Canada")
  {
    a = unlist(strsplit(as.character(filename), "_"))[2];
    d = unlist(strsplit(as.character(a), "T"))[1];
    h = unlist(strsplit(as.character(a), "T"))[2];
  }else if(type == "Ilheus" || type == "Laje")
  {
    d = unlist(strsplit(as.character(filename), "_"))[1];
    h = unlist(strsplit(as.character(filename), "_"))[2];
    
    d = gsub("\\.", "", d);
    h = gsub("\\.", "", h);
  }
  
  h = substr(h, 1, 6);
  #===============================================================#  
  
  year  = as.integer(substr(d, 1, 4)); 
  month = as.integer(substr(d, 5, 6));
  day   = as.integer(substr(d, 7, 8));
  
  hour   = as.integer(substr(h, 1, 2));   
  minute = as.integer(substr(h, 3, 4));
  second = as.integer(substr(h, 5, 6));
  
  return(ISOdatetime(year, month, day, hour, minute, second));  
}

# row.format = "%d/%m/%Y"
# col.format = "%H:%M"
# type (cf. convert.filename2datetime)
format.data2heatmap = function(dataset, column.id, column.value, column.row.col, row.format, col.format, type, CONVERT.FUNCTION)
{
  new = data.frame(name="", row="", col="", value=0.0, stringsAsFactors = FALSE);
  new = new[0, ]
  
  for(i in 1:nrow(dataset))
  {
    row.col = CONVERT.FUNCTION(dataset[i, column.row.col], type);
    
    new[i, "name"]  = dataset[i, column.id];
    new[i, "row"]   = format(row.col, row.format);
    new[i, "col"]   = format(row.col, col.format);
    new[i, "value"] = dataset[i, column.value];
  }
  
  return(new);
}

evaluate.norm = function(dataset, labels, distance = FALSE)
{
  data.backup = dataset;
  types  = c("maxabs", "minmax", "square", "log", "vecnorm", "zscore", "sig", "tanh");
  values = c();
  
  list.norm = list(maxabs=NULL, minmax=NULL, square=NULL, log=NULL, vecnorm=NULL, zscore=NULL, sig=NULL, tanh=NULL);
  
  for(i in 1:length(types))
  {
    data = data.backup;
    data = norm.stand(data, types[i]);
    
    if(distance)
      list.norm[[types[i]]] = data
    
    silhouette.value = silhouette(as.numeric(labels), dist(data));
    values = c(values, summary(silhouette.value)$avg.width)
  }
  
  if(distance)
  {
    cat("Plotting Distance Scatterplot\n")    
    plot.distance(data.backup, list.norm, ylab = "Normalized", save = TRUE)
    cat("Plotting Distance Histogram\n")    
    distance.histogram(data.backup, list.norm, save = TRUE)
  }
  
  ord = order(values);
  values = data.frame(silhueta = values[ord], row.names = types[ord]);
  
  if(distance)
    cat("Silhouette order\n")
  
  return(values)
}

one.hot.encoding = function(data, column)
{
  for(i in 1:length(column))
  {
    values = unique(data[, column[i]])
    values = values[order(values)]
    
    for(j in 1:length(values))
    {
      data[data[, column[i]] == values[j], paste(column[i], values[j], sep = "_")] = 1
      data[data[, column[i]] != values[j], paste(column[i], values[j], sep = "_")] = 0
    }
  }

  return(data)
}

moving.avg = function(x, window = 3)
{
  padding = floor(window / 2)
  x.new   = c(rep(0, padding), x, rep(0, padding))  
  x.mean = c()
  
  for(i in (padding + 1):(length(x.new) - padding))
    x.mean = c(x.mean, mean(x.new[(i - padding):(i + padding)]))
  
  return(x.mean);
}

plot.stem = function(x, ...)
{
  # x_min = min(x, na.rm = TRUE) - 1;
  x_min = min(x, na.rm = TRUE);
  plot(x, col = "red", ...)
  
  for(i in 1:length(x))
    lines(c(i, i), c(x_min, x[i]), col = "blue", lwd = 2)    
}

