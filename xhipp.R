#================================================================================#
#Implementation of xHiPP algorithm
#
#Changed: 04/08/2018
#         Added colnames into root tree node (cf. fill.children)
#Changed: 03/05/2018
#         Added medoid return in split function
#Changed: 12/10/2017
#         Added option to define number of clusters
#Changed: 11/13/2017
#         hierarchy.rec didn't involke itself.
#Changed: 11/11/2017
#         Parallel compatibility with Windows (use PSOCK (default) in makeCluster, 
#         clusterEvalQ and .export/.package inside foreach)
#Changed: 11/09/2017
#         Added parallelism to improve performance
#Changed 10/04/2017
#        Function get.numeric.columns was moved to utils.R
#
#Created    : 05/17/2017
#================================================================================#

require(jsonlite);
require(cluster);
require(mp);
require(doParallel);
source("shared/utils.R");
# source("~/Documentos/shared_src/R/utils.R");
# source("~/Documents/shared_src/R/utils.R");

process.types = list(ordinary = 0, text = 1, image = 2, audio = 3);
QT.CORES <- 1;
PROCESSING.TYPE <- process.types$ordinary;

LIST.ENV.FUNC <- c("add.fields","adjust.coordinate","calc.metrics","create.node","dist.point",
             "estimate.radius","fill.children","fill.children.aux","get.data.center","get.index",
             "hclust.centroid","hierarchy","hierarchy.rec","move.node","padding",
             "project.tree","project.tree.rec","split","spread.tree","spread.tree.rec",
             "spreader","table2tree","tree2table", "get.numeric.columns",
             "get.text.words", "PROCESSING.TYPE");
LIST.ENV.PKG <- c("mp", "cluster");

hclust.centroid = function(index.cluster, dataset, clusters) 
{
  return(colMeans(dataset[which(clusters == index.cluster), ]));
}

fill.children.aux = function(dataset, bynamerow, list_columns, name.group, init.coord = FALSE)
{
  # list_columns = get.numeric.columns(dataset, name.group);
  list.nodes   = list();
  
  for(i in 1:nrow(dataset))
  {
    index = i;
    
    if(bynamerow)
      index = as.numeric(rownames(dataset[i, ]))
    
    new_node      = create.node(FALSE, TRUE);
    new_node$name = paste("item_", index, sep = "");
    new_node$row_index = index;
    
    if(!is.null(dataset[i, name.group[1]]))
      new_node$name = as.character(dataset[i, name.group[1]]);
    if(!is.null(dataset[i, name.group[2]]))
      new_node$group = dataset[i, name.group[2]];
    
    new_node$data  = as.numeric(dataset[i, list_columns]);

    #Teste e atribuições adicionados por causa do HiPP_projection_cluster
    if(init.coord)
    {
      new_node$x = dataset[i, 1];
      new_node$y = dataset[i, 2];
    }
    
    list.nodes = append(list.nodes, list(new_node));
  }
  
  return(list.nodes);
}

fill.children = function(node, dataset, bynamerow, name.group, init.coord = FALSE)
{
  node$qt_instances = nrow(dataset);
  list_columns      = get.numeric.columns(dataset, name.group);
  node$colnames     = colnames(dataset)[list_columns];
  
  #====================================================================================================    
  row.index = list();
  size = floor(nrow(dataset) / QT.CORES);
  
  for(i in 1:QT.CORES)
  {
    first.index = 1 + (i - 1) * size;
    last.index  = ifelse(i == QT.CORES, nrow(dataset), first.index + size - 1);
    
    row.index = append(row.index, list(list(first = first.index, last = last.index)));  
  }  
  
  node$children = foreach(i = 1:QT.CORES, .combine = append, .export = LIST.ENV.FUNC, .packages = LIST.ENV.PKG)%dopar%
  {
    fill.children.aux(dataset[row.index[[i]]$first:row.index[[i]]$last, ], bynamerow, list_columns, name.group, init.coord)
  }
  #====================================================================================================      
  
  return(node);
}

