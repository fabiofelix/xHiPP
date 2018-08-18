var TREE_MAP_FOCUS = null;

var Tree_Map = function(vd, s)
{
  var _this = this;
  this.view_data = vd;
  this.sync = s;
  this.node_focused = null;
  
  if(vd == undefined)
    throw "ViewData undefined";
  if(s == undefined)
    throw "Sync undefined";    
  
  this.load = function(tree, svg)
  {
    var treemap = d3.treemap()
  //       .tile(d3.treemapBinary)
  //       .tile(d3.treemapDice)
  //       .tile(d3.treemapSlice)
  //       .tile(d3.treemapSliceDice)
        .tile(d3.treemapSquarify)
  //       .tile(d3.treemapResquarify)
        .size([svg.attr("width"), svg.attr("height")])
        .round(true)
        .paddingInner(1);

    var root = d3.hierarchy(tree)
        .eachBefore(function(d) { d.data.id = (d.parent ? d.parent.data.id + "." : "") + d.data.name; })
        .sum(function(d) {return d.children ? 0 : 1} )  //sumByCount
//         .sum(function(d) {return 1} )  //sumBySize
        .sort(function(a, b) { return b.value - a.value; }), 
        tree = treemap(root),
        nodes = tree.leaves();
    
    _this.node_focused = root;
    _this.create_rect(tree, svg, root);
  };
  this.create_rect = function(tree, svg, root)
  {
    var cell = svg.selectAll("g")
      .data(tree.descendants())
      .enter().append("g")
        .attr("transform", function(d) { return "translate(" + d.x0 + "," + d.y0 + ")"; })
        .each(function(d) { if(!d.data.isRoot && !d.data.isLeave) d.node = this; });

    cell.append("rect")
        .attr("id", function(d) { return d.data.id; })
        .attr("width", function(d) { return d.x1 - d.x0; })
        .attr("height", function(d) { return d.y1 - d.y0; })
        .attr("fill", function(d) 
        { 
          return _this.sync.fill_obj(d, false, true);
        })
        .on("click", function(d) 
        { 
          var node = _this.node_focused == d.parent ? root : d.parent;
          _this.zoom(node, svg, d3.event);
          _this.sync.sincronize(node, "packedmap");
        })
        .on("mouseover", function(d)
        {
          _this.view_data.show_image_tooltip(d.data.isLeave && _this.view_data.isMediaData(d.data.name), {name: d.data.name});
        })
        .on("mouseleave", function(d)
        {
          _this.view_data.show_image_tooltip(false);
        })      

    cell.append("title").text(function(d) { return d.data.name });        
  };
  this.zoom = function(d, svg, event) 
  {
    _this.node_focused = d;
    
    var x  = d3.scaleLinear().range([0, svg.attr("width")]).domain([d.x0, d.x1]),
        y  = d3.scaleLinear().range([0, svg.attr("height")]).domain([d.y0, d.y1]),  
        kx = svg.attr("width") / (d.x1 - d.x0), ky = svg.attr("height")   / (d.y1 - d.y0);

    var transition = svg.selectAll("g").transition()
        .duration(d3.event.altKey ? 7500 : 750)
        .attr("transform", function(d) { return "translate(" + x(d.x0) + "," + y(d.y0) + ")"; });

    transition.select("rect")
        .attr("width", function(d) { return kx * (d.x1 - d.x0) - 1; })
        .attr("height", function(d) { return ky * (d.y1 - d.y0) - 1; })
    
    svg.selectAll("g").selectAll("text").remove();
    
    if(d.parent)
      svg.selectAll("g").append("text").on("click", function(obj){ _this.view_data.show( Utils.extract_name(obj), Utils.extract_parent_children_name(obj) ); })
        .selectAll("tspan")
          .data(function(d) { return d.data.name.split(/(?=[A-Z][^A-Z])/g); })
        .enter().append("tspan")
          .attr("x", 4)
          .attr("y", function(d, i) { return 13 + i * 10; })
          .text(function(d) { return d; });  

    event.stopPropagation();  
  };
  this.hovered = function(obj, hover, threshold)
  {
    d3.selectAll(obj.ancestors().map(function(d) { if(d.depth == threshold) return d.node; }))
      .classed("node--hover", hover);
  }
}
