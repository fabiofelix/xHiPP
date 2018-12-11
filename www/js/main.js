var FILE_NAME = "",
    VIS = null;

$(document).ready(
  function()
  {
    VIS = new Vis();
    
    $(document).on("click", "#load_button", load_csv); 
    $(document).on("click", "#load_button_tree", load_tree);
    $(document).on("click", "#load_button_group", load_group);

    $(document).on("click", "#show_point", VIS.packed.remove_circles);
    $(document).on("click", "#transparent", VIS.packed.transparent_circles); 
    $(document).on("click", "#normal", VIS.packed.add_circles); 
    $(document).on("click", "#medoid", VIS.packed.show_img_medoid);
    $(document).on("click", "#cluster2csv", VIS.packed.cluster2csv);        
    
    
    $("#userFile").fileinput({
        showPreview: false, 
        showUpload: false, 
        showRemove: false,
        showCancel: false,
        allowedFileExtensions: ["csv", "json"],
        browseLabel: ""
    }); 
    
    $("#userFile").fileinput("reset");
    
    //Adicionado por causa de uma modificação no shiny.js this.makeRequest('uploadEnd'... que limpa o valor do input
    $("#userFile").change(function(){ FILE_NAME = $("#userFile").val(); });
    
    $("#show_values").tooltip({html: true, title: $("#my-tooltip").html(), placement: "bottom", tip: "my-tooltip" });

    var config = [
      {button: "#order_button",      source: ".order_values",      target: "#order",                default_value: "cluster_projection"},
      {button: "#cluster_button",    source: ".cluster_values",    target: "#cluster_algorithm",    default_value: "kmeans"},
      {button: "#projection_button", source: ".projection_values", target: "#projection_algorithm", default_value: "force"}        
    ];
    
    for(var i = 0; i < config.length; i++)
      config_options(config[i].button, config[i].source, config[i].target, config[i].default_value);
  }
);

function config_options(button, source, target, default_value)
{
  $(target).val(default_value);
  $(target).trigger("change");

  $(source).on("click", function(event)
  { 
    event.preventDefault();
    
    $(target).val($(this).attr("value"));
    $(target).trigger("change");
    
    $(button).html($(this).html() + "<span class='caret'></span>");
  });    
}

function load_csv(event)
{
  $("#text_path").val("www/data/text");
  $("#text_path").trigger("change");  
  process_file("csv", "Informe um arquivo CSV.", "shiny");
}

function load_group(event)
{
  process_file("json", "Informe um arquivo JSON com a estrutura dos Grupos.", "shiny");
}

function load_tree(event)
{
  process_file("json", "Informe um arquivo JSON com a estrutura da &Aacute;rvore", "d3.json");
}

function process_file(file_type, error_msg, handle)
{
  var file_name = $("#userFile").val() == "" ? FILE_NAME : $("#userFile").val();
  
  if(file_name.split(".").pop() == file_type)
  {
    $("#loading").modal("show");
    
    if(handle == "shiny")
    {
//    Força que a página envie algo para o Shiny mesmo se os demais parâmetros da tela não tenham sido modificados
//    Essa 'variável' precisa ser utilizada no servidor de alguma maneira
      $("#POG").val(Math.random());
      Shiny.onInputChange("POG", $("#POG").val());
      
      Shiny.addCustomMessageHandler("myCallBackHandler", function(message) 
      { 
        call_back(typeof(message) === "string" ? message : null, message); 
      });         
    }  
    else 
    {
      file_name = "data/json/" + file_name.split("C:\\fakepath\\").pop();
      d3.json(file_name, call_back);
    }  
  }
  else
    alert(error_msg);    
}

