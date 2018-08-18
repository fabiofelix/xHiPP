$(document).ready(
  function()
  {
    bind_component();
    trigger_shiny_event(false);
  }
);

//TODO: MELHORAR ESSA FUNÇÃO PARA VÁRIOS COMPONENTES
//O Shiny faz bind para cada um dos componentes que estiverem na tela
function trigger_shiny_event(changing)
{
//   Desativar o evento uploadFiles inicializado pelo Shiny e associado ao input file
  var s1  = Shiny.inputBindings.bindingNames["shiny.fileInputBinding"].binding,
      s2  = Shiny.inputBindings.bindingNames["shiny.textInput"].binding,
      s3  = Shiny.inputBindings.bindingNames["shiny.selectInput"].binding,
      s4  = Shiny.inputBindings.bindingNames["shiny.checkboxInput"].binding;
  var input_file = $("input[type='file']"),
      input_text = $('input[type="text"], input[type="search"], input[type="url"], input[type="email"]'),
      select     = $("select"),
      checkbox   = $('input[type="checkbox"]');  
      
  if(changing)
  {
    for(var i = 0; i < checkbox.length; i++)
    {
      s4.subscribe(checkbox[i]);    
      $(checkbox[i]).trigger('change');
    }  
    for(var i = 0; i < select.length; i++)
    {
      s3.subscribe(select[i]);    
      $(select[i]).trigger('change');
    }  
    for(var i = 0; i < input_text.length; i++)
    {
      s2.subscribe(input_text[i]);    
      $(input_text[i]).trigger('change');
    }    
    for(var i = 0; i < input_file.length; i++)
    {
      s1.subscribe(input_file[i]);    
      $(input_file[i]).trigger('change');
    }
  }
  
  for(var i = 0; i < checkbox.length; i++)
    s4.unsubscribe(checkbox[i]);   
  for(var i = 0; i < select.length; i++)
    s3.unsubscribe(select[i]);   
  for(var i = 0; i < input_text.length; i++)
    s2.unsubscribe(input_text[i]);  
  for(var i = 0; i < input_file.length; i++)
    s1.unsubscribe(input_file[i]);
}    

function bind_component()
{
  var input_binding = new Shiny.InputBinding();
  $.extend(input_binding, {
    find: function find(scope) {
      return $(scope).find('input[type="file"]');
    },
    getValue: function getValue(el) {
      return null;
    },
    subscribe: function subscribe(el, callback) {
      
    },
    unsubscribe: function unsubscribe(el) {
      $(el).off('.fileInputBinding');
    }
  });    
  Shiny.inputBindings.register(input_binding, "my_shiny.fileInputBinding");
  
  var textInputBinding = new Shiny.InputBinding();
  $.extend(textInputBinding, {
    find: function find(scope) {
      return $(scope).find('input[type="text"], input[type="search"], input[type="url"], input[type="email"]');
    },
    getValue: function getValue(el) {
      return null;
    },
    subscribe: function subscribe(el, callback) {

    },
    unsubscribe: function unsubscribe(el) {
      $(el).off('.textInputBinding');
    }
  });
  Shiny.inputBindings.register(textInputBinding, 'my_shiny.textInput');  
  
  var selectInputBinding = new Shiny.InputBinding();
  $.extend(selectInputBinding, {
    find: function find(scope) {
      return $(scope).find('select');
    },
    getValue: function getValue(el) {
      return null;
    },
    subscribe: function subscribe(el, callback) {

    },
    unsubscribe: function unsubscribe(el) {
      $(el).off('.selectInputBinding');
    }
  });
  Shiny.inputBindings.register(selectInputBinding, 'my_shiny.selectInput');  
  
  var checkboxInputBinding = new Shiny.InputBinding();
  $.extend(checkboxInputBinding, {
    find: function find(scope) {
      return $(scope).find('input[type="checkbox"]');
    },
    getValue: function getValue(el) {
      return null;
    },
    subscribe: function subscribe(el, callback) {

    },
    unsubscribe: function unsubscribe(el) {
      $(el).off('.checkboxInputBinding');
    }
  });
  Shiny.inputBindings.register(checkboxInputBinding, 'my_shiny.checkboxInput');  
}