fill.children2 = function(node, dataset_aux, clust, init.coord, name.group, original.data = NULL, columns.aux = NULL)
{
  list_columns = get.numeric.columns(dataset_aux, name.group);

  for(i in 1:nrow(dataset_aux))
  {
#============================================================================================================================
    index = as.numeric(rownames(dataset_aux[i, ]))
    
    new_node      = create.node(FALSE, TRUE);
    new_node$name = paste("item_", index, sep = "");
    new_node$row_index = index;
    
    if(!is.null(dataset_aux[i, name.group[1]]))
      new_node$name = as.character(dataset_aux[i, name.group[1]]);
    if(!is.null(dataset_aux[i, name.group[2]]))
      new_node$group = dataset_aux[i, name.group[2]];
    
    new_node$data  = as.numeric(dataset_aux[i, list_columns]);
    new_node$words = c();
    
    if(PROCESSING.TYPE == process.types$text)
    {
      data = dataset_aux;
      columns = list_columns;
      
      if(!is.null(original.data))
      {
        data = original.data;
        columns = columns.aux;
      }  
      
      new_node$words = get.text.words(data[i, columns]);
    }  
    
    #Teste e atribuições adicionados por causa do HiPP_projection_cluster
    if(init.coord)
    {
      new_node$x = dataset_aux[i, 1];
      new_node$y = dataset_aux[i, 2];
    }
#============================================================================================================================
    
    group.index = clust$cluster[i];
    group = node$children[[group.index]];
    
    group$children = append(group$children, list(new_node));
    group$qt_instances = length(group$children);

    if(PROCESSING.TYPE %in% c(process.types$image, process.types$audio) && !all(group$medoid_coord %in% new_node$data))
    {
      aux = rbind(group$center, group$medoid_coord, new_node$data);
      last.row = nrow(aux);
      aux = as.matrix(dist(aux));
      aux[1, 1] = .Machine$double.xmax;
      aux = which.min(aux[, 1]);
      
      if(aux == last.row)
      {
        group$medoid_coord = new_node$data;
        group$medoid_name  = new_node$name;
      }
    }
    
    node$children[[group.index]] = group;
  }  
  
  
  return(node);
}

create.node = function(isRoot, isLeave)
{
  new_node = list(name = "", center = c(), children = c(), r = 0, qt_instances = 0);
  
  if(isRoot)
  {
    new_node$name   = "root";
    new_node$qt_min = 0;
  }else if(isLeave)
    new_node = list(name  = "",  group = "", data  = c(), row_index = -1, parent_instances = 0)
  else
  {
    new_node$group = "";
    new_node$parent_instances = 0;
  }
  
  new_node$isRoot  = isRoot;
  new_node$isLeave = isLeave;  
  new_node$r = 10;
  
  return(new_node);
}

add.fields = function(node)
{
  node$r = 10;
  
  if(node$isRoot)
    node$qt_min = 0    
  else 
  {
    node$x = 0;
    node$y = 0;      
    node$parent_instances = 1; 
    
    if(!node$isLeave)
      node$parent_r = 0;
  }
  
  return(node);  
}

table2tree = function(dataset, name.group)
{
  if(!is.null(dataset))
  {
    tree = create.node(TRUE, FALSE);
    tree = fill.children(tree, dataset, TRUE, name.group);
    return(tree);
  }
}

get.index = function(node)
{
  return(sapply(node$children, function(kid){ kid$row_index; }, simplify = "array"));
}

get.data.center = function(node, dataset, name.group)
{
  aux = t(sapply(node$children, function(kid){ kid$center; }));
  colnames(aux) = colnames(dataset[0, get.numeric.columns(dataset, name.group)]);
  
  return(aux);
}

get.tree.names = function(tree)
{
  name.list = c()
  
  if(tree$isLeave)
    name.list = c(tree$name)
  else
  {
    for(i in 1:length(tree$children))
      name.list = c(name.list, get.tree.names(tree$children[[i]]));
  }
  
  return(name.list)
}

