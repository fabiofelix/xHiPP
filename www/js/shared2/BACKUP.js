//This classes needs: bootstrap, fancybox
//                    Forms form_text.html, form_audio.html, form_others into pages/
//
//Changed: 05/10/2018
//         Changed function show_image_tooltip to access aux data directory
//         Changed get_path to access aux data directory
//         Changed isDataView to isMedidaData
//Changed: 04/6/2018
//         Added function show_others
//Changed: 04/05/2018
//         Added function show_image_tooltip
//Changed: 03/04/2018
//         Added function get_path
//Changed: 03/02/2018
//         Added function extractImageAudio
//Changed: 11/08/2017
//         Added default value to list_obj int show method
//
//Created: 11/07/2017

var ViewData = function()
{
  var _this = this;
  this.image_path = "data/img/";
  this.text_path  = "data/text/";
  this.aux_path   = "data/aux2/";
  this.text_form_path  = "pages/form_text.html";
  this.audio_path = "data/audio/";
  this.audio_form_path = "pages/form_audio.html";
  this.others_form_path  = "pages/form_others.html";  
  this.showing_data = false;
  this.colnames = null;
  
  this.show = function (obj, list_obj = [])
  {
    _this.showing_data = _this.isImage(obj.name) || _this.isText(obj.name) || _this.isAudio(obj.name) || obj.data !== undefined;
    
    if(_this.isImage(obj.name))
      _this.show_image(obj, list_obj);
    else if(_this.isText(obj.name))
      _this.show_text(obj);
    else if(_this.isAudio(obj.name))
      _this.show_audio(obj);
    else if(obj.data)
      _this.show_others(obj);
  };
  
  this.reset_show = function()
  {
    _this.showing_data = false;
  };
  
//obj = {name: '', color: '', data: []}  
//list_obj = [{name: '', color: ''}, {name: '', color: '', data: []} ... ]  
  this.show_image = function (obj, list_obj)
  {
    var array_photo = [{href: _this.image_path + obj.name, title: obj.name,  color: obj.color,
      beforeShow: function(){ $(".fancybox-skin").css("background-color", this.color); }
    }];
    
    for(var i = 0; i < list_obj.length; i++)
    {
      if(list_obj[i].name !== obj.name)
      {
        array_photo.push({href: _this.image_path + list_obj[i].name, title: list_obj[i].name, color: list_obj[i].color,
          beforeShow: function() {  $(".fancybox-skin").css("background-color", this.color); } 
        });
      }  
    }
    
    $.fancybox.open(array_photo);
  };
  
//obj = {name: '', color: '', data: []}  
  this.show_text = function (obj)
  {
    $("#modal_form").load(_this.text_form_path, function()
    {
      $("#div_text_content").load(_this.text_path + obj.name);
      $("#div_text_title").text(obj.name);    
    });
    $("#modal_form").modal({backdrop: 'static', keyboard: false});    
    
  //   $("#div_text").modal("show");
  };
  
//obj = {name: '', color: '', data: []}  
  this.show_audio = function (obj)
  {
    $('#modal_form').load(_this.audio_form_path, function(text, status, xhr)
    {
      $("#div_audio_title").text(obj.name); 
      $("#audio_spec").attr("src", _this.audio_path + _this.extractImageAudio(obj.name));      
      $("#audio_sound").attr("src", _this.audio_path + obj.name);
      $("#audio_sound").attr("type", "audio/" + _this.get_ext(obj.name));
      
      $('#modal_form').modal({backdrop: 'static', keyboard: false});  
    });
    
    $('#modal_form').on('hidden.bs.modal', function () 
    { 
      if($("#audio_sound").length > 0)
        $("#audio_sound")[0].pause(); 
    });
  };

//obj = {name: '', color: '', data: []}  
  this.show_others = function(obj)
  {
    $("#modal_form").load(_this.others_form_path, function()
    {
//TODO: Melhorar formatação dessa apresentação.
      for(var i = 0; i < obj.data.length; i++)
      {
        var title = "";
        
        if(_this.colnames && i < _this.colnames.length)
          title = "<i><b>" + _this.colnames[i] + "</b></i>: ";
        
        $(".modal-body").append("<span>" + title + obj.data[i] + "</span><br />");
      }
      
      $("#div_text_title").text(obj.name);    
    });
    $("#modal_form").modal({backdrop: 'static', keyboard: false});      
  };
  this.show_image_tooltip = function(show, names, wrapper)
  {
    var wrapper_aux = wrapper == undefined ? "#image_tooltip" : wrapper;
    
    if(show && (names.name !== "" || names.alternative !== "") && 
       (_this.isImage(names.name) || _this.isAudio(names.name) || !_this.isMediaData(names.name)))
    {
      var name = names.name,
          search_aux_path  = !_this.isMediaData(names.name) && names.alternative != undefined && names.alternative !== "";
      
      if(search_aux_path)
        name = names.alternative;
       
      d3.select(wrapper_aux)
        .classed("hidden", false)
        .style("left", (d3.event.pageX + 10) + "px")
        .style("top", (d3.event.pageY - 10) + "px")
        .select("#thumb")
        .attr("src", _this.get_path(name, search_aux_path));
    }
    else
      d3.select(wrapper_aux).classed("hidden", true);  
  }  
  this.isMediaData = function(file_name)
  {
    return _this.isImage(file_name) || _this.isText(file_name) || _this.isAudio(file_name);
  };
  this.isImage = function (file_name)
  {
    return file_name.search(".png") != -1 || file_name.search(".jpg") != -1 || file_name.search(".jpeg") != -1;
  };
  this.isText = function (file_name)
  {
    return file_name.search(".txt") != -1; 
  };
  this.isAudio = function (file_name)
  {
    return file_name.search(".mp3") != -1 || file_name.search(".wav") != -1 || file_name.search(".flac") != -1; 
  };  
  this.extractImageAudio = function(audio_name, type = ".png")
  {
    var index = audio_name.lastIndexOf(".");
    var name  = audio_name.substring(0, index);
    return name + type;
  };  
  this.get_path = function(path, search_aux_path)
  {
    if(search_aux_path)
      return _this.aux_path + path;      
    else if(_this.isImage(path))
      return _this.image_path + path;      
    else if(_this.isText(path))
      return _this.text_path + path;      
    else if(_this.isAudio(path))
      return _this.audio_path + _this.extractImageAudio(path);
    else
      return "";
  };
  this.get_ext = function(file)
  {
    return file.split(".").pop();
  }
}
