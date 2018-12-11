#================================================================================#
#Functions to evaluate Multidimentional projections
#             
#Changed: 05/01/2018
#         Added distance.histogram function
#Changed: 03/23/2018
#         Added configuration in evaluate.projection and calc.metrics to identiy which metric need to be calculated
#Changed: 12/10/2017
#         Added evaluate.HiPP
#         Added option to define qt_cluster in neighborhood.hit and neighborhood.preservation
#Changed: 11/28/2017
#         Added evaluate.original.data
#Changed: 11/12/2017
#         Changed exibition of Neiborhood Hit and Preservation
#Changed: 11/11/2017
#         Added plot.distance
#Changed: 10/26/2017
#         Change plot configs
#Changed: 10/20/2017
#         Change plot configs
#Changed: 10/04/2017
#
#Created: 05/08/2017
#================================================================================#

require(cluster) 
require(mp)

stress = function(X, Y)  
{
  if(is.null(X) || is.na(X) || is.null(Y) || is.na(Y) )
  {
    stop("matrizes nao informadas");
  }  
  if(nrow(X) != nrow(Y))
  {
    stop("quantidade de linhas das matrizes difere");
  }
  
  dist_x  = as.matrix(dist(X));
  dist_y  = as.matrix(dist(Y));
  
  dif_dist_xy = dist_x - dist_y;
  dif_dist_xy = dif_dist_xy^2;
  dif_dist_xy = dif_dist_xy[lower.tri(dif_dist_xy)];
  sum_dif_xy  = sum(dif_dist_xy);
  
  power_dist_x = dist_x^2;
  power_dist_x = power_dist_x[lower.tri(power_dist_x)];
  sum_dist_x   = sum(power_dist_x); 
  
  return(sqrt(sum_dif_xy / sum_dist_x));
}

neighborhood.aux = function(row, index, k, class = NULL)
{
  row        = sort(row, index.return = TRUE);
  list_index = row$ix[-which(row$ix == index)];
  list_index = sort(list_index[1:k]);
  
  if(is.null(class) || is.na(class))
    return(list_index)
  else
    return(length(which(class[list_index] == class[index])));
}

neighborhood.hit = function(projected, class, k = floor(sqrt(nrow(projected))))
{
  if(is.null(projected) || is.na(projected))
    stop("projected matrix not found");
  if(is.null(class) || is.na(class))
    stop("class not found");  
  if(is.null(k) || is.na(k))
    k = floor(sqrt(nrow(projected)));
  
  projected = as.matrix(dist(projected));
  sum       = 0;
  
  for(i in 1:nrow(projected))
  {
    sum = sum + neighborhood.aux(projected[i, ], i, k, class);
  }
  
  return(sum / (k * nrow(projected)) );
}

# neighborhood.preservation.old = function(original, projected, class, k = floor(sqrt(nrow(original))))
# {
#   if(is.null(original) || is.na(original))
#     stop("original matrix not found");
#   if(is.null(projected) || is.na(projected))
#     stop("projected matrix not found");  
#   if(is.null(class) || is.na(class))
#     stop("class not found");  
#   if(is.null(k) || is.na(k))
#     k = floor(sqrt(nrow(original)));  
#   
#   dist_o = as.matrix(dist(original));
#   dist_p = as.matrix(dist(projected));
#   sum    = 0;
#   
#   for(i in 1:nrow(dist_o))
#   {
#     Po = neighborhood.aux(dist_o[i, ], i, k, class);
#     Pp = neighborhood.aux(dist_p[i, ], i, k, class);
#     
#     sum = sum + Pp / ifelse(Po == 0, 1, Po);
#   }  
#   
#   return(sum / nrow(dist_o)); 
# }

neighborhood.preservation = function(original, projected, k = floor(sqrt(nrow(original))))
{
  if(is.null(original) || is.na(original))
    stop("original matrix not found");
  if(is.null(projected) || is.na(projected))
    stop("projected matrix not found");  
  if(is.null(k) || is.na(k))
    k = floor(sqrt(nrow(original)));  
  
  original  = as.matrix(dist(original));
  projected = as.matrix(dist(projected));
  Sum       = 0;
  
  for(i in 1:nrow(original))
  {
    neighorO = neighborhood.aux(original[i, ], i, k);
    neighorP = neighborhood.aux(projected[i, ], i, k);
    
    Sum = Sum + sum(neighorO %in% neighorP, na.rm = TRUE) / length(neighorO);
  }  
  
  return(Sum / nrow(original)); 
}