tree2table = function(tree, dataset = NULL, by.data = FALSE)
{
  if(is.null(dataset))
    dataset = matrix(c(0, 0), nrow = 1)[0, ];
  
  if(tree$isLeave)
  {
    if(by.data)
    {
      leave_data = tree$data;
      
      if(class(leave_data) == "list")
        leave_data = unlist(leave_data);
      
      if(nrow(dataset) == 0 && ncol(dataset) != length(leave_data))
        dataset = rbind(rep(0, length(leave_data)))[0, ];
      
      dataset = rbind(dataset, leave_data);
      tree$row_index = nrow(dataset);
      tree = add.fields(tree);
    }else
    {
      while(nrow(dataset) < tree$row_index)
        dataset = rbind(dataset, c(0, 0));
      
      dataset[tree$row_index, 1] = tree$x;
      dataset[tree$row_index, 2] = tree$y;    
    }
  }
  else
  {
    if(by.data)
      tree = add.fields(tree);
    
    for(i in 1:length(tree$children))
    {
      dataset = tree2table(tree$children[[i]], dataset, by.data);
      
      if(by.data)
      {
        tree$children[[i]] =  dataset$tree;
        dataset = dataset$dataset;
      }  
    }  
  }
  
  if(by.data)
  {
    rownames(dataset) = seq(1, nrow(dataset));
    return(list(tree = tree, dataset = dataset));
  }else
    return(dataset);
}

split = function(node, dataset, type.cluster, qt_cluster,  name.group, init.coord = FALSE, original.data = NULL, summary.path = "")
{
  if(qt_cluster <= 0)
  {
    # qt_cluster = floor(sqrt(node$qt_instances)); #Regra da raiz
    qt_cluster = floor(1 + 3.3 * log10(node$qt_instances)); #Regra de Sturges
  }  
  
  node$qt_cluster = qt_cluster;    
  
  if(qt_cluster > 1)
  {
    list_columns = get.numeric.columns(dataset, name.group);
    dataset_aux  = dataset[get.index(node), ];
    
    columns.aux  = NULL;
    
    if(!is.null(original.data))
    {
      original.data = original.data[get.index(node), ];
      columns.aux   = get.numeric.columns(original.data, name.group);
    }  
    
    if(type.cluster == "kmeans" ||  !(type.cluster %in% c("kmeans", "kmedoid", "hclust")))
      clust = kmeans(dataset_aux[, list_columns], qt_cluster, iter.max = 15)
    else if(type.cluster == "kmedoid")
    {
      clust = pam(dataset_aux[, list_columns], qt_cluster);
      clust$cluster = clust$clustering;
      clust$centers = clust$medoids;
    }else if(type.cluster == "hclust")
    {
      clust = hclust(dist(dataset_aux[, list_columns]));
      clust$cluster = cutree(clust, qt_cluster);
      clust$centers = sapply(unique(clust$cluster), hclust.centroid, dataset_aux[, list_columns], clust$cluster);
      clust$centers = t(clust$centers);
    }
    
    node$children = c();
    groups        = sort(unique(clust$cluster));
    
    #Partindo da ideia de que os valores em clust$cluster sempre estao entre 1 e qt_cluster
    for(i in 1:length(groups))
    {
      new_node        = create.node(FALSE, FALSE);
      new_node$center = as.vector(clust$centers[groups[i], ]);
      new_node$medoid_name = "";
      new_node$medoid_coord = rep(.Machine$double.xmax, length(new_node$center));
      node$children   = append(node$children, list(new_node));
    }
    
    node = fill.children2(node, dataset_aux, clust, init.coord, name.group, original.data = original.data, columns.aux = columns.aux);

    # for(i in 1:length(groups))
    # {
    #   new_node        = create.node(FALSE, FALSE);
    #   new_node$center = as.vector(clust$centers[groups[i], ]);
    #   new_node        = fill.children(new_node, dataset_aux[which(clust$cluster == groups[i]), ], TRUE, name.group, init.coord);
    # 
    #   node$children   = append(node$children, list(new_node));
    # }
  }
  
  return(node);
}

