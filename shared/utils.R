#================================================================================#
#Set of generic functions
#
#Created: 10/04/2017
#================================================================================#

get.numeric.columns = function(dataset, name.group = NULL)
{
  if(!is.null(dataset))
  {
    dataset = data.frame(dataset);    

    columns = sapply(dataset, function(col)
    {
      return(is.numeric(col));
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
      values = dataset[, i];
      MIN    = min(values)
      
      if(MIN < 0)
        values = values - MIN

      MAX = max(values);
      MIN = min(values);
      
      dataset[, i] = (log10(values + 1) - log10(MIN + 1)) / 
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

adjust.path <- function(path)
{
  my.system = Sys.info()
  my.system = my.system["sysname"]
  my.system = grep("windows", my.system, ignore.case = TRUE)
  
  if(length(my.system) > 0)
    path = gsub("/", "\\\\", path) 
  
  return(path)
}
