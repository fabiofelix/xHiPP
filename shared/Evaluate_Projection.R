#================================================================================#
#Functions to evaluate Multidimentional projections
#             
#Created: 06/03/2020
#================================================================================#

require(cluster) 

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