distance.scatterplot = function(original, projected, desc = "", show.label = TRUE)
{
  if(class(original) != "dist")
    original = dist(original[, get.numeric.columns(original)])
  if(class(projected) != "dist")
    projected = dist(projected[, get.numeric.columns(projected)])  
  
  original  = as.matrix(original)  
  projected = as.matrix(projected)
  
  x = c(original)
  y = c(projected)
  
  plot(x, y, main =  desc, bg = "blue", col = "black",  type = "n", 
       xlab = ifelse(show.label, "Original", ""), ylab = ifelse(show.label, "Projected", "") )
  lines(par()$usr[1:2], par()$usr[3:4], col = "red" )
  points(x, y, pch = 21, bg = "blue", col = "black")  
}

distance.histogram = function(original, projected.list, save = FALSE, prefix.file = "", original.dist = NULL)
{
  count = 0;
  
  for(i in 1:length(projected.list))
    count = count + ifelse( is.null(projected.list[[i]]), 0, 1 )  
  
  dime = get.dimentions(count, type = 2);

  if(save)
    png( paste(prefix.file, "Distance_histogram.png", sep = ifelse(prefix.file == "", "", "_")),
         width = 1366, height = 768);
  
  par(mfrow = c(dime$nrow, dime$ncol), oma = c(1, 1.5, 2, 0), mar = c(2.3, 2.5, 2.0, 0.5));
  
  if(count > 1)
    plot.new()
  
  dist1 = original.dist
  
  if(is.null(original.dist))
    dist1 = dist(original, upper = FALSE)

  hist(dist1, freq = FALSE, main = ifelse(count > 1, "Original", ""), xlab = "", ylab = "", col = "red")
  lines(density(dist1), lwd = 2, lty = 2)
  start.new.line = count > 1
  
  for(i in 1:length(projected.list))
  {
    if(!is.null(projected.list[[i]]))
    {
      cat("   |- Plotting ", names(projected.list[i]), "\n", sep = "")  
      
      if(start.new.line)
      {
        plot.new();
        start.new.line = FALSE
      }  

      dist1 = dist(projected.list[[i]], upper = FALSE)
      hist(dist1, freq = FALSE, main = names(projected.list[i]), xlab = "", ylab = "", col = "red")
      lines(density(dist1), lwd = 2, lty = 2)        
    }  
  }

  mtext("Distance Histogram", outer = TRUE, cex = 1.5)
  mtext("Distance", outer = TRUE, cex = 1.0, side = 1)
  mtext("Density", outer = TRUE, cex = 1.0, side = 2)  
  par(mfrow = c(1, 1), oma = c(0, 0, 0, 0), mar = c(5.1, 4.1, 4.1, 2.1));

  if(save)
    dev.off();
}

plot.distance = function(original, projected.list, save = FALSE, prefix.file = "", ylab = "Projected")
{
  count = 0;
  
  for(i in 1:length(projected.list))
    count = count + ifelse( is.null(projected.list[[i]]), 0, 1 )
  
  dime = get.dimentions(count);
  
  if(save)
    png( paste(prefix.file, "Distance_Scatterplot.png", sep = ifelse(prefix.file == "", "", "_")), 
         width = 1366, height = 768);  
  
  par(mfrow = c(dime$nrow, dime$ncol), oma = c(1, 1.5, 2, 0), mar = c(2.3, 2.5, 2.0, 0.5));
  
  for(i in 1:length(projected.list))
  {
    if(!is.null(projected.list[[i]]))
    {
      cat("   |- Plotting ", names(projected.list[i]), "\n", sep = "")      
      distance.scatterplot(original, projected.list[[i]], names(projected.list[i]));
    }  
  }
  
  mtext("Distance Scatterplot", outer = TRUE, cex = 1.5)
  mtext("Original", outer = TRUE, cex = 1.0, side = 1)
  mtext(ylab, outer = TRUE, cex = 1.0, side = 2)
  par(mfrow = c(1, 1), oma = c(0, 0, 0, 0), mar = c(5.1, 4.1, 4.1, 2.1));
  
  if(save)
    dev.off();
}

