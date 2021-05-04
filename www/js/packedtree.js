
var View_States = {normal: 0,  medoid: 1, transparent: 2, points: 3};
    
// https://stackoverflow.com/questions/14167863/how-can-i-bring-a-circle-to-the-front-with-d3  
d3.selection.prototype.moveToFront = function() 
{
  var item = this._groups[0][0];
  var children = item.__data__.descendants();
  
  item.parentNode.appendChild(item);
  
  if(children)
    children.forEach(function(data, i, array)
    {
      var select = d3.select(data.svg_item)._groups[0][0];
      select.parentNode.appendChild(select);
    });    
};  

d3.selection.prototype.moveToBack = function() 
{ 
  return this.each(function() 
  { 
    if(this.parentNode.firstChild) 
      this.parentNode.insertBefore(this, this.parentNode.firstChild); 
  }); 
};      

//========================================================================================================//

var PackedTree = function(vd, s)
{
  var _this = this;
  this.view_data = vd;
  this.sync = s;
  this.node_focused = null;
  this.viewing_state = View_States.normal;
  this.interpolation_view = null;
  this.dimensions = {margin: 0, padding: 0};
  this.previous_obj = null;
  this.svg = null;
  
  if(vd == undefined)
    throw "ViewData undefined";
  if(s == undefined)
    throw "Sync undefined";  
  
  this.load = function(tree, svg)
  {
    _this.svg = svg;
    _this.view_data.reset_show();
    
    var root = d3.hierarchy(tree)
        .sum(function(d) { return d.size; })
        .sort(function(a, b) { return b.value - a.value; });
        
    _this.node_focused = root;
    
    svg.on("click", function() 
        { 
          if(!_this.view_data.showing_data) 
          {
            _this.zoom(root, svg, d3.event); 
            _this.sync.sincronize(root, "treemap"); //cf. main.js 
          }  
       
          _this.view_data.reset_show();
        }); 
    
    var hp = new xHiPP_pack(),
        tree_packed = hp.pack(root, _this.summary(root), svg.attr("width") - _this.dimensions.margin - _this.dimensions.padding, svg.attr("height") - _this.dimensions.margin - _this.dimensions.padding),
        nodes = tree_packed.descendants();

    _this.sync.load_groups(nodes);

    var g = svg.append("g")
          .attr("transform", "translate(" + svg.attr("width") / 2 + "," + svg.attr("height") / 2 + ")")
          .attr("x", "50%").attr("y", "50%");

    _this.create_defs(g, nodes, true);
    _this.create_defs(g, nodes, false); 
    var circle = _this.create_circle(svg, g, nodes);    
    _this.create_text_title(g, circle, nodes, root);

    _this.zoomTo([root.x, root.y, root.r * 2 + _this.dimensions.margin], svg);
    _this.sync.show_values(root);      
  };
  this.create_defs = function (g, nodes, TESTE)
  {
    var inter_nodes = null;
    
    if(TESTE)
      inter_nodes = nodes.filter(function(d) { 
        return !d.data.isRoot && !d.data.isLeave && (_this.view_data.isImage(d.data.medoid_name) || _this.view_data.isAudio(d.data.medoid_name)); 
      });
    else
      inter_nodes = nodes.filter(function(d) { 
        return !d.data.isRoot && !d.data.isLeave && !_this.view_data.isMediaData(d.data.medoid_name); 
      });      
    
    var defs = g.selectAll("defs")
    .data(inter_nodes)
    .enter()
    .append("defs")
    .append("pattern")
    .attr("id", function(d)
    {
      var index = d.data.medoid_name.lastIndexOf(".");
      var name  = d.data.medoid_name.substring(0, index);     
      return name;
    })
    .attr("height", 1)
    .attr("width", 1)
    .attr("preserveAspectRatio", "none")
    .attr("viewBox", function(d) { return "0 0 " + String(d.r * 2) + " " + String(d.r * 2); })
    .append("image")
    .attr("xlink:href", function(d)
    {
      if(TESTE)
        return _this.view_data.get_path(d.data.medoid_name);
      else  
        return _this.view_data.aux_path + d.data.summary;
    })
    .attr("type", "image/png")
    .attr("height", function(d){ return d.r * 2 ; } )
    .attr("width", function(d){ return d.r * 2; }  )
    .attr("preserveAspectRatio", "none");
  };
  this.create_circle = function (svg, g, nodes)
  {
    var circle = g.selectAll("circle")
      .data(nodes)
      .enter()
      .append("circle")
        .attr("class", function(d) 
        { 
//TODO: verificar se � necess�rio
          d.svg_item = this;
          return d.parent ? d.children ? "node" : "node node--leaf" : "node node--root"; 
        })
        .style("fill", function(d) 
        { 
          return _this.sync.fill_obj(d);
        })
        .on("click", function(d)
        { 
          if(d.children)
          {
            if (_this.node_focused !== d)
              _this.zoom(d, svg, d3.event);

            _this.sync.sincronize(d, "treemap");
          } 
          else
          {  
            _this.sync.sincronize(d.parent, "treemap", true);
            _this.view_data.show( Utils.extract_name(d), Utils.extract_parent_children_name(d) );
          }  
        })
        .style("visibility", function(d)
        {
          return d.depth >= 2 ? "hidden" : "visible";
        })      
        .on("mouseover", function(d)
        {
          d3.select(this).moveToFront();  

//TODO: criar uma classe css          
          this.style.stroke      = "#000";
          this.style.strokeWidth = 1.5;    
          
          _this.sync.hover_treemap(d, true);
          
          var force_presentation = false;
                       
          if(!_this.view_data.isMediaData(d.data.name))
            force_presentation = !d.data.isLeave && !d.data.isRoot;
         
          _this.view_data.show_image_tooltip(true, {name: d.data.name, alternative: d.data.summary}, 
              force_presentation, {X: d3.event.pageX, Y: d3.event.pageY});
        })
        .on("mouseleave", function(d)
        {
          if(_this.view_data.showing_data)
            _this.previous_obj = this;
            else
            {
//TODO: criar uma classe css
            this.style.stroke      = "#646464";
            this.style.strokeWidth = 0.5;

            if(_this.previous_obj)
            {
              _this.previous_obj.style.stroke      = "#646464";
              _this.previous_obj.style.strokeWidth = 0.5;              
              _this.previous_obj = null;
            }
          }

          _this.view_data.reset_show();

          _this.sync.hover_treemap(d, false);
          _this.view_data.show_image_tooltip(false);
        });
        
    return circle;        
  };
  this.create_text_title = function (g, circle, nodes, root)
  {
    circle.append("title").text(function(d) 
    { 
      if(d.data.terms != undefined && d.data.terms !== "")
        return d.data.isLeave ? d.data.name + " (" + d.data.terms.filter(String) + ")" : d.data.terms.filter(String);
      else if(d.data.isLeave)
        return d.data.name;
    });   
    
    var text = g.selectAll("text")
      .data(nodes)
      .enter().append("text")
        .attr("class", "label")
        .style("fill-opacity", function(d) { return d.parent === root ? 1 : 0; })
        .style("display", function(d) { return d.parent === root ? "inline" : "none"; })
        .text(function(d) 
        { 
          if(typeof(d.data.name) != "string" || _this.view_data.isMediaData( Utils.extract_name(d).name ) )
            return "";
          else
          {
            var text = "";
            
            if(d.data.name !== undefined)
              text += d.data.name;
            if(d.data.group !== undefined)
              text += (text !== "" ? " - " : "" ) + d.data.group;                
            
            return text;
          }
        });  
  };   
  this.summary = function(tree)
  {
    var sum = {min_x: Number.MAX_VALUE, min_y: Number.MAX_VALUE, max_x: Number.MIN_VALUE, max_y: Number.MIN_VALUE};
    
    tree = tree.each(function(node)
    {
      if(!node.data.isRoot && typeof(node.data.x) != "undefined")
      {
        sum.min_x = Math.min(sum.min_x, node.data.x);
        sum.min_y = Math.min(sum.min_y, node.data.y);
        sum.max_x = Math.max(sum.max_x, node.data.x);
        sum.max_y = Math.max(sum.max_y, node.data.y);          
      }
    });    
    
    return(sum);
  };
  this.get_fill_group = function (d)
  {
    if(!d.data.isRoot && !d.data.isLeave)
    {  
      var index = d.data.medoid_name.lastIndexOf(".");
      var name  = d.data.medoid_name.substring(0, index);             
      
      return "url(#" + name + ")";
    }
    else
      return _this.sync.fill_obj(d);      
  };
  this.adjust_circles = function(last_focus)
  {
    if(_this.viewing_state != View_States.transparent)
    {
      var children = _this.node_focused.descendants();
      
      children.forEach(function(data, i, array)
      {
        d3.select(data.svg_item)
        .style("visibility", function(d)
        {
          if(!d.parent || d === _this.node_focused || d.parent === _this.node_focused)
            return "visible";
          else if(d.parent && (!d.children || (d.depth > _this.node_focused.depth && d.parent !== _this.node_focused)))
            return "hidden";
          else 
            return this.style.visibility;
        }); 
      });
    }  
    if(_this.viewing_state == View_States.medoid)
    {
      var parents = _this.node_focused.ancestors();
      
      d3.selectAll("circle")
        .style("fill", function(d) 
        { 
          if(d === _this.node_focused || parents.indexOf(d) > -1)
            return _this.sync.fill_obj(d);    
          else if(d === last_focus) 
            return _this.get_fill_group(d);
          else 
            return this.style.fill;
        });     
    }    
  };
  this.zoom = function(d, svg, event) 
  {
    var last_focus = _this.node_focused;
    _this.node_focused = d;

    var transition = d3.transition()
        .duration(750) //milliseconds
        .tween("zoom", function(d) 
        {
          var inter = d3.interpolateZoom(_this.interpolation_view, [_this.node_focused.x, _this.node_focused.y, _this.node_focused.r * 2 + _this.dimensions.margin]);
          return function(t) { _this.zoomTo(inter(t), svg); };
        });
                
    _this.adjust_circles(last_focus);
    
    transition.selectAll("text")
      .filter(function(d) { return d.parent === _this.node_focused || this.style.display === "inline"; })
        .style("fill-opacity", function(d) { return d.parent === _this.node_focused ? 1 : 0; })
        .on("start", function(d) { if (d.parent === _this.node_focused) this.style.display = "inline"; })
        .on("end", function(d) { if (d.parent !== _this.node_focused) this.style.display = "none"; });      

    _this.view_data.show( Utils.extract_name(_this.node_focused), Utils.extract_parent_children_name(_this.node_focused) );
    _this.sync.show_values(_this.node_focused);
    event.stopPropagation();     
  };
  //Precisa selecionar todos os itens svg porque todos precisam ter seus atributos modificados,
  //tanto os que est�o sendo focados quanto os demais
  this.zoomTo = function (iv, svg) 
  {
    _this.interpolation_view = iv;
    var k = Math.min(svg.attr("width"), svg.attr("height")) / _this.interpolation_view[2]; 
    
    svg.selectAll("circle,text")
      .attr("transform", function(d) { return "translate(" + (d.x - _this.interpolation_view[0]) * k + "," + (d.y - _this.interpolation_view[1]) * k + ")"; })
      .attr("r", function(d) 
      {
        if(this.tagName == "circle")
          return d.r * k;
        else
          return d.r;
      });  
  };  
  this.add_circles = function()
  {
    _this.viewing_state = View_States.normal;  
    
    d3.selectAll("circle")
    .style("visibility", function(d)
    {
      return d.depth >= 2 ? "hidden" : "visible"; //deixa vis�veis a raiz (depth = 0) e seus filhos (depth = 1) 
    })
    .style("fill", function(d) 
    { 
      if(d.children)
        return _this.sync.fill_obj(d);
      else
        return this.style.fill;
    });  
  };
  this.remove_circles = function()
  {
    _this.viewing_state = View_States.points;
    
    d3.selectAll("circle")
    .style("visibility", function(d)
    {
      return d.children ? "hidden" : "visible";        
    });
  };
  this.transparent_circles = function ()
  {
    _this.viewing_state = View_States.transparent;
    
    d3.selectAll("circle")
    .style("visibility", function(d)
    {
      return "visible";
    })   
    .style("fill", function(d) 
    { 
      if(d.children)
        return _this.sync.fill_obj(d, true);
      else
        return this.style.fill;   
    });
  };
  this.show_img_medoid = function ()
  {
    var circles = d3.selectAll("circle").filter(function(d) { 
      return d.data.isLeave && (_this.view_data.isImage(d.data.name) || _this.view_data.isAudio(d.data.name)); 
    });    
    
    if(circles._groups[0].length > 0)
    {
      _this.add_circles();
      _this.viewing_state = View_States.medoid;      
      d3.selectAll("circle")
      .style("fill", function(d) 
      { 
        if(!d.data.isRoot && !d.data.isLeave)
          return _this.get_fill_group(d);
        else
          return this.style.fill;
      });        
    }  
  };
  this.cluster2csv = function()
  {
    if(_this.node_focused)
    {
      var items = _this.node_focused.descendants();
      var array_data = [],
          array_names = [];
      
      $.each(items, 
        function(i, obj)
        {
          if(obj.data.isLeave)
          {
            array_data.push([obj.data.x, obj.data.y]);              
            array_names.push({name: obj.data.name, group: obj.data.group});              
          }
        }
      );

      if(array_data.length > 0)
        download_data(array_data, "Cluster_xHiPP.csv", array_names);      
    }
  };
}
