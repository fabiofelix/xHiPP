//This classes needs: KolorWheel.js and Spectrum.js
//  http://linkbroker.hu/stuff/kolorwheel.js/
//  https://bgrins.github.io/spectrum/#methods-show
//
//Changed: 12/19/2020
//         Removed alfa hexa values from default_palette
//Changed: 06/04/2020
//         Fixed, load funciton was changing data parameter
//Changed: 02/20/2020
//         Added inheritance class structure
//Changed: 12/27/2017
//         It wasn't removing Inverse button when changing from Custom mode 
//Changed: 11/15/2017
//         Changed default_color value (it was incorrect)
//         Changed get_color to return alpha in default value
//Changed: 11/13/2017
//         Change name from this.get_gradient_hsl to this.get_gradient
//Changed: 11/10/2017
//         updated options layout
//Changed: 11/06/2017
//         create_options didn't change selected_palette
//         added inverse options
//         added inverse button
//         removed reverse from seq_color
//Created: 11/02/2017

var HandleOption = function()
{
  var _this = this; //sempre adicionar
  this.selected_option = ""; 

  //Adicionadas no prototype
  // this.create_options = function(wrapper, title = "", default_option = "default", label_top = false) {}
  // this.select_default = function(value) {}

  //Utilizado para opcoes estaticas no htmtl
  this.config_options = function(button, source, target, default_value)
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

    $(source).each(function()
    {
      if($(this).attr("value") == default_value)
      {
        $(this).trigger("click");
        return false;
      }  
    });
  };
  this.clear = function(wrapper)
  {
    $(wrapper).html("");
  };
  this.compose = function(wrapper, title, default_option, label_top)
  {
    var ul_link = _this.generate_options(wrapper, default_option);
    var lb_bt = _this.generate_button(title);
    var div   = $("<div>").addClass("dropdown");
    
    if(label_top)
      $(wrapper).append(lb_bt[0]);
    else
      div.append(lb_bt[0]);
    
    div.append(lb_bt[1]).append(ul_link[0]);
    $(wrapper).append(div);

    return ul_link[1];
  };
  this.bind = function(selected_link)
  {
    $(document).off("click", '.' + _this.get_class());
    $(document).on("click", '.' + _this.get_class(), _this.onClick_option);    
    
    if(selected_link)
      selected_link.trigger("click");
  };
  this.generate_options = function(wrapper, default_option)
  {
    var ul  = $("<ul>").addClass("dropdown-menu");
    var selected_link = null;
    var options = _this.get_options();

    for(var i = 0; i < options.length; i++)
    {
      var link = $("<a>");
      ul.append($("<li>").append(
        link.addClass(_this.get_class())
                       .attr("value", options[i].value)
                       .attr("wrapper", wrapper)
                       .html(options[i].text))
      );
      
      if(options[i].value === default_option)
        selected_link = link;
    }  
    
    return [ul, selected_link];
  };
  this.generate_button = function(title)
  {
    var label  = $("<label>").text(title + (title == "" ? "" : ": ")).css("padding-right", 5);

    var options = _this.get_options();
    var default_option = "";

    for(var i = 0; i < options.length; i++)
    {
      if(options[i].value == _this.selected_option)
        default_option = options[i].text;
    }  

    var button = $("<button>").html(default_option + "span class='caret'></span>")
                              .addClass("btn btn-default dropdown-toggle")
                              .attr("id", _this.get_id())
                              .attr("type", "button")
                              .attr("data-toggle", "dropdown");  
                              
    return [label, button];
  };
  this.onClick_option = function(event)
  {
    event.preventDefault();

    var wrapper = $($(this).attr("wrapper"));
    var parent  = wrapper.find(".dropdown");

    wrapper.find('#' + _this.get_id()).html($(this).html() + "<span class='caret'></span>");
    _this.selected_option = $(this).attr("value");

    _this.do_option_click(event, parent);
  };
  //Reimplementar nos filhos
  this.get_options = function()
  {
    return [];
  };  
  this.get_class = function()
  {
    return "";
  };
  this.get_id = function()
  {
    return "";
  };  
  this.do_option_click = function(event, parent) 
  {

  };
}

HandleOption.prototype.create_options = function(wrapper, title = "", default_option = "default", label_top = false)
{
  this.clear(wrapper);
  this.select_default(default_option);
  var sl = this.compose(wrapper, title, default_option, label_top);
  this.bind(sl);
};

HandleOption.prototype.select_default = function(value)
{
  this.selected_option = value
};