plot.neighbor.aux = function(p.value, h.value, legend.names, save = FALSE, prefix.file = "")
{
  main.text = "";
  list.value = list();
  
  if(!is.null(p.value))
  {
    list.value$p = p.value;
    main.text    = c("Neighborhood Preservation");
  }
  
  colors     = palette();
  
  if(!is.null(h.value))
  {
    list.value$h = h.value;
    
    if(length(main.text) == 0)
      main.text    = c("Neighborhood Hit")
    else
      main.text    = c(main.text, "Neighborhood Hit");
  }  
  
  if(save)
    png(paste(prefix.file, "Neighbor.png", sep = ifelse(prefix.file == "", "", "_")), width = 1366, height = 768);    
  
  par(mfrow = c(1, length(list.value)), oma = c(1, 1.5, 0, 0), mar = c(2.3, 2.5, 2.0, 0.5));  
  
  for(i in 1:length(list.value))
  {
    data = list.value[[i]];
    MIN  = min(apply(data, 1, min));
    MAX  = max(apply(data, 1, max));
    
    if(i == 1)
      MIN = min(MIN, 0);
    
    plot(y = c(MIN, MAX), x = c(1, ncol(data)), type = "n", xlab = "", ylab = "", main = main.text[i])
    
    for(j in 1:nrow(data))
    {
      # points(data[j, ], type = "b", col = "black", bg = colors[j], pch = 21)
      lines(data[j, ], col = colors[j])
    }
    
    if(i == 1 && !is.null(legend.names))
      legend(ncol(data) - 8, MIN + 0.3,
             as.factor(legend.names),
             lty = c(1, 1), col = colors,
             box.lty = 0, bg = "transparent")    
  }
  
  mtext("Neighbor", outer = TRUE, cex = 1.0, side = 1)
  mtext("Values", outer = TRUE, cex = 1.0, side = 2)
  par(mfrow = c(1, 1), oma = c(0, 0, 0, 0), mar = c(5.1, 4.1, 4.1, 2.1));    
  
  if(save)
    dev.off();      
}

plot.neighbor.aux2 = function(p.value, h.value, legend.names, save = FALSE, prefix.file = "")
{
  # main.text = "";
  # list.value = list();
  # 
  # if(!is.null(p.value))
  # {
  #   list.value$p = p.value;
  #   main.text    = c("Neighborhood Preservation");
  # }
  # 
  # colors     = palette();
  # 
  # if(!is.null(h.value))
  # {
  #   list.value$h = h.value;
  #   
  #   if(length(main.text) == 0)
  #     main.text    = c("Neighborhood Hit")
  #   else
  #     main.text    = c(main.text, "Neighborhood Hit");
  # }  
  # 
  # if(save)
  #   png(paste(prefix.file, "Neighbor_boxplot.png", sep = ifelse(prefix.file == "", "", "_")), width = 1366, height = 768);    
  # 
  # par(mfrow = c(1, length(list.value)), oma = c(1, 1.5, 0, 0), mar = c(2.3, 2.5, 2.0, 0.5));  
  # 
  # 
  # 
  # mtext("Neighbor", outer = TRUE, cex = 1.0, side = 1)
  # mtext("Values", outer = TRUE, cex = 1.0, side = 2)
  # par(mfrow = c(1, 1), oma = c(0, 0, 0, 0), mar = c(5.1, 4.1, 4.1, 2.1));    
  # 
  # if(save)
  #   dev.off();      
}

