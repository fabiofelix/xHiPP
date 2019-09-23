//This classes needs: bootstrap, fancybox (cf. helpers for thumbs), wavesurfer, wavesurfer.cursor.js
//                    Forms form_text.html, form_audio.html, form_others into pages/
//
//Changed: 09/16/2019
//         Changed image thumbnail size
//Changed: 09/15/2019
//         Added audio equalization
//         Added image thumbnail
//         Changed directory structure, put css and js in the same directory of the html forms
//Changed: 09/11/2019
//         Tooltip adjusted to not get out the window
//Changed: 09/08/2019
//         Changed form_text width, close icon and text separation format
//         Removed show_tooltip d3 dependence
//Changed: 09/07/2019
//         Changed audio playing
//Changed: 10/04/2018
//         Bug fixed: use of html funciton insted of text in show_tooltip
//Changed: 07/17/2018
//         Added function show_tooltip
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
  this.text_form_path  = "js/shared/viewdata/form_text.html";
  this.audio_path = "data/audio/";
  this.audio_form_path = "js/shared/viewdata/form_audio.html";
  this.others_form_path  = "js/shared/viewdata/form_others.html";  
  this.showing_data = false;
  this.colnames = null;
  this.wavesurfer = null;
  
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
    
    $.fancybox.open(array_photo, {helpers: {thumbs: {width: 100, height: 70}}});
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

      _this.config_audio_player(obj.name);
      _this.config_audio_equalizer();
            
      if( $(window).width() > 1366 )
        $('#modal_form .modal-dialog').addClass("modal-lg");
      
      $('#modal_form').modal({backdrop: 'static', keyboard: false});  
    });
    
    $('#modal_form').on('hidden.bs.modal', function () { _this.wavesurfer.pause(); _this.wavesurfer.destroy(); });
  };
  
  this.config_audio_player = function(file_name)
  {
    _this.wavesurfer = WaveSurfer.create({
      container: '#audio_sound',
      waveColor: 'gray',
      progressColor: 'black',
      height: 50,
      opacity: 1,
      normalize: true,
      plugins: [
        WaveSurfer.cursor.create({
          showTime: true,
          opacity: 1,
          customShowTimeStyle: {
            'background-color': '#000',
            color: '#fff',
            padding: '2px',
            'font-size': '10px'
          }
        })
      ]
    });   
    $("#audio_back").on("click", _this.audio_control_click);
    $("#audio_play").on("click", _this.audio_control_click);
    $("#audio_for").on("click", _this.audio_control_click);
    
    _this.wavesurfer.load(_this.audio_path + file_name);
  //       _this.wavesurfer.load("data/audio/teste.wav");    
  };
  this.config_audio_equalizer = function()
  {
    $("#audio_equalizer").html("");
    
    _this.wavesurfer.on('ready', 
    function() 
    { 
      var EQ = [
//         {f:    16, type: 'lowshelf'},        
        {f:    32, type: 'lowshelf'},        
        {f:    63, type: 'peaking'},
        {f:   125, type: 'peaking'},        
        {f:   250, type: 'peaking'},
        {f:   500, type: 'peaking'},        
        {f:  1000, type: 'peaking'},
        {f:  2000, type: 'peaking'},        
        {f:  4000, type: 'peaking' },
        {f:  8000, type: 'peaking' },        
        {f: 16000, type: 'highshelf'}
      ];        
      
      var filters = EQ.map(function(band) 
      {
        var filter = _this.wavesurfer.backend.ac.createBiquadFilter();
        filter.type = band.type;
        filter.gain.value = 0;
        filter.Q.value = 1;
        filter.frequency.value = band.f;
        return filter;
      });  
      
      _this.wavesurfer.backend.setFilters(filters);

      filters.forEach(function(filter) 
      {
        var onChange = function(e) 
        { 
          filter.gain.value = ~~e.target.value; 
          e.target.title = e.target.value;
        };
        var label = filter.frequency.value >= 1000 ? filter.frequency.value / 1000 : filter.frequency.value;
        label = label + (filter.frequency.value >= 1000 ? "kHz" : "Hz");
        
        var div = $("<div>").append(
          $("<input>")
            .addClass("eq-slider")
            .attr("type", "range")
            .attr("min", -80)
            .attr("max", 80)
            .attr("value", 0)
            .attr("title", 0)
            .attr("orient", "vertical")
            .on("input", onChange)
            .on("change", onChange)
          )
          .append( $("<span>").text(label).addClass("eq-label") )
          .addClass("col-lg-2");
        
        $("#audio_equalizer").append(div);

      });        
    });
  };
  this.audio_control_click = function(event)
  {
    if($(this).attr("id") == "audio_back")
      _this.wavesurfer.skipBackward();
    else if($(this).attr("id") == "audio_play")
      _this.wavesurfer.playPause();
    else
      _this.wavesurfer.skipForward();
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
  this.show_image_tooltip = function(show, names, wrapper, force)
  {
    var wrapper_aux = wrapper == undefined ? "#image_tooltip" : wrapper;
    
    if(show && (names.name !== "" || names.alternative !== "") && 
       (_this.isImage(names.name) || _this.isAudio(names.name) || force ))
    {
      var name = names.name,
          search_aux_path  = !_this.isMediaData(names.name) && names.alternative != undefined && names.alternative !== "";
      
      if(search_aux_path)
        name = names.alternative;
       
      _this.show_tooltip(true, wrapper_aux, {X: d3.event.pageX, Y: d3.event.pageY}, "img", _this.get_path(name, search_aux_path));
    }
    else
      _this.show_tooltip(false, wrapper_aux);
  };
  this.show_tooltip = function(show, wrapper, position, type, value)
  {
    if(show)
    {
      var x_offset = y_offset = 10,
          x = position.X + x_offset,
          y = position.Y + y_offset;          
          
     if(x + x_offset + $(wrapper).width() >= $(window).width())
       x = position.X - 3 * x_offset - $(wrapper).width();
     if(y + $(wrapper).height() >= $(window).height())
       y = position.Y - y_offset - $(wrapper).height();
     else if(y + $(wrapper).height() < 0)
       y = position.Y;
      
      $(wrapper)
        .css("left", x + "px")
        .css("top", y + "px");                   
        
      if(type == "img")
        $(wrapper + " #thumb").attr("src", value);        
      else if(type == "text")    
        $(wrapper + " #value").html(value);
    }
    
    if(show)
      $(wrapper).removeClass("hidden")
    else  
      $(wrapper).addClass("hidden")
  };  
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
