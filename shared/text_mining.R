#================================================================================#
#Set of generic functions
#
#Changed: 05/03/2021
#         Added stopwords directory
#         Added docterms inferior/superior frequency limits
#         Removed warnnings about Vector Source
#Changed: 05/04/2018
#         Added tfidf function
#         Extend list of 'stop words' in preprocess.text funcntion
#changed: 04/26/2018
#         Changed get.text.words
#changed: 04/22/2018
#         Added get.tree.topic.new to substitute get.tree.topic
#Changed: 04/20/2018
#         Added extract.topic.tfidf to use into extract.tree.topics.new
#Changed: 11/15/2017
#         extract.tree.topics.new corrected topics from leaves 
#Changed: 11/06/2017
#         extract.tree.topics.new can save and read a topics table
#Changed: 10/04/2017
#         Added function extract.tree.topics to extract topics from Hipp.tree
#Created: 10/03/2017
#         Created from https://eight2late.wordpress.com/2015/09/29/a-gentle-introduction-to-topic-modeling-using-r/
#================================================================================#

# Instalar no R pacote SnowballC para a stem funcionar
require("tm");
# Instalar no Linux o pacote gsl (GNU Scientific Library)
require("topicmodels");

preprocess.text = function(source.path, file.type = ".txt", list.file = NULL)
{
  if(is.null(list.file) || is.na(list.file))
    filenames = list.files(source.path, pattern = file.type, full.names = TRUE)
  else
    filenames = list.file;
  
  if(length(filenames) > 0)
  {  
    files = lapply(filenames, function(file) { paste(stringi::stri_read_lines(file), collapse = " ") });    
    docs  = Corpus(DataframeSource(data.frame(doc_id = basename(filenames), text = unlist(files))));
    
    docs = tm_map(docs, content_transformer(tolower));
    docs = tm_map(docs, removePunctuation);
    docs = tm_map(docs, removeNumbers);

    stopword.path = adjust.path(file.path(getwd(), "shared", "stopwords"))
    stop.words = list.files(stopword.path, pattern = ".spw", full.names = TRUE)

    if(length(stop.words) > 0)
    {
      stop.words = lapply(stop.words, readLines)
      stop.words = unlist(stop.words)
      stop.words = unique(stop.words)
      
      limit = ceiling(length(stop.words) / 100)
      
      for(i in 1:limit)
      {
        begin = (i - 1) * 100 + 1
        end   = ifelse(i == limit, length(stop.words), (i * 100))
        docs = tm_map(docs, removeWords, stop.words[ begin : end ]);
      }
    }else
    {
      docs = tm_map(docs, removeWords, stopwords("english"));
      docs = tm_map(docs, removeWords, c("sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday",
                                         tolower(month.name),
                                         "day", "week", "weekend", "month", "year", "second", "minute", "hour",
                                         "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
                                         "hundred", "million", "billion", 
                                         "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "nineth", "tenth",
                                         "dont", "didnt", "wont", "woudnt", "coudnt", "cant", "cannot", "wasnt", "werent",
                                         "new", "old", "tall", "short", "great", 
                                         "late", "early", "latest", "earlier"));
      docs = tm_map(docs, removeWords, tolower(month.name));    
    }
    
    #remove whitespace
    docs = tm_map(docs, stripWhitespace);
    #Stem document
    docs = tm_map(docs, stemDocument);
    
    #Create document-term matrix
    limit.inf = ceiling(0.01 * length(files)) #remove terms that appear in less than 1% of documents
    limit.sup = ceiling(0.5 * length(files))  #remove terms that appear in more than 50% of documents
    dtm = DocumentTermMatrix(docs, control = list(bounds = list(global = c(limit.inf, limit.sup))));
    # dtm = DocumentTermMatrix(docs);    
    rownames(dtm) = filenames;
    rowTotals = apply(dtm, 1, sum) 
    dtm = dtm[rowTotals > 0, ] #remove documents with no terms
    freq = colSums(as.matrix(dtm));
    freq = freq[order(freq, decreasing = TRUE)];
    
    return(list(term.matrix = dtm, fequency.matrix = freq));
  }else
    return(list(term.matrix = NULL, fequency.matrix = NULL));
}

extract.topic.terms = function(term.matrix, qt.topics = 5, qt.terms = 5, seed.value = 2153)
{
  # set.seed(seed.value);
  ldaOut = LDA(term.matrix, qt.topics, control = list(seed = seed.value));
  ldaOut.topics = as.matrix(topics(ldaOut))
  # View(ldaOut.topics)
  
  ldaOut.terms = as.matrix(terms(ldaOut, qt.terms))
  # View(ldaOut.terms)

  doc.terms = NULL;
  names = rownames(ldaOut.topics);
  
  for(i in 1:nrow(ldaOut.topics))
  {
    column  = ldaOut.topics[i, 1];
    col.desc = stringi::stri_pad_left(as.character(column), nchar(as.character(qt.topics)), pad = "0")
    new_row = c(basename(names[i]), as.list(ldaOut.terms[, column]), paste("TOPIC", col.desc, sep = ""));    
    names(new_row) = c("name", paste("t", seq(1, qt.terms), sep = ""), "TOPIC");
    
    # cat(names[i], column, as.character(ldaOut.terms[, column]), "\n");
    
    if(is.null(doc.terms))
      doc.terms = data.frame(new_row, stringsAsFactors = FALSE)
    else
      doc.terms = rbind(doc.terms, new_row)
  }  
  
  return(doc.terms);
}