function call_back(error, data)
{
  try 
  {
    if(error)
      throw error;
    
    if(Array.isArray(data))
    {
      if( typeof(data[0]) == "string" )
        data = eval("(" + data[0] + ")");
      else
        data = data[0];
    }      
    
    if(data.seed_value > 0)
      $("#seed").val(data.seed_value);
    if(data.threshold !== undefined)
      $("#threshold").val(data.threshold);
    if(data.frac !== undefined)
      $("#frac").val(data.frac);
    if(data.max_iteration !== undefined)
      $("#max_iteration").val(data.max_iteration);
    if(data.qt_cluster !== undefined)
      $("#qt_cluster").val(data.qt_cluster);            
    if(data.order !== undefined)    
      $("#" + data.order).trigger("click");      
    if(data.cluster_algorithm !== undefined)    
      $("#" + data.cluster_algorithm).trigger("click");            
    if(data.projection_algorithm !== undefined)    
      $("#" + data.projection_algorithm).trigger("click");            
 
    VIS.load(data);
  }
  catch(err) 
  {
    alert(err);
  }
  finally 
  {
    $("#loading").modal("hide");
  }  
}

//==========================================================================================================================//

var Vis = function()
{
  var _this = this;

  this.view_data = new ViewData(); 
  this.sync      = new Sync(this);
  this.packed    = new PackedTree(this.view_data, this.sync);
  this.treemap   = new Tree_Map(this.view_data, this.sync);
  this.cloud     = new Word_Cloud();
  this.palette   = new ColorPalette();
  this.palette.create_options("#color_palette", "Color/Group");
  this.tree_height = 0;
  
  this.sync.packedtree = this.packed;
  this.sync.treemap    = this.treemap;
  this.sync.cloud      = this.cloud;        
  
  this.load = function(data)
  {
    Utils.palette = _this.palette;
    _this.view_data.colnames = data.colnames;
      
//cf. functioins.js
    _this.packed.load(data, config_svg("#chart_left"));
    _this.treemap.load(data, config_svg("#chart_treemap"));
    _this.cloud.load(data, config_svg("#chart_word_cloud"), config_svg("#chart_topic_cloud"));          
  };
  this.load_groups = function(tree)
  {
    _this.tree_height = tree[0].height;
    var groups = [];  
    
    $.each(tree, 
      function(i, obj)
      {
        if(typeof(obj.data.group) !== "undefined" && obj.data.group !== "" && groups.indexOf(obj.data.group) === -1)
          groups.push(obj.data.group);              
      }
    );
    
    _this.palette.load(groups);  
    
    $("#list_group").html("");
    
    for(var i = 0; i < groups.length; i++)
    {
      var li   = $("<li>");
      var link = $("<a>").html(groups[i])
                        .css("color", _this.palette.get_color(groups[i]))
                        .css("pointer-events", "none");
      $("#list_group").append(li.append(link));
    }
  };
  this.show_values = function(node)
  {
    if(node.data.isRoot)
    {
      $("#stress").html(node.data.stress);
      $("#n_preserv").html(node.data.np);
      $("#n_hit").html(node.data.nh);
      $("#silhouette").html(node.data.silhouette);    
    }
    
    $("#qt_inst").html(node.data.qt_instances);
    $("#qt_group").html(node.children.length);
    $("#qt_depth").html(node.depth);
    $("#qt_height").html(node.height);  
    
    if(node.children[0].data.isLeave)
      $("#qt_group").html("1");

    if(node.data.isRoot)
      $("#qt_min").html(node.data.qt_min);
    
    $("#show_values").attr("data-original-title", $("#my-tooltip").html());
  };
  this.fill_obj = function(obj, transparent, treemap)
  {
    if(obj.data.isLeave)
      return _this.palette.get_color(obj.data.group);
    else if(treemap != undefined && obj.children)
      return "rgba(255, 255, 255, 1)";
    else  
    {
      var group       = _this.get_max_hist_group(obj),
          color_scale = d3.scaleLinear().domain([0, _this.tree_height - 1]);
      
      if(transparent == undefined || !transparent)
      {  
        var alpha_range = color_scale.range([0.15, 0.80]),
            alpha       = Math.round(alpha_range(obj.depth) * 100) / 100;
            
        return _this.palette.get_color(group, alpha);    
      }
      else
      {
        var rgb_colors  = _this.palette.get_gradient(group, [0, 0, -40], 0.1),    
            color_range = color_scale.range([rgb_colors[0], rgb_colors[1]]);            
            
        return color_range(obj.depth);      
      }  
    }  
  };
  this.get_max_hist_group = function(data_obj)
  {
    var list_child = d3.hierarchy(data_obj.data).descendants().filter(function(d) { return d.data.isLeave; });
    var obj = new Object();    

    for(var i = 0; i < list_child.length; i++)
    {
      var c  = list_child[i].data.group;
      obj[c] = (obj[c] == undefined ? 0 : obj[c]) + 1;
    }

    var max_value = -1,
        max_group  = "";    

    for(var group in obj) 
    {
      if(obj[group] > max_value)
      {
        max_value = obj[group];
        max_group = group;
      }
    }  
    
    return max_group;
  }  
}