save.summary = function(tree, dataset, name.group, summary.path, original.data)
{
  file.name = "";  
  
  if(PROCESSING.TYPE == process.types$ordinary)
  {
    dataset = norm.stand(dataset, "minmax")
    list.columns = get.numeric.columns(dataset, name.group);

    if(!is.null(original.data))
    {
      list.columns  = get.numeric.columns(original.data, name.group);
      dataset = norm.stand(original.data, "minmax");
    }    
    
    dataset = dataset[get.index(tree), ]
    
    if(nrow(dataset) == 1)
      dataset = rbind(dataset, dataset[1, ])
    if(ncol(dataset) == 1)
      dataset = cbind(dataset, dataset[, 1])    

    dataset  = dataset[order(dataset[, name.group[2]]), ];
    groups   = table(dataset[, name.group[2]]);
    gray.aux = gray.colors(length(groups));
    colors   = c();
    
    for(i in 1:length(groups))
      colors = c(colors, rep(gray.aux[i], as.numeric(groups[i])))
    
    list.names = list.files(summary.path, pattern = paste("group_summary[[:digit:]_]*.png", sep = "") )
    count = "1";
    
    if(length(list.names) > 0)
    {
      list.names = list.names[sort(order(list.names))];
      file.name  = tools::file_path_sans_ext(list.names[length(list.names)]);
      file.name  = unlist(strsplit(file.name, "group_summary"));
      
      if(length(file.name) > 1)
      {
        count = file.name[length(file.name)];
        count = as.numeric(count);
        count = as.character(ifelse(is.na(count), 2, count + 1));
      }
    }
    
    file.name = paste("group_summary", stringr::str_pad(count, 3, side = "left", pad = "0"), ".png", sep = "")
    
    png(paste(summary.path, file.name, sep = "/"), width = 830, height = 768);
    heatmap(as.matrix(dataset[, list.columns]), scale = "none", 
            Rowv = NA, Colv = NA, 
            labRow = "", labCol = "", 
            margins = c(0.5, 0), RowSideColors = colors);
    dev.off();
  }  

  return(file.name);
}

hierarchy.rec = function(tree, dataset, qt_cluster, min.item, type.cluster, name.group, init.coord = FALSE, original.data = NULL, summary.path = "")
{
  tree$summary = save.summary(tree, dataset, name.group, summary.path, original.data);  

  if(!is.null(tree) && !is.null(dataset) && length(tree$children) > min.item)
  {
    tree = split(tree, dataset, type.cluster, qt_cluster, name.group, init.coord, original.data, summary.path);
    
    for(i in 1:length(tree$children))
      tree$children[[i]] = hierarchy.rec(tree$children[[i]], dataset, qt_cluster, min.item, type.cluster, name.group, init.coord, original.data, summary.path);
  }

  return(tree);
}

hierarchy = function(tree, dataset, qt_cluster, min.item, type.cluster, name.group, init.coord = FALSE, original.data = NULL, summary.path = "")
{
  if(!is.null(tree) && !is.null(dataset) && length(tree$children) > min.item)
  {
    tree = split(tree, dataset, type.cluster, qt_cluster, name.group, init.coord, original.data, summary.path);
    
    #====================================================================================================    
    # tree$children = foreach(i = 1:length(tree$children), .combine = append, .export = LIST.ENV.FUNC, .packages = LIST.ENV.PKG)%dopar%
    for(i in 1:length(tree$children))
    {
      # list(hierarchy.rec(tree$children[[i]], dataset, qt_cluster, min.item, type.cluster, name.group, init.coord, original.data, summary.path));
      tree$children[[i]] = hierarchy.rec(tree$children[[i]], dataset, qt_cluster, min.item, type.cluster, name.group, init.coord, original.data, summary.path);
    }
    #====================================================================================================    
  }
  
  return(tree);
}

padding = function(dataset, qt.min)
{
  if(nrow(dataset) < qt.min)
  {
    n = qt.min - nrow(dataset);
    m_aux = sapply(dataset, function(col)
    {
      aux = sd(col);
      rnorm(n, mean(col), ifelse(is.na(aux), 1, aux)); 
    })    
    
    return(rbind(dataset, m_aux));
  }else
    return(dataset);
}

