//config_svg

//Changed: 10/06/2018
//         Added functions read_data and download_data
//Changed: 03/02/2017
//         Changed config_svg to compability with Hipp

function clear_page(id)
{
  if(id == undefined)
    $("#page-wrapper").html("");
  else
    $(id).html("");
}

function disable_form(disable, just_button)
{
  if(disable)
    $("form button[type='submit']").button("loading");
  else  
    $("form button[type='submit']").button("reset");
  
  $("form button").prop("disabled", disable);  
  
//Os campos desabilitados não são enviados para o servidor quando o action do form é utilizado.  
  if(!just_button)
  {
    $("form input").prop("disabled", disable);
    $("form select").prop("disabled", disable);
  }
}

function show_error(msg)
{
  alert(msg.responseText);
}

// function get_link_img(data)
// {
//   for(var i = 0; i < data.length; i++)
//   {
//     if(data[i] != "" && (data[i].search(".png") != -1 || data[i].search(".jpg") != -1 || data[i].search(".jpeg") != -1))
//       return data[i];
//   }  
// }
// 
// function get_audio_img(data)
// {
//   for(var i = 0; i < data.length; i++)
//   {
//     if(data[i] != "" && (data[i].search(".wav") != -1 || data[i].search(".mp3") != -1 || data[i].search(".flac") != -1))
//       return data[i];
//   }  
//   
//   return "";
// }

// Sempre possuir a tag dentro da pagina <div id="modal_form" class="modal fade" aria-hidden="true"></div>
function show_modal(page, show, callback)
{
  if(show)
  {
    $("#modal_form").load(page, callback);
    $("#modal_form").modal({backdrop: "static", keyboard: false});       
  }
  else
    $("#modal_form").modal("hide");  
}

function array_has_string(array, string)
{
  for(var i = 0; i < array.length; i++)
  {
    if(array[i].indexOf(string) > -1)
      return i;
  }
  
return -1;    
}

function config_svg(wrapper, height, margin)
{
  var svg = d3.select(wrapper).select("svg");
  
  if(svg.empty())
    svg = d3.select(wrapper).append("svg");
  else
    svg.selectAll("*").remove();        
  
  svg = svg.attr("width", $(wrapper).innerWidth() - parseInt($(wrapper).css("padding-left")) - parseInt($(wrapper).css("padding-right")));
  
  if(height !== undefined)     
    svg.attr("height", height);  
  else if(height !== undefined && margin !== undefined)
    svg.attr("height", height + margin.top + margin.bottom)
       .append("g").attr("transform", "translate(" + margin.left + "," + margin.top + ")");
  else
    svg.attr("height", $(wrapper).innerHeight()  - parseInt($(wrapper).css("padding-top")) - parseInt($(wrapper).css("padding-bottom")))
 
  return svg;  
};

function parse_time(date)
{
//mm/dd/yyyy HH:MM:ss  
  var tokens = date.split(" "),
      date   = tokens[0].split('/'),
      time   = tokens[1].split(':');

//ano, mês, dia, hora, minuto, segundo, milissegundo
  return new Date(+date[2], +date[0] - 1, +date[1], +time[0], +time[1], +time[2]);  
}

function download_data(data, file_name, name_label)
{
  var csvContent = 
    (typeof(name_label) === "undefined" ? "" : "name,") + 
    "X,Y" +
    (typeof(name_label) === "undefined" ? "" : ",group") + 
    "\r\n";
  
  data.forEach(function(row, i)
  {
    csvContent += 
      (typeof(name_label) === "undefined" ? "" : name_label[i].name + ",") +
      row.join(",") + 
      (typeof(name_label) === "undefined" ? "" : "," + name_label[i].group) +
      "\r\n";
  }); 
  
  var blob = new Blob([csvContent]);
  
  // IE hack; see http://msdn.microsoft.com/en-us/library/ie/hh779016.aspx
  if (window.navigator.msSaveOrOpenBlob)  
    window.navigator.msSaveBlob(blob, file_name);
  else
  {
    var link = $("<a>", 
                 {
                   id: "download_file",
                   href: window.URL.createObjectURL(blob, {type: "text/plain"}),
                   download: file_name,
                   hidden: true
                });
    
    $("body").append(link);
    link[0].click(); 
    link.remove();
  }  
}

function read_data(stream, callback)
{
  var reader = new FileReader();

  reader.onload = function(reader_event)
  { 
    callback(reader_event.target.result);
  };
  
  reader.readAsText(stream);
}