//==========================================================================================================================//

var Sync = function(v)
{
  var _this = this;
  
  this.vis        = v;
  this.packedtree = null;
  this.treemap    = null;
  this.cloud      = null;
  
  this.sincronize = function(obj, target, draw_cloud)
  {
    var list_target = svg = null,
        obj_source = obj;      

    if(target == "packedmap")  
    {  
      list_target = d3.selectAll("circle")._groups[0];
      svg =  d3.select("#chart_left").select("svg");
    }  
    else if(target == "treemap")
    {
      list_target = d3.selectAll("rect")._groups[0];   
      svg =  d3.select("#chart_treemap").select("svg");
    }  

    var obj_target = null;

    if(obj_source.data.isRoot)
    {
      obj_target = list_target[0].__data__;
      
      while(obj_target.parent)
        obj_target = obj_target.parent;
    }
    else
    {  
      var find_parent = !obj_source.data.isLeave,
          index = 0;
      
      while(!obj_source.data.isLeave)
        obj_source = obj_source.children[0];      
      
      for(var i = 0; i < list_target.length; i++)
      {
        obj_target = list_target[i].__data__;
        
        if(obj_source.data.name == obj_target.data.name)
        {
          obj_target = obj_target.parent;
          
          if(find_parent)
          {
            index = obj_source.depth - obj.depth - 1;
            
            while(index > 0 && obj_target.parent)
            {
              obj_target = obj_target.parent;
              --index;
            }  
          }
          
          break;
        }  
      }
    }

    if(target == "packedmap") 
      _this.packedtree.zoom(obj_target, svg, d3.event);
    else if(target == "treemap")  
      _this.treemap.zoom(obj_target, svg, d3.event);
    if(draw_cloud == undefined || !draw_cloud)
    {
      var aux1 = d3.select("#chart_word_cloud").select("svg");
      aux1.selectAll("*").remove();
      _this.cloud.load(obj, aux1);        
    }
  };
  this.hover_treemap = function(obj, hover)
  {
    var obj_source = obj;      
    
    if(!obj_source.data.isRoot)
    {    
      while(!obj_source.data.isLeave)
        obj_source = obj_source.children[0];      
      
      var obj_target = null,
          list_target = d3.selectAll("rect")._groups[0];  
          
      for(var i = 0; i < list_target.length; i++)    
      {
        obj_target = list_target[i].__data__;
        
        if(obj_source.data.name == obj_target.data.name)
          break;
      };
        
      _this.treemap.hovered(obj_target, hover, (obj.data.isLeave ? obj.depth - 1 : obj.depth));
    }
  };
  this.load_groups = function(tree)
  {
    _this.vis.load_groups(tree);
  };
  this.fill_obj = function(obj, transparent, treemap)
  {
    return _this.vis.fill_obj(obj, transparent, treemap);
  };
  this.show_values = function(node)
  {
    _this.vis.show_values(node);
  }
}

//==========================================================================================================================//

var Utils = 
{
  palette: null,
  extract_name: function(obj)
  {
    return {name: obj.data.name, color: this.palette.get_color(obj.data.group), data: obj.data.data};
  },
  extract_parent_children_name: function(obj)
  {
    var names = [];
    
    if(obj.parent)
    {
      for(var i = 0; i < obj.parent.children.length; i++)
        names.push({name: obj.parent.children[i].data.name, color: this.palette.get_color(obj.parent.children[i].data.group), data: obj.data.data});
    }
    
    return names;
  }  
}
//==========================================================================================================================//