var ColorPalette = function()
{
  HandleOption.call(this);
  var _this = this;

  //From Nutrient Explorer http://bl.ocks.org/syntagmatic/raw/3150059/
  this.default_palette = ["#95326C","#BFBFBF","#94DAE1","#C29B93","#9367BC","#E2DD92","#FF7C0A","#E6B751",
                          "#F1F146","#FFBA75","#E274C1","#C4AFD4","#BA6940","#F7B6D2","#17BFCF","#8B564B",
                          "#C83266","#D3272A","#1F77B2","#FF9694","#9BD9E4","#95DE87","#ACC6E7","#E699B4",
                          "#2D9F2D"];
  this.default_color = 0;                          
  this.colors = {};
  this.selected_start   = "#FF0000";
  this.selected_finish  = "#00FF00";
  this.default_start = "";
  this.default_finish = "";

  this.create_options = function(wrapper, title = "Colors", default_option = "default", default_start = "#FF0000", default_finish = "#00FF00", label_top = false)
  {
    _this.default_start = default_start;
    _this.default_finish = default_finish;
    HandleOption.prototype.create_options.call(this, wrapper, title, default_option, label_top)
  };
  this.select_default = function(value)
  {
    HandleOption.prototype.select_default.call(this, value);

    if(_this.selected_option === "custom")
    {
      _this.selected_start  = _this.default_start === "" ? _this.selected_start : _this.default_start;
      _this.selected_finish = _this.default_finish  === "" ? _this.selected_finish : _this.default_finish;
    }    
  };
  this.get_options = function()
  {
    return [
      {value: "default", text: "Default"},
      {value: "gray", text: "Gray"},
      {value: "igray", text: "Inverse Gray"},
      {value: "heat1", text: "Heat 1"},
      {value: "iheat1", text: "Inverse Heat 1"},
      {value: "heat2", text: "Heat 2"},
      {value: "iheat2", text: "Inverse Heat 2"},
      {value: "terrain", text: "Terrain"},
      {value: "iterrain", text: "Inverse Terrain"},
      {value: "custom", text: "Custom"}            
    ];
  }; 
  this.get_class = function()
  {
    return "palette_option";
  };
  this.get_id = function()
  {
    return "palette_button";
  };   
  this.do_option_click = function(event, parent)
  {
    if (_this.selected_option === "custom")
    {
      if($("#custom_start").length == 0)
      {
        var custom1 = $("<input>").attr("type", "text").attr("id", "custom_start");
        var custom2 = $("<input>").attr("type", "text").attr("id", "custom_finish");
        var button  = $("<button id='inverse_color_palette' type='button' class='btn btn-info teste_spectrum' >Inverse</button>")
                       .css("margin-left", 10);
        
        $(parent).append(custom1);
        $(parent).append(custom2);
        $(parent).append(button);
        
        custom1.spectrum({color: _this.selected_start, change: _this.onChange_start, showInput: true, preferredFormat: "hex"});
        custom2.spectrum({color: _this.selected_finish, change: _this.onChange_finish, showInput: true, preferredFormat: "hex"});
        
        $(".sp-replacer").css("margin-left", "10px");
        
        $(document).off("click", "#inverse_color_palette");        
        $(document).on("click", "#inverse_color_palette", _this.onClick_Inservecolor);        
      }
      else
      {
        $(".sp-replacer").css("display", "inline-block");
        $("#inverse_color_palette").css("display", "inline-block");       
      } 
      
//       $("#custom_start").spectrum("set", last_colors.start.slice(0, 7));
//       $("#custom_finish").spectrum("set", last_colors.finish.slice(0, 7));      
    }
    else if($("#custom_start").length > 0)
    {
      $(".sp-replacer").css("display", "none");       
      $("#inverse_color_palette").css("display", "none");       
    }       
  };
  this.onChange_start = function(color)
  {
    _this.selected_start = color.toHexString().toUpperCase();
  };
  this.onChange_finish = function(color)
  {
    _this.selected_finish = color.toHexString().toUpperCase();
  };
  this.onClick_Inservecolor = function(event)  
  {
    event.preventDefault();
    var start  = $("#custom_start").spectrum("get"),
        finish = $("#custom_finish").spectrum("get");
    
    _this.selected_start  = finish.toHexString().toUpperCase();
    _this.selected_finish = start.toHexString().toUpperCase();
        
    $("#custom_start").spectrum("set", finish);
    $("#custom_finish").spectrum("set", start);
  };
  //Load 'color_qt' or 'data.lenth' palette values and associate with each data value
  this.load = function(data, color_qt = 0)
  {
    var new_data = data.slice();
    var palette = _this.get_palette(color_qt > 0 ? color_qt : new_data.length);
    new_data.sort();
    
    for(var i = 0; i < new_data.length; i++)
      _this.colors[new_data[i]] = palette[i];
  };    //Get the correct color value associated with 'id' and changed by 'alpha'
  this.get_color = function(id, alpha = undefined)
  {
    var color = _this.colors[id];
    
    if(typeof(color) === "undefined")
      return _this.get_default().slice(0, 7) + _this.alpha2hex(  alpha === undefined ? 1 : alpha  );
    else if(alpha !== undefined)
      return color.slice(0, 7) + _this.alpha2hex(alpha);
    else  
      return color;
  };
  this.get_default = function()
  {
    return _this.default_palette[_this.default_color];
  };    
  this.get_palette = function(color_qt)
  {
    var colors = _this.get_limit_colors();
    
    if(_this.selected_option === "default")
      return _this.default_palette.slice(0, color_qt);
    else if(colors.start != "" && colors.finish != "" && color_qt > 0)
      return _this.seq_color(colors.start, colors.finish, color_qt);
    else 
      return _this.default_palette.slice(0, color_qt);
  };
  this.seq_color = function (from, to, qt)
  {
    var base   = new KolorWheel(from);
    var target = base.abs(to, qt < 2 ? 2 : qt);
    var values = [];

    for (var n = 0; n < qt; n++) 
      values.push(target.get(n).getHex());

//     values.reverse();  
    return values;  
  };  
  this.get_limit_colors = function()
  {
    switch(_this.selected_option)
    {
      case "gray"   : return {start: "#F2F2F2", finish: "#333333"}; //(white-gray, black)
      case "igray"  : return {start: "#333333", finish: "#F2F2F2"}; //(black, white-gray)   
      case "heat1"  : return {start: "#E6E31A", finish: "#E61919"}; //(yellow, red)
      case "iheat1" : return {start: "#E61919", finish: "#E6E31A"}; //(red, yellow) 
      case "heat2" : return {start: "#F8F208", finish: "#500000"};   //(yellow, brown)
      case "iheat2"  : return {start: "#500000", finish: "#E6E31A"}; //(brown, yellow)      
      case "terrain": return {start: "#F2F2F2", finish: "#109610"};   //(gray, green)
      case "iterrain" : return {start: "#109610" , finish: "#F2F2F2"}; //(green, gray)      
      case "custom"   :  return {start: _this.selected_start, finish: _this.selected_finish};
      default: return {start: "", finish: ""};  
    }
  };
  this.alpha2hex = function(alpha)
  {
    return ("0" + Math.round(alpha * 255).toString(16)).toUpperCase().slice(-2);
  };
  this.get_gradient = function(id, vec_hsl, alpha, return_type = "hsla")
  {
    var start = new KolorWheel(_this.get_color(id));
    var vec   = start.getHsl();
    vec[0]    = Math.round(vec[0] + vec_hsl[0]);
    vec[1]    = Math.round(vec[1] + vec_hsl[1]);
    vec[2]    = Math.round(vec[2] + vec_hsl[2]);
    var finish  = new KolorWheel(vec);
    
    if(return_type === "hex")
      return [start.getHex() + _this.alpha2hex(alpha), finish.getHex() + _this.alpha2hex(alpha)];
    else if(return_type === "rgba")
      return ["rgba(" + Math.round(start.getRgb()[0]) + ", " +
                        Math.round(start.getRgb()[1]) + ", " +
                        Math.round(start.getRgb()[2]) + ", " +
                        alpha + ")",
              "rgba(" + Math.round(finish.getRgb()[0]) + ", " +
                        Math.round(finish.getRgb()[1]) + ", " +
                        Math.round(finish.getRgb()[2]) + ", " +
                        alpha + ")"];
    else
      return ["hsla(" + Math.round(start.getHsl()[0]) + ", " +
                        Math.round(start.getHsl()[1]) + "%, " +
                        Math.round(start.getHsl()[2]) + "%, " +
                        alpha + ")",
              "hsla(" + Math.round(finish.getHsl()[0]) + ", " +
                        Math.round(finish.getHsl()[1]) + "%, " +
                        Math.round(finish.getHsl()[2]) + "%, " +
                        alpha + ")"];
  }    
}

// ColorPalette.prototype = Object.create(HandleOption);