plot.neighbor = function(dataset, list.vis, labels, neighbor.k, save = FALSE, prefix.file = "", plot.hit = TRUE, plot.preservation = TRUE)
{
  p.values = NULL;
  h.values = NULL;
  legend.names = c();
  has.label = length(labels) > 1 && length(unique(labels)) > 1;
  
  for(i in 1:length(list.vis))
  {
    if(!is.null(list.vis[[i]]))
    {
      cat("  |- Calculating ", names(list.vis[i]), "\n", sep = "")            
      pb = txtProgressBar(min = 0, max = max(neighbor.k), style = 3)    
      
      new.row.p = c();
      new.row.h = c();
      legend.names = c(legend.names, names(list.vis[i]));
      
      for(j in neighbor.k)
      {
        if(plot.preservation)
        {
          value     = neighborhood.preservation(dataset, list.vis[[i]], j);
          new.row.p = c(new.row.p, value);
        }
        if(plot.hit && has.label)
        {
          value = neighborhood.hit(list.vis[[i]], labels, j);
          new.row.h = c(new.row.h, value);
        }  
        
        setTxtProgressBar(pb, j)
      }
      
      close(pb)
      
      if(plot.preservation)
      {
        if(is.null(p.values))
          p.values = matrix(new.row.p, nrow = 1)
        else
          p.values = rbind(p.values, new.row.p);
      }
      if(plot.hit && has.label)
      {
        if(is.null(h.values))
          h.values = matrix(new.row.h, nrow = 1)
        else
          h.values = rbind(h.values, new.row.h);        
      }
    }
  }
  
  rownames(p.values) = seq(1, nrow(p.values));
  
  if(has.label)
    rownames(h.values) = seq(1, nrow(h.values));
  
  plot.neighbor.aux(p.values, h.values, legend.names, save = save, prefix.file = prefix.file);
  # plot.neighbor.aux2(p.values, h.values, legend.names, save = save, prefix.file = prefix.file);
  
#============================================================================================#  
  row.names(p.values) = legend.names;
  row.names(h.values) = legend.names;
  
  if(save)
    png( paste(prefix.file, "Neighborhood2.png", sep = ifelse(prefix.file == "", "", "_")), 
         width = 1366, height = 768);  
  
  par(mfrow = c(1, 2), oma = c(1, 1.5, 0, 0), mar = c(2.3, 2.5, 2.0, 0.5));  
  
  if(!is.null(p.values))
    boxplot(t(p.values), main = "Neighborhood Preservation")
  if(!is.null(h.values))
    boxplot(t(h.values), main = "Neighborhood Hit")
  
  par(mfrow = c(1, 1), oma = c(0, 0, 0, 0), mar = c(5.1, 4.1, 4.1, 2.1));    
  
  if(save)
    dev.off()
#============================================================================================#  
}

get.dimentions = function(qt, type = 1)
{
  if(qt < 2)
  {
    nrow = 1;
    ncol = 1;    
  }else if(type == 1)
  {
    nrow = 3;
    ncol = 3;
    
    if(qt %in% c(1, 2))
      nrow = 1
    else if(qt %in% c(3, 4, 5, 6))
      nrow = 2;
    
    if(qt == 1)
      ncol = 1
    else if(qt %in% c(2, 3, 4))
      ncol = 2;
  }else
  {
    nrow = 4
    ncol = 3
    
    if(qt == 1)
      nrow = 1
    else if(qt %in% c(2, 3))
      nrow = 2
    else if(qt %in% c(4, 5, 6))
      nrow = 3
    
    if(qt %in% c(1, 2))
      ncol = 2    
  }

  return(list(nrow = nrow, ncol = ncol));
}

plot.list = function(metric.values, config, join = TRUE, data.projection = NULL, labels = NULL, 
                     title = NULL, value.on.descript = TRUE, save = FALSE)
{
  if(save)
    png(paste(title, ".png", sep = ""), width = 1366, height = 768);
  if(join)
  {
    dime = get.dimentions(sum(unlist(config)));
    par(mfrow = c(dime$nrow, dime$ncol), oma = c(0, 0, 
                                                 ifelse( is.null(title) || is.na(title) || title == "" ,0, 2), 0), 
        mar = c(0.5, 0.5, 2.0, 0.5));
  }
  
  for(i in 1:length(config))
  {
    if(config[[i]])
    {
      desc = names(config[i]);
      
      if(value.on.descript)
      {
        if(!is.null(metric.values) && !is.na(metric.values))
          desc = paste(names(config[i]), " -> ", round(metric.values[[i]], 4), sep = "");
       
        # print(dim(data.projection[[i]]))
         
        plot(data.projection[[i]], main =  desc, bg = labels, col = "black",  pch = 21, xlab = "", ylab = "", xaxt = "n", yaxt = "n");
      }else
        plot(metric.values[[i]], main =  desc, bg = labels, col = "black",  pch = 21, xlab = "", ylab = "", xaxt = "n", yaxt = "n");
    }  
  }
  
  if(join)
  {
    mtext(title, outer = TRUE, cex = 1.5)
    par(mfrow = c(1, 1), oma = c(0, 0, 0, 0), mar = c(5.1, 4.1, 4.1, 2.1));  
  }
  if(save)
    dev.off();
}