estimate.radius = function(node, dataset, name.group)
{
  if(node$isRoot)
  {
    list_column = get.numeric.columns(dataset, name.group);
    node$center = as.vector(colMeans(dataset[, list_column]));
    dataset_aux = rbind(dataset[, list_column], node$center);
    dist_aux    = as.matrix(dist(dataset_aux));
    node$r      = max(dist_aux[, nrow(dist_aux)]);
  }else if(!node$isLeave)
  {
    sum0 = node$qt_instances;
    
    if(!node$children[[1]]$isLeave)
      sum0 = sum(sapply(node$children, function(kid) { (kid$qt_instances / node$qt_instances)^2 }));
    
    node$r = sqrt( node$parent_r ^ 2 / sum0) * (node$qt_instances / node$parent_instances);
  }
  
  return(node);
}

adjust.coordinate = function(coordinates, node)
{
  node_x_min = ifelse(node$isRoot, -node$r, node$x - node$r);
  node_x_max = ifelse(node$isRoot, node$r, node$x + node$r);
  node_y_min = ifelse(node$isRoot, -node$r, node$y - node$r);
  node_y_max = ifelse(node$isRoot, node$r, node$y + node$r);
  
  x_min = x_max = y_min = y_max = 0;      
  
  if(ncol(coordinates) > 0)
  {
    x_min = min(coordinates[ , 1]);
    x_max = max(coordinates[ , 1]);
    y_min = min(coordinates[ , 2]);
    y_max = max(coordinates[ , 2]);    
  }
  
  if(x_max == x_min)
  {
    if(ncol(coordinates) == 0)
      coordinates = cbind(coordinates, node_x_min)
    else
      coordinates[, 1] = node_x_min;
  }  
  else
    coordinates[, 1] = node_x_min + (coordinates[, 1] - x_min) / (x_max - x_min) * (node_x_max - node_x_min);
  
  if(y_max == y_min)
  { 
    if(ncol(coordinates) == 1)
      coordinates = cbind(coordinates, node_y_min)
    else    
      coordinates[, 2] = node_y_min;
  }else    
    coordinates[, 2] = node_y_min + (coordinates[, 2] - y_min) / (y_max - y_min) * (node_y_max - node_y_min);
  
  return(coordinates);
}

project.tree.rec = function(tree, dataset, type.projection, name.group)
{
  if(!is.null(tree) && !is.null(dataset) && !tree$isLeave)
  {
    if(tree$children[[1]]$isLeave)
    {
      dataset_aux = dataset[get.index(tree), get.numeric.columns(dataset, name.group)];
      
      if(type.projection == "force")
        vis = forceScheme(dist(dataset_aux))
      else if(type.projection == "lamp")
        vis = lamp(padding(dataset_aux, 4))
      else if(type.projection == "lsp")
        vis = lsp(padding(dataset_aux, 20))
      else if(type.projection == "mds")
        vis = cmdscale(dist(padding(dataset_aux, 3)))
      else if(type.projection == "pca")
        vis = prcomp(padding(dataset_aux, 3))$x[, 1:2]
      else if(type.projection == "plmp")
        vis = plmp(padding(dataset_aux, 10))
      else if(type.projection == "tsne")
        vis = tSNE(padding(dataset_aux, 2));
    }else
    {
      dataset_aux = get.data.center(tree, dataset, name.group);
      vis = forceScheme(dist(dataset_aux));
    }  
    
    tree = estimate.radius(tree, dataset, name.group);
    vis  = adjust.coordinate(vis, tree);
    
    for(i in 1:length(tree$children))
    {
      index = i;
      
      if(tree$children[[i]]$isLeave)
        index = which(rownames(dataset_aux) == as.character(tree$children[[i]]$row_index));
      
      tree$children[[i]]$x = vis[index, 1];
      tree$children[[i]]$y = vis[index, 2]; 
      
      #Teste adicionado por causa do HiPP_projection_cluster
      if(!tree$children[[i]]$isLeave) 
      {
        tree$children[[i]]$parent_r = tree$r;
        tree$children[[i]]$parent_instances = tree$qt_instances;
        tree$children[[i]] = project.tree.rec(tree$children[[i]], dataset, type.projection, name.group);      
      }
    }
  }
  
  return(tree);  
}

