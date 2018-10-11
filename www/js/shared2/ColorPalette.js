//This classes needs: KolorWheel.js and Spectrum.js
//  http://linkbroker.hu/stuff/kolorwheel.js/
//  https://bgrins.github.io/spectrum/#methods-show
//
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

var ColorPalette = function()
{
  var _this = this;
  //From Nutrient Explorer http://bl.ocks.org/syntagmatic/raw/3150059/
  this.default_palette = ["#95326CFF","#BFBFBFFF","#94DAE1FF","#C29B93FF","#9367BCFF","#E2DD92FF","#FF7C0AFF","#E6B751FF",
                          "#F1F146FF","#FFBA75FF","#E274C1FF","#C4AFD4FF","#BA6940FF","#F7B6D2FF","#17BFCFFF","#8B564BFF",
                          "#C83266FF","#D3272AFF","#1F77B2FF","#FF9694FF","#9BD9E4FF","#95DE87FF","#ACC6E7FF","#E699B4FF",
                          "#2D9F2DFF"];
  this.default_color = 0;                          
  this.colors = {};
  this.selected_palette = "default";
  this.selected_start   = "#FF0000";
  this.selected_finish  = "#00FF00";
  
  //Add selection list of palettes into a 'wrapper'
  this.create_options = function(wrapper, title = "Colors", default_option = "default", default_start = "#FF0000", default_finish = "#00FF00")
  {
    $(wrapper).html("");
    _this.selected_palette = default_option;
    
    if(_this.selected_palette === "custom")
    {
      _this.selected_start  = default_start === "" ? _this.selected_start : default_start;
      _this.selected_finish = default_finish  === "" ? _this.selected_finish : default_finish;
    }    
    
    var ul  = $("<ul>").addClass("dropdown-menu");
    var options = [
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
    
    var selected_link = null;
    
    for(var i = 0; i < options.length; i++)
    {
      var link = $("<a>");
      ul.append($("<li>").append(
        link.addClass("palette_option")
                       .attr("value", options[i].value)
                       .attr("wrapper", wrapper)
                       .html(options[i].text))
      );
      
      if(options[i].value === default_option)
        selected_link = link;
    }
    
    var label  = $("<label>").text(title + ": ").css("padding-right", 5);
    var button = $("<button>").html("Default<span class='caret'></span>")
                              .addClass("btn btn-default dropdown-toggle")
                              .attr("id", "palette_button")
                              .attr("type", "button")
                              .attr("data-toggle", "dropdown");    
    $(wrapper).append(
      $("<div>").addClass("dropdown")
                .append(label)
                .append(button)
                .append(ul)
    );
    
    $(document).off("click", ".palette_option");
    $(document).on("click", ".palette_option", _this.onClick_option);    
    
    if(selected_link)
      selected_link.trigger("click");
  };
  
  //Load 'color_qt' or 'data.lenth' palette values and associate with each data value
  this.load = function(data, color_qt = 0)
  {
    var palette = _this.get_palette(color_qt > 0 ? color_qt : data.length);
    data.sort();
    
    for(var i = 0; i < data.length; i++)
      _this.colors[data[i]] = palette[i];      
  };  
  
  //Get the correct color value associated with 'id' and changed by 'alpha'
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
  this.onClick_option = function(event)
  {
    var wrapper = $($(this).attr("wrapper"));
    var parent  = wrapper.find(".dropdown");
    var last_colors = _this.get_limit_colors();
    
    wrapper.find("#palette_button").html($(this).html() + "<span class='caret'></span>");
    _this.selected_palette = $(this).attr("value");
    
    if (_this.selected_palette === "custom")
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

  this.get_palette = function(color_qt)
  {
    var colors = _this.get_limit_colors();
    
    if(_this.selected_palette === "default")
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
    switch(_this.selected_palette)
    {
      case "gray"   : return {start: "#F2F2F2FF", finish: "#000000FF"}; //(white-gray, black)
      case "igray"  : return {start: "#000000FF", finish: "#F2F2F2FF"}; //(black, white-gray)   
      case "heat1"  : return {start: "#FFFF00FF", finish: "#FF0000FF"}; //(yellow, red)
      case "iheat1" : return {start: "#FF0000FF", finish: "#FFFF00FF"}; //(red, yellow) 
      case "heat2" : return {start: "#FFFF00FF", finish: "#500000FF"};   //(yellow, brown)
      case "iheat2"  : return {start: "#500000FF", finish: "#FFFF00FF"}; //(brown, yellow)      
      case "terrain": return {start: "#F2F2F2FF", finish: "#00A600FF"};   //(gray, green)
      case "iterrain" : return {start: "#00A600FF" , finish: "#F2F2F2FF"}; //(green, gray)      
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