calc.metrics = function(dataset, data.projection, projection.name, labels, calc = list(stress=TRUE, Silhouette=TRUE, nhit=TRUE, npreservation=TRUE, distance=TRUE), verbose = TRUE, qt_cluster = NULL)
{ 
  stress.value = 0;
  np.value = 0;
  
  if(calc$stress)
  {
    if(verbose)
      cat("   |- Calculating ", projection.name, " Stress\n", sep = "")
    
    stress.value = stress(dataset, data.projection);
  }

  if(calc$npreservation)
  {
    if(verbose)
      cat("   |- Calculating ", projection.name, " Neighborhood Preservation\n", sep = "")
  
    np.value = neighborhood.preservation(dataset, data.projection, k = qt_cluster);
  }

  silhouette.value = NULL;
  silhouette.avg   = NULL;
  nh.value         = 0;

  if(length(labels) > 1 && length(unique(labels)) > 1)
  {
    if(calc$Silhouette)
    {
      if(verbose)
        cat("   |- Calculating ", projection.name, " Silhouete\n", sep = "")
  
      dist_vis         = dist(data.projection);
      silhouette.value = silhouette(as.numeric(labels), dist_vis);
      silhouette.avg   = summary(silhouette.value)$avg.width;
    }
    if(calc$nhit)
    {
      if(verbose)
        cat("   |- Calculating ", projection.name, " Neighborhood Hit\n", sep = "")
  
      nh.value = neighborhood.hit(data.projection, labels, k = qt_cluster);
    }
  }
  
  return(list(stress.value = stress.value, silhouette.value = silhouette.value, silhouette.avg = silhouette.avg, nh.value = nh.value,
              np.value = np.value));
}