project.tree = function(tree, dataset, type.projection, name.group)
{
  if(!is.null(tree) && !is.null(dataset) && tree$isRoot)
  {
    # if(tree$children[[1]]$isLeave)
    #   dataset_aux = dataset[get.index(tree), get.numeric.columns(dataset, name.group)]
    # else
    #   dataset_aux = get.data.center(tree, dataset, name.group);
    
    if(tree$children[[1]]$isLeave)
    {
      dataset_aux = dataset[get.index(tree), get.numeric.columns(dataset, name.group)];

      if(type.projection == "force")
        vis = forceScheme(dist(dataset_aux))
      else if(type.projection == "lamp")
        vis = lamp(padding(dataset_aux, 4))
      else if(type.projection == "lsp")
        vis = lsp(padding(dataset_aux, 20))
      else if(type.projection == "mds")
        vis = cmdscale(dist(padding(dataset_aux, 3)))
      else if(type.projection == "pca")
        vis = prcomp(padding(dataset_aux, 3))$x[, 1:2]
      else if(type.projection == "plmp")
        vis = plmp(padding(dataset_aux, 10))
      else if(type.projection == "tsne")
        vis = tSNE(padding(dataset_aux, 2));
    }else
    {
      dataset_aux = get.data.center(tree, dataset, name.group);
      vis = forceScheme(dist(dataset_aux));
    }
    
    tree = estimate.radius(tree, dataset, name.group);
    vis  = adjust.coordinate(vis, tree);
    
    #====================================================================================================    
    tree$children = foreach(i = 1:length(tree$children), .combine = append, .export = LIST.ENV.FUNC, .packages = LIST.ENV.PKG)%dopar%
    {
      index = i;
      
      if(tree$children[[i]]$isLeave)
        index = which(rownames(dataset_aux) == as.character(tree$children[[i]]$row_index));
      
      tree$children[[i]]$x = vis[index, 1];
      tree$children[[i]]$y = vis[index, 2]; 
      
      #Teste adicionado por causa do HiPP_projection_cluster
      if(tree$children[[i]]$isLeave)
        list(tree$childre[[i]])
      else
      {
        tree$children[[i]]$parent_r = tree$r;
        tree$children[[i]]$parent_instances = tree$qt_instances;
        list(project.tree.rec(tree$children[[i]], dataset, type.projection, name.group));      
      }
    }
    #====================================================================================================            
  }
  
  return(tree);
}

dist.point = function (p1, p2)
{
  return (sqrt((p2$x - p1$x)^2 + (p2$y - p1$y)^2));
}

move.node = function(node, delta.x, delta.y)
{
  node$x = node$x + delta.x;
  node$y = node$y + delta.y;
  
  if(!node$isLeave)
  {
    for(i in 1:length(node$children))
      node$children[[i]] = move.node(node$children[[i]], delta.x, delta.y);
  }
  
  return(node);
}

spreader = function(node, max.iteration, threshold, frac)
{
  iteration = 1;
  
  repeat
  {
    changed  = FALSE;
    last_changed = changed;
    
    for(i in 1:length(node$children))
    {
      Ci = node$children[[i]];
      
      for(j in 1:length(node$children))
      {
        if(i != j)
        {
          Cj = node$children[[j]];
          d  = dist.point(Ci, Cj);
          s  = 0.2;
          
          if(!Ci$isLeave)
            s  = Ci$r + Cj$r;
          
          if(s < d)
            s = s + threshold;
          
          if(s > d)
          {
            delta = (s - d) / frac;
            vec   = c(Cj$x - Ci$x, Cj$y - Ci$y);
            
            if(vec[1] == 0 && vec[2] == 0)
              vec = c(delta, delta);
            
            vec_norm = sqrt(vec[1]^2 + vec[2]^2);
            vec2 = c(vec[1] / vec_norm, vec[2] / vec_norm);
            
            node$children[[i]] = move.node(Ci, -(vec2[1] * 3 * delta / 4), -(vec2[2] * 3 * delta / 4));
            node$children[[j]] = move.node(Cj, (vec2[1] * delta / 4), (vec2[2] * delta / 4));
            
            changed = TRUE;
          }
        }
      }
    }
    
    iteration = iteration + 1;
    
    if(last_changed == changed || iteration > max.iteration)
      break;
  }
  
  return(node);
}