extract.topic.tfidf = function(term.matrix, qt.topics = 5)
{
  tf = as.matrix(term.matrix)
  df = apply(tf, 2, function(col) sum(col > 0, na.rm = TRUE))
  
  topics    = NULL;
  file.names = basename(rownames(tf))
  
  for(i in 1:nrow(tf))
  {
    tf[i, ]    = tf[i, ] * log(nrow(tf) / (1 + df))

    row.topics = tf[i, order(tf[i, ], decreasing = TRUE)]
    row.topics = row.topics[1:qt.topics];
    row.topics = row.topics[row.topics > 0];
    row.topics = row.topics[order(names(row.topics))];
    row.topics = c(names(row.topics), rep("", qt.topics - length(row.topics)))
    
    new.row = c(name = file.names[i], as.list(row.topics))
    names(new.row) = c("name", paste("t", seq(1, qt.topics), sep = ""));
    
    if(is.null(topics))
      topics = data.frame(new.row, stringsAsFactors = FALSE)
    else
      topics = rbind(topics, new.row)
  }  
  
  return(topics);
}

tfidf = function(data)
{
  tf = as.matrix(data)
  df = apply(tf, 2, function(col) sum(col > 0, na.rm = TRUE))

  for(i in 1:nrow(tf))
    tf[i, ] = tf[i, ] * log(nrow(tf) / (1 + df))

  return(tf);  
}

get.tree.terms.new = function(tree, topics, qt.topics = 5)
{
  tree.terms  = topics[which(topics$name %in% get.tree.names(tree)), -1]
  tree.topics = tree.terms[, "TOPIC"]
  topic.terms = c()  
  
  if(length(tree.topics) > 0)
  {
    index.topic = which(colnames(tree.terms) == "TOPIC")
    
    topic.terms = table(tree.topics);
    topic.terms = which.max(topic.terms)
    topic.terms = names(topic.terms)
    topic.terms = which(tree.terms[, "TOPIC"] == topic.terms)
    topic.terms = tree.terms[topic.terms[1], -index.topic]
    topic.terms = as.vector(unlist(topic.terms))
  }
  
  return(topic.terms)
}

extract.tree.topics.new = function(tree, text.path, topics = NULL, data = NULL, topic.as.group = TRUE)
{
  if(tree$isRoot)
  {
    text.path = adjust.path(text.path)
    path      = adjust.path(file.path(text.path, "topics_hippTree.csv"))
    
    if(file.exists(path))
      topics = read.csv(path)
    else
    {
      p = preprocess.text(text.path);
      topics = extract.topic.terms(p$term.matrix, qt.topics = tree$qt_cluster);
      write.csv(topics, path, row.names = FALSE);
    }

    for(i in 1:length(tree$children))
      tree$children[[i]] = extract.tree.topics.new(tree$children[[i]], text.path, topics = topics, topic.as.group = topic.as.group);    
  }else if(tree$isLeave)
  {
    tree$terms = as.matrix(topics[which(topics$name == tree$name), -1]);
    tree$terms = as.character(tree$terms);
    
    if(topic.as.group)
    {
      tree$group = ifelse(length(tree$terms) == 0, "ZERO TERMS", tree$terms[length(tree$terms)])
      
      if(length(tree$terms) == 0)
        cat("warnning: ", tree$name, " has no topic terms\n")
    }  

    tree$terms = tree$terms[-length(tree$terms)]
  }else
  {
    tree$terms = get.tree.terms.new(tree, topics)
    
    for(i in 1:length(tree$children))
      tree$children[[i]] = extract.tree.topics.new(tree$children[[i]], text.path, topics = topics, topic.as.group = topic.as.group);        
  }
  
  return(tree);
}

get.text.words = function(data, k = 100)
{
  names = colnames(data);
  aux   = which(!is.na(data));
  
  if(length(aux) > 0)
  {
    names = names[aux];
    data  = data[, aux];
  }  

  aux = which(data != 0);
  
  if(length(aux) > 0)
  {
    names = names[aux];
    data  = data[, aux]; 
  }  
  
  col.order = order(data, decreasing = TRUE)
  names = names[col.order]
  data  = data[col.order];
  k     = ifelse(k > length(data), length(data), k)
  words = list();
  
  for(i in 1:k)
  {
    word = list(text = names[i], freq = as.numeric(data[i]))
    words = append(words, list(word))
  }  

  return(words);
}