evaluate.projection = function(dataset, labels = c("red"), seed = 1753, 
                               neighbor.k = c(1:30),
                               save = FALSE,
                               projection = list(PCA=TRUE, MDS=TRUE, ForceScheme=TRUE, LSP=TRUE, PLMP=TRUE, LAMP=TRUE, tSNE=TRUE, HiPP=FALSE),
                               calc = list(stress=TRUE, Silhouette=TRUE, nhit=TRUE, npreservation=TRUE, distance.s=TRUE, distance.h=TRUE),
                               silhouette.file.name = NULL)
{
  dataset = dataset[, get.numeric.columns(dataset)];
  
  list.projection = c("PCA", "MDS", "ForceScheme", "LSP", "PLMP", "LAMP", "tSNE", "HiPP");  
  list.vis    = list(PCA=NULL, MDS=NULL, ForceScheme=NULL, LSP=NULL, PLMP=NULL, LAMP=NULL, tSNE=NULL, HiPP=NULL);
  list.stress = list(PCA=0, MDS=0, ForceScheme=0, LSP=0, PLMP=0, LAMP=0, tSNE=0, HiPP=0);
  list.silhouette = list(PCA=NULL, MDS=NULL, ForceScheme=NULL, LSP=NULL, PLMP=NULL, LAMP=NULL, tSNE=NULL, HiPP=NULL);
  list.avg.silhouette = list(PCA=0, MDS=0, ForceScheme=0, LSP=0, PLMP=0, LAMP=0, tSNE=0, HiPP=0);
  list.neibor.hit = list(PCA=0, MDS=0, ForceScheme=0, LSP=0, PLMP=0, LAMP=0, tSNE=0, HiPP=0);
  list.neibor.preservation = list(PCA=0, MDS=0, ForceScheme=0, LSP=0, PLMP=0, LAMP=0, tSNE=0, HiPP=0);
  
  original.dist = dist(dataset);
  show.unique.neighbor = (length(neighbor.k) > 0 & length(neighbor.k) == 1);
  
  for(i in 1:length(list.projection))
  {
    if(projection[[list.projection[i]]])
    {
      cat("-> Calculating ", list.projection[i], "\n", sep = "");
      
      set.seed(seed);
      
      if(list.projection[i] == "PCA")
        list.vis[[list.projection[i]]] = prcomp(dataset)$x[, 1:2]
      else if(list.projection[i] == "MDS")
        list.vis[[list.projection[i]]] = cmdscale(original.dist)   
      else if(list.projection[i] == "ForceScheme")
        list.vis[[list.projection[i]]] = forceScheme(original.dist)
      else if(list.projection[i] == "LSP")
        list.vis[[list.projection[i]]] = lsp(dataset)
      else if(list.projection[i] == "PLMP")
        list.vis[[list.projection[i]]] = plmp(dataset)
      else if(list.projection[i] == "LAMP")
        list.vis[[list.projection[i]]] = lamp(dataset)
      else if(list.projection[i] == "tSNE")
        list.vis[[list.projection[i]]] = tSNE(dataset)
      else if(list.projection[i] == "HiPP")
        list.vis[[list.projection[i]]] = HiPP(dataset, return.tree = FALSE, operation = "cluster_projection");
      
      metrics = calc.metrics(dataset, list.vis[[list.projection[i]]], list.projection[i], labels, calc);
      list.stress[[list.projection[i]]] = metrics$stress.value;
      list.silhouette[[list.projection[i]]] = metrics$silhouette.value;
      list.avg.silhouette[[list.projection[i]]] = metrics$silhouette.avg;
      list.neibor.hit[[list.projection[i]]]  = metrics$nh.value;
      list.neibor.preservation[[list.projection[i]]] = metrics$np.value;
    }    
  }
  
  if(any(unlist(calc)))
  {
    if(calc$stress)
    {
      cat("Plotting Stress\n")
      plot.list(list.stress, projection, data.projection = list.vis, labels = labels, title = "Stress", save = save);
    }
    if(calc$npreservation && show.unique.neighbor)
    {
      cat("Plotting Neighborhood Preservation\n")
      plot.list(list.neibor.preservation, projection, data = list.vis, labels = labels, title = "Neighborhood Preservation", save = save);
    }
    if(length(labels) > 1 && length(unique(labels)) > 1)
    {
      if(calc$nhit && show.unique.neighbor)
      {
        cat("Plotting Neighborhood Hit\n")
        plot.list(list.neibor.hit, projection, data = list.vis, labels = labels, title = "Neighborhood Hit", save = save);
      }
      if(calc$Silhouette)
      {
        cat("Plotting Silhouette Average\n")
        plot.list(list.avg.silhouette, projection, data = list.vis, labels = labels, title = ifelse(is.null(silhouette.file.name), "Silhouette Average", silhouette.file.name), save = save);      
      }
    }
    if(calc$distance.s)
    {
      cat("Plotting Distance Scatterplot\n")
      plot.distance(original.dist, list.vis, save = save)
    }
    if(calc$distance.h)
    {
      cat("Plotting Distance Histogram\n")
      distance.histogram(original = NULL, list.vis, save = save, original.dist = original.dist)
    }    
    if((calc$nhit || calc$npreservation) && !show.unique.neighbor)
    {
      cat("Plotting Neighborhood Hit and Preservation\n");
      plot.neighbor(dataset, list.vis, labels, neighbor.k, save = save, plot.hit = calc$nhit, plot.preservation = calc$npreservation)
    }
  } else
  {
    cat("Plotting\n")
    plot.list(NULL, projection, data.projection = list.vis, labels = labels, save = save, title = "Projections");    
  }
}