spread.tree.rec = function(tree, max.iteration = 20, threshold = 0.1, frac = 4.0)
{
  if(!tree$isLeave)
  {
    if(is.null(max.iteration) || is.na(max.iteration))
      max.iteration = 20;
    if(is.null(threshold) || is.na(threshold))
      threshold = 0.1;
    if(is.null(frac) || is.na(frac))
      frac = 4.0;        
    
    for(i in 1: length(tree$children))
      tree$children[[i]] = spread.tree.rec(tree$children[[i]], max.iteration, threshold, frac);
    
    #Teste adicionado por causa do HiPP_projection_cluster
    if(!is.null(tree$children[[1]]$x))
      tree = spreader(tree, max.iteration, threshold, frac);
  }
  
  return(tree);  
}

spread.tree = function(tree, max.iteration = 20, threshold = 0.1, frac = 4.0)
{
  if(tree$isRoot)
  {
    if(is.null(max.iteration) || is.na(max.iteration))
      max.iteration = 20;
    if(is.null(threshold) || is.na(threshold))
      threshold = 0.1;
    if(is.null(frac) || is.na(frac))
      frac = 4.0;        
    
    #====================================================================================================    
    tree$children = foreach(i = 1:length(tree$children), .combine = append, .export = LIST.ENV.FUNC, .packages = LIST.ENV.PKG)%dopar%
    {
      list(spread.tree.rec(tree$children[[i]], max.iteration, threshold, frac));
    }
    #====================================================================================================        
    
    #Teste adicionado por causa do HiPP_projection_cluster
    if(!is.null(tree$children[[1]]$x))
      tree = spreader(tree, max.iteration, threshold, frac);    
  }
  
  return(tree);
}

xHiPP_cluster_projection = function(dataset, qt_cluster = 0, min.item = floor(sqrt(nrow(dataset))), cluster.algorithm = "kmeans", projection.algorithm = "force", 
                                   spread = TRUE, max.iteration = 20, threshold = 0.1, frac = 4.0, return.tree = TRUE, name.group = c("name", "group"),
                                   summary.path = "")
{
  tree = table2tree(dataset, name.group);

  if(!is.null(min.item) && !is.na(min.item) && !is.na(as.numeric(min.item)) && as.numeric(min.item) >= 2)
    tree$qt_min = as.numeric(min.item)
  else
    tree$qt_min = floor(sqrt(nrow(dataset)));
  
  tree = hierarchy(tree, dataset, qt_cluster, tree$qt_min, cluster.algorithm, name.group, summary.path = summary.path);
  tree = project.tree(tree, dataset, projection.algorithm, name.group); 

  if(spread)
    tree = spread.tree(tree, max.iteration, threshold, frac);

  if(return.tree)
    return(tree)
  else
    return(tree2table(tree));
}

