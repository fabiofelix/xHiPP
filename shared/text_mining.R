#================================================================================#
#Set of generic functions
#
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
    files     = lapply(filenames, readLines);
    docs      = Corpus(VectorSource(files));
    
    docs = tm_map(docs, content_transformer(tolower));
    docs = tm_map(docs, removePunctuation);
    docs = tm_map(docs, removeNumbers);
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
    #remove whitespace
    docs = tm_map(docs, stripWhitespace);
    #Stem document
    docs = tm_map(docs, stemDocument);
    
    #Create document-term matrix
    dtm = DocumentTermMatrix(docs);
    rownames(dtm) = filenames;
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
  
  topicProbabilities = as.data.frame(ldaOut@gamma)
  # View(topicProbabilities)
  
  doc.terms = NULL;
  names = rownames(ldaOut.topics);
  
  for(i in 1:nrow(ldaOut.topics))
  {
    column  = ldaOut.topics[i, 1];
    # new_row = c(name = basename(names[i]), as.list(ldaOut.terms[, column]), TOPIC = paste("TOPIC", column, sep = ""));
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

get.tree.topic.new = function(tree, topics, qt.topics = 5)
{
  tree.terms  = topics[which(topics$name %in% get.tree.names(tree)), -1]
  tree.topics = tree.terms[, "TOPIC"]
  topic.words = c()  
  
  if(length(tree.topics) > 0)
  {
    index.topic = which(colnames(tree.terms) == "TOPIC")
    
    topic.words = table(tree.topics);
    topic.words = which.max(topic.words)
    topic.words = names(topic.words)
    topic.words = which(tree.terms[, "TOPIC"] == topic.words)
    topic.words = tree.terms[topic.words[1], -index.topic]
    topic.words = as.vector(unlist(topic.words))
  }
  
  return(topic.words)
}

get.tree.topic = function(tree, topics)
{
  tree.topics = topics[which(topics$name %in% get.tree.names(tree)), -1]
  topic.list  = c()
  
  if(nrow(tree.topics) > 0)
  {
    for(j in 1:ncol(tree.topics))
    {
      h     = sort(table(tree.topics[, j]), decreasing = TRUE);
      topic = ""
  
      for(k in 1:length(h))
      {
        topic = names(h[k])
        
        if( topic %in% topic.list  )
          topic = ""
        else
          break
      }
      
      if(topic != "")
        topic.list = c(topic.list, topic)
    }
  }
  return(topic.list)
}

extract.tree.topics.new = function(tree, text.path, topics = NULL, data = NULL, topic.as.group = TRUE)
{
  if(tree$isRoot)
  {
    if(file.exists(file.path(text.path, "topics_hippTree.csv")))
      topics = read.csv(file.path(text.path, "topics_hippTree.csv"))
    else
    {
      p = preprocess.text(text.path);
      topics = extract.topic.terms(p$term.matrix, qt.topics = tree$qt_cluster);
      # topics = extract.topic.tfidf(p$term.matrix);
      write.csv(topics, file.path(text.path, "topics_hippTree.csv"), row.names = FALSE);
    }
    
    # name.index = which(colnames(data) == "name");
    # group.index = which(colnames(data) == "group");
    # 
    # rownames(data) = data[, name.index];
    # data = data[ , -c(name.index, group.index)];
    # 
    # topics = extract.topic.tfidf(data);
    
    for(i in 1:length(tree$children))
      tree$children[[i]] = extract.tree.topics.new(tree$children[[i]], text.path, topics = topics, topic.as.group = topic.as.group);    
  }else if(tree$isLeave)
  {
    tree$topics = as.matrix(topics[which(topics$name == tree$name), -1]);
    tree$topics = as.character(tree$topics);
    
    if(topic.as.group)
      tree$group  = tree$topics[length(tree$topics)]    
    
    tree$topics = tree$topics[-length(tree$topics)]
  }else
  {
    tree$topics = get.tree.topic.new(tree, topics)
    
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

# extract.tree.topics = function(tree, text.path)
# {
#   if(tree$isLeave)
#   {
#     p      = preprocess.text(text.path, list.file = c(paste(text.path, "/", tree$name, sep = "")));
#     topics = extract.topic.terms(p$term.matrix);
#     tree$topics = "";
#     
#     if(nrow(topics) > 0)    
#       tree$topics = c(topics[1, -1]);
#   }else if(tree$isRoot)
#   {
#     for(i in 1:length(tree$children))
#       tree$children[[i]] = extract.tree.topics(tree$children[[i]], text.path);
#   }else
#   {
#     data = NULL;
#     
#     for(i in 1:length(tree$children))
#     {
#       tree$children[[i]] = extract.tree.topics(tree$children[[i]], text.path);
#       
#       if(is.null(data))
#         data = data.frame(tree$children[[i]]$topics, stringsAsFactors = FALSE)
#       else
#         data = rbind(data, tree$children[[i]]$topics)   
#       
#       tree$topics = unlist(tree$children[[i]]$topics);      
#     }  
#     
#     list.topics = NULL;    
#     
#     for(i in 1:ncol(data))
#     {
#       sorted = sort(table(data[, i]), decreasing = TRUE);
#       list.topics = c(list.topics, names(sorted[1]));
#     }
#     
#     tree$topics = list.topics;      
#   }
#   
#   return(tree);
# }

# abc = preprocess.text("/home/fabio/Documentos/Mestrado/Pesquisa/Hipp/www/data/teste");
# def = extract.topic.terms(abc$term.matrix)
# View(def)


# filenames = list.files("/home/fabio/Documents/Pesquisa/Text", pattern = "*.txt")
# files     = lapply(filenames, readLines)
# docs      = Corpus(VectorSource(files))

# writeLines(as.character(docs[[30]]))

#remove potentially problematic symbols
# docs = tm_map(docs, content_transformer(tolower))
# toSpace = content_transformer(function(x, pattern) { return (gsub(pattern, " ", x))})
# docs = tm_map(docs, toSpace, "-")
# docs = tm_map(docs, toSpace, "'")
# docs = tm_map(docs, toSpace, ".")
# docs = tm_map(docs, toSpace, "'")
# docs = tm_map(docs, toSpace, "'")


#remove punctuation
# docs = tm_map(docs, removePunctuation)
#Strip digits
# docs = tm_map(docs, removeNumbers)
#remove stopwords
# docs = tm_map(docs, removeWords, stopwords("english"))
#remove whitespace
# docs = tm_map(docs, stripWhitespace)
#Stem document
# docs = tm_map(docs, stemDocument)

#Create document-term matrix
# dtm = DocumentTermMatrix(docs)
# rownames(dtm) = filenames
# freq = colSums(as.matrix(dtm))

# ord = order(freq, decreasing = TRUE)
# freq = freq[ord]
# write.csv(freq, "word_freq.csv")


#Necessário instalar no Linux o pacote gsl (GNU Scientific Library)
# require("topicmodels")

# burnin <- 4000
# iter <- 2000
# thin <- 500
# seed <-list(2003,5,63,100001,765)
# nstart <- 5
# best <- TRUE
# k = 5
# 
# ldaOut <-LDA(dtm, k, method="Gibbs", control=list(nstart=nstart, seed = seed, best=best, burnin = burnin, iter = iter, thin=thin))


# ldaOut = LDA(dtm, 5);
# ldaOut.topics = as.matrix(topics(ldaOut))
# View(ldaOut.topics)

# ldaOut.terms = as.matrix(terms(ldaOut, 6))
# View(ldaOut.terms)

# topicProbabilities = as.data.frame(ldaOut@gamma)
# View(topicProbabilities)

# topic1ToTopic2 = lapply(1:nrow(dtm), function(x) sort(topicProbabilities[x,])[k] / sort(topicProbabilities[x, ])[k - 1])
# topic2ToTopic3 = lapply(1:nrow(dtm),function(x) sort(topicProbabilities[x,])[k - 1]/sort(topicProbabilities[x, ])[k - 2])