evaluate.original.data = function(dataset, labels = c("red"), plot.values = TRUE)
{
  dataset = dataset[, get.numeric.columns(dataset)];
  silhouette.value = silhouette(as.numeric(labels), dist(dataset));  
  
  if(plot.values)
  {
    plot(silhouette.value);
    distance.histogram(dataset, NULL)
  }  
  
  return(summary(silhouette.value)$avg.width);
}


evaluate.HiPP = function(dataset, labels = c("red"), seed = 1753, neighbor.k = c(1:30), 
                         operation = "cluster_projection",
                         qt.cluster = NULL,
                         clustering = list(kmeans = TRUE, kmedoid = TRUE, hclust = TRUE),
                         projection = list(pca=TRUE, mds=TRUE, force=TRUE, lsp=TRUE, plmp=TRUE, lamp=TRUE, tsne=TRUE))
{
  list.vis = list(pca=NULL, mds=NULL, force=NULL, lsp=NULL, plmp=NULL, lamp=NULL, tsne=NULL); 
  
  list.stress = list(pca=0, mds=0, force=0, lsp=0, plmp=0, lamp=0, tsne=0);
  list.silhouette = list(pca=NULL, mds=NULL, force=NULL, lsp=NULL, plmp=NULL, lamp=NULL, tsne=NULL);
  list.avg.silhouette = list(pca=0, mds=0, force=0, lsp=0, plmp=0, lamp=0, tsne=0);
  list.neibor.hit = list(pca=0, mds=0, force=0, lsp=0, plmp=0, lamp=0, tsne=0);
  list.neibor.preservation = list(pca=0, mds=0, force=0, lsp=0, plmp=0, lamp=0, tsne=0);  
  
  original.dist = dist(dataset, upper = FALSE);
  
  for(i in 1:length(clustering))
  {
    if(clustering[[i]])
    {
      for(j in 1:length(projection))
      {
        if(projection[[j]])
        {
          cat("-> Calculating ", names(clustering)[i], " + ", names(projection)[j], "\n", sep = "");
          set.seed(seed);          
          
          list.vis[[j]] = HiPP(dataset, operation, names(clustering)[i], names(projection)[j], return.tree = FALSE, 
                               qt_cluster = ifelse(is.null(qt.cluster), 0, qt.cluster));
          
          metrics = calc.metrics(dataset, list.vis[[ names(projection)[j]  ]], names(projection)[j], labels, qt_cluster = qt.cluster);
          list.stress[[ names(projection)[j] ]] = metrics$stress.value;
          list.silhouette[[ names(projection)[j] ]] = metrics$silhouette.value;
          list.avg.silhouette[[ names(projection)[j] ]] = metrics$silhouette.avg;
          list.neibor.hit[[ names(projection)[j] ]]  = metrics$nh.value;
          list.neibor.preservation[[ names(projection)[j] ]] = metrics$np.value;              
        }  
      }
      
      cat("Plotting Stress\n")
      plot.list(list.stress, projection, data.projection = list.vis, labels = labels, title = paste(names(clustering)[i], "Stress", sep = "_"), save = TRUE);
      
      cat("Plotting Silhouette Average\n")
      plot.list(list.avg.silhouette, projection, data = list.vis, labels = labels, title = paste(names(clustering)[i], "Silhouette Average", sep = "_"), save = TRUE);      
      
      # cat("Plotting Distance Scatterplot\n")
      # plot.distance(original.dist, list.vis, save = TRUE, prefix.file = names(clustering)[i]);
      
      cat("Plotting Neighborhood Hit and Preservation\n");
      plot.neighbor(dataset, list.vis, labels, neighbor.k, save = TRUE, prefix.file = names(clustering)[i]);
    }
  }    
}  

# evaluate.original.data(iris[, 1:4], iris[, 5])
# evaluate.projection(iris[, 1:4], iris[, 5], calc = list(stress=TRUE, Silhouette=TRUE, nhit=TRUE, npreservation=TRUE, distance.s=TRUE, distance.h=TRUE), projection = list(PCA=TRUE, MDS=TRUE, ForceScheme=TRUE, LSP=TRUE, PLMP=TRUE, LAMP=TRUE, tSNE=TRUE, HiPP=FALSE))

