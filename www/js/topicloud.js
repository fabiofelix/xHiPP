
var Word_Cloud = function()
{
  var _this = this;
  this.svg = null;
  
  this.load = function(tree, svg_word)
  {
    var sum_words  = _this.get_word_summary(tree);
    
    if(sum_words.items.length > 0)
      _this.load_cloud(svg_word, sum_words);  
  };  
  this.get_word_summary = function(tree)
  {
    var summary   = {total: 0,  max_count: 0, items: []},
        children  = tree.children.slice(),
        children2 = [];
    
    while(children.length > 0)
    {
      var kid = children[0];
      children.splice(0, 1);
      
      if(_this.get_property(kid, "isLeave"))
        children2.push(kid);
      else
        children = children.concat(kid.children);
    }  
    
    children2.forEach(function(kid, i, array)
    {
      var words = _this.get_property(kid, "words");
      
      if(words != undefined && words !== "")
      {
        words.forEach(function(word, i, array)
        {
          var index = -1;
          
          var sum_item = summary.items.find(function(item, j, array)
          {
            index = j;
            return item.text == word.text;
          });        
          
          if(sum_item == undefined)
            summary.items.push({text: word.text, freq: word.freq});
          else  
            summary.items[index].freq += word.freq;
  //         if(sum_item == undefined)
  //           summary.items.push({text: word.text, freq: 1});
  //         else  
  //           summary.items[index].freq++;        
        });
      }
    });
    
    summary.items.sort(function(a, b) { return b.freq - a.freq; });
    
    if(summary.items.length > 100)
      summary.items.splice(100);
    if(summary.items.length > 0)
      summary.max_count = summary.items[0].freq;  
    
    return summary;  
  };
  this.load_cloud = function(svg, summary)
  {
    _this.svg_word = svg;
    
    var fontSize = d3.scalePow().exponent(5).domain([1, summary.max_count]).range([20, 80]);
    var layout = d3.layout.cloud()
          .size([svg.attr("width"),  svg.attr("height")])
          .timeInterval(10)
          .words(summary.items)
          .rotate(function(d) { return 0; })
          .fontSize(function(d, i) {  return fontSize(d.freq);  })
          .fontWeight(["bold"])
          .text(function(d) { return d.text; })
          .spiral("rectangular") // "archimedean" or "rectangular"
          .on("end", _this.draw_words)
          .start();
          
    var g = svg.append("g")
          .attr("transform", "translate(" + 0 + "," + 0 + ")");        
    var wordcloud = g.append("g")
        .attr('class','wordcloud')
        .attr("transform", "translate(" + svg.attr("width") / 2 + "," + svg.attr("height") / 2 + ")");
  };
  this.draw_words = function(words) 
  {
    var color = d3.scaleOrdinal(d3.schemeCategory20);    
    _this.svg_word.select(".wordcloud").selectAll("text")
        .data(words)
        .enter().append("text")
        .attr('class','word')
        .style("fill", function(d, i) { return color(i); })
        .style("font-size", function(d) { return d.size + "px"; })
        .style("font-family", function(d) { return d.font; })
        .attr("text-anchor", "middle")
        .attr("transform", function(d) { return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")"; })
        .text(function(d) { return d.text; });
  };       
  this.get_property = function(obj, prop)
  {
    if(obj[prop] == undefined)
      return obj.data[prop];
    else
      return obj[prop];
  }
}