xHiPP_projection_cluster = function(dataset, qt_cluster = 0, min.item = floor(sqrt(nrow(dataset))), cluster.algorithm = "kmeans", projection.algorithm = "force", 
                                   spread = TRUE, max.iteration = 20, threshold = 0.1, frac = 4.0, return.tree = TRUE, name.group = c("name", "group"),
                                   summary.path = "")
{
  tree = table2tree(dataset, name.group);
  
  if(!is.null(min.item) && !is.na(min.item) && !is.na(as.numeric(min.item)) && as.numeric(min.item) >= 2)
    tree$qt_min = as.numeric(min.item)
  else
    tree$qt_min = floor(sqrt(nrow(dataset)));
  
  tree = project.tree(tree, dataset, projection.algorithm, name.group);  
  aux1 = tree2table(tree);
  aux2 = as.data.frame(aux1); 
  
  if(length(which(colnames(dataset) == name.group[1])) > 0)
  {
    aux2 = cbind(aux2, dataset[, name.group[1]], stringsAsFactors = FALSE);
    colnames(aux2)[ncol(aux2)] = name.group[1];
  }  
  if(length(which(colnames(dataset) == name.group[2])) > 0)
  {
    aux2 = cbind(aux2, dataset[, name.group[2]], stringsAsFactors = FALSE);
    colnames(aux2)[ncol(aux2)] = name.group[2];
  }
  
  tree = hierarchy(tree, aux2, qt_cluster, tree$qt_min, cluster.algorithm, name.group, init.coord = TRUE, original.data = dataset, summary.path = summary.path);
  
  if(spread)
    tree = spread.tree(tree, max.iteration, threshold, frac);
  if(return.tree)
    return(tree)
  else
    return(aux1);
}

xHiPP_from_cluster = function(json, projection.algorithm = "force", spread = TRUE, max.iteration = 20, threshold = 0.1, frac = 4.0, return.tree = TRUE)
{
  tree    = tree2table(json, by.data = TRUE);
  dataset = as.data.frame(tree$dataset);  
  tree    = tree$tree;
  tree    = project.tree(tree, dataset, projection.algorithm, c("name", "group"));  
  
  if(spread)
    tree = spread.tree(tree, max.iteration, threshold, frac);
  if(return.tree)
    return(tree)
  else
    return(tree2table(tree));
}

xHiPP = function(data, operation, cluster.algorithm = "kmeans", projection.algorithm = "force", qt_cluster = 0, 
                spread = TRUE, max.iteration = 20, threshold = 0.1, frac = 4.0, return.tree = TRUE, name.group = c("name", "group"),
                process.type = process.types$ordinary, 
                summary.path = "")
{
  tree = NULL;

  QT.CORES <<- detectCores() - 1
  PROCESSING.TYPE <<- process.type
  registerDoParallel(cores = QT.CORES)
  cl = makeCluster(QT.CORES, "PSOCK")
  clusterEvalQ(cl, library("mp"))
  clusterEvalQ(cl, library("cluster"))
  
  if(file.exists(summary.path))
    do.call(file.remove, list(list.files(summary.path, full.names = TRUE)))
  
  if(operation == "cluster_projection")
    tree = xHiPP_cluster_projection(data, 
                                   qt_cluster = qt_cluster,
                                   min.item = floor(sqrt(nrow(data))), 
                                   cluster.algorithm = cluster.algorithm, 
                                   projection.algorithm = projection.algorithm, 
                                   spread = spread, 
                                   max.iteration = max.iteration, 
                                   threshold = threshold, 
                                   frac = frac, 
                                   return.tree = return.tree, 
                                   name.group = name.group,
                                   summary.path = summary.path)
  else if(operation == "projection_cluster")
    tree = xHiPP_projection_cluster(data, 
                                   qt_cluster = qt_cluster,
                                   min.item = floor(sqrt(nrow(data))), 
                                   cluster.algorithm = cluster.algorithm, 
                                   projection.algorithm = projection.algorithm, 
                                   spread = spread, 
                                   max.iteration = max.iteration, 
                                   threshold = threshold, 
                                   frac = frac, 
                                   return.tree = return.tree, 
                                   name.group = name.group, 
                                   summary.path = summary.path)
  else
    tree = xHiPP_from_cluster(data,          
                             projection.algorithm = projection.algorithm, 
                             spread = spread, 
                             max.iteration = max.iteration, 
                             threshold = threshold, 
                             frac = frac, 
                             return.tree = return.tree);
  
  stopCluster(cl)
  registerDoSEQ()
  
  return(tree);
}  
