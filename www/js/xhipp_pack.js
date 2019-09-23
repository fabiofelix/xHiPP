
var xHiPP_pack = function()
{
  this.pack = function(tree, summary, Xf, Yf)
  {
    tree.r = 10;
    tree.x = (tree.data.x - summary.min_x) * (Xf / ( summary.max_x - summary.min_x));
    //Além de colocar a coordenada y entre 0 e Yf, também inverte os valores por causa da localização do ponto (0, 0) na tela
    tree.y = Yf + (tree.data.y - summary.min_y) * ( -Yf / ( summary.max_y - summary.min_y ) );
    
    if(tree.children)
    {
      for(var i = 0; i < tree.children.length; i++)
        tree.children[i] = this.pack(tree.children[i], summary, Xf, Yf);
      
      tree = this.spreader(tree);
      
      var enc = d3.packEnclose(tree.children);
      tree.x  = enc.x;
      tree.y  = enc.y;
      tree.r  = enc.r;
    }
    
    return tree;
  }; 
  this.spreader = function(tree)
  {
    var iteration = 1;
    
    var max       = parseInt($("#max_iteration").val());
    var threshold = parseFloat($("#threshold").val());
    var frac      = parseFloat($("#frac").val());  
  //   var max       = 20;
  //   var threshold = 1.5;   //se os nós não possuirem interseção mas estiverem muito próximos faz com que sejam minimamente afastados
  //   var frac      = 4.0;   //4 <= frac <= 8. Quanto menor mais espelhados os pontos ficam
    
    do
    {
      var changed  = false;
      var last_changed = changed;
      
      for(var i = 0; i < tree.children.length; i++)
      {
        var Ci = tree.children[i];
        
        for(var j = 0; j < tree.children.length; j++)
        {
          if(i !== j)
          {
            var Cj = tree.children[j],
                d  = this.dist(Ci, Cj),
                s  = Ci.r + Cj.r;
            
  //           if(!intersection(Ci.x, Ci.y, Ci.r, Cj.x, Cj.y, Cj.r))
            if(s < d)
              s += threshold;
            
            if(s > d)
            {
              var delta = (s - d) / frac,
                  vec   = [Cj.x - Ci.x, Cj.y - Ci.y];
                  
              if(vec[0] == 0 && vec[1] == 0)
                vec = [delta, delta];
              
              var vec_norm = Math.sqrt(Math.pow(vec[0], 2) + Math.pow(vec[1], 2)),
                  vec2 = [vec[0] / vec_norm, vec[1] / vec_norm];
              
              Ci = this.move_node(Ci, -(vec2[0] * 3 * delta / 4), -(vec2[1] * 3 * delta / 4));
              Cj = this.move_node(Cj, (vec2[0] * delta / 4), (vec2[1] * delta / 4));            
              
              changed = true;
            }
          }
        }
      }
      
      iteration++;
    }while(last_changed != changed && iteration <= max);
  
    return tree;
  };
  this.move_node = function(node, delta_x, delta_y)
  {
    node.x = node.x + delta_x;
    node.y = node.y + delta_y;
    
    if(node.children)
    {
      for(var i = 0; i < node.children.length; i++)
        node.children[i] = this.move_node(node.children[i], delta_x, delta_y);
    }
    
    return node;
  };
  this.dist = function(p1, p2)
  {
    return Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));
  }  
}

function _pack(tree, original_limites, Xf, Yf)
{
  tree.r = 10;
  tree.x = (tree.data.x - original_limites.min_x) * (Xf / ( original_limites.max_x - original_limites.min_x));
  //Além de colocar a coordenada y entre 0 e Yf, também inverte os valores por causa da localização do ponto (0, 0) na tela
  tree.y = Yf + (tree.data.y - original_limites.min_y) * ( -Yf / ( original_limites.max_y - original_limites.min_y ) );
  
  if(tree.children)
  {
    for(var i = 0; i < tree.children.length; i++)
      tree.children[i] = _pack(tree.children[i], original_limites, Xf, Yf);
    
    if( $("#speader").is(":checked"))
      tree = spreader(tree);
    
    var enc = d3.packEnclose(tree.children);
    tree.x  = enc.x;
    tree.y  = enc.y;
    tree.r  = enc.r;
  }
  
  return tree;
}

function dist(p1, p2)
{
  return Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));
}

function move_node(node, delta_x, delta_y)
{
  node.x = node.x + delta_x;
  node.y = node.y + delta_y;
  
  if(node.children)
  {
    for(var i = 0; i < node.children.length; i++)
      node.children[i] = move_node(node.children[i], delta_x, delta_y);
  }
  
  return node;
}

function spreader(tree)
{
  var iteration = 1;
  
  var max       = parseInt($("#max_iteration").val());
  var threshold = parseFloat($("#threshold").val());
  var frac      = parseFloat($("#frac").val());  
//   var max       = 20;
//   var threshold = 1.5;   //se os nós não possuirem interseção mas estiverem muito próximos faz com que sejam minimamente afastados
//   var frac      = 4.0;   //4 <= frac <= 8. Quanto menor mais espelhados os pontos ficam
  
  do
  {
    var changed  = false;
    var last_changed = changed;
    
    for(var i = 0; i < tree.children.length; i++)
    {
      var Ci = tree.children[i];
      
      for(var j = 0; j < tree.children.length; j++)
      {
        if(i !== j)
        {
          var Cj = tree.children[j],
              d  = dist(Ci, Cj),
              s  = Ci.r + Cj.r;
          
//           if(!intersection(Ci.x, Ci.y, Ci.r, Cj.x, Cj.y, Cj.r))
          if(s < d)
            s += threshold;
          
          if(s > d)
          {
            var delta = (s - d) / frac,
                vec   = [Cj.x - Ci.x, Cj.y - Ci.y];
                
            if(vec[0] == 0 && vec[1] == 0)
              vec = [delta, delta];
            
            var vec_norm = Math.sqrt(Math.pow(vec[0], 2) + Math.pow(vec[1], 2)),
                vec2 = [vec[0] / vec_norm, vec[1] / vec_norm];
            
            Ci = move_node(Ci, -(vec2[0] * 3 * delta / 4), -(vec2[1] * 3 * delta / 4));
            Cj = move_node(Cj, (vec2[0] * delta / 4), (vec2[1] * delta / 4));            
            
            changed = true;
          }
        }
      }
    }
    
    iteration++;
  }while(last_changed != changed && iteration <= max);
 
  return tree;
}


// https://stackoverflow.com/questions/12219802/a-javascript-function-that-returns-the-x-y-points-of-intersection-between-two-ci/12221389#12221389
function intersection(x0, y0, r0, x1, y1, r1) 
{
  var a, dx, dy, d, h, rx, ry;
  var x2, y2;

  /* dx and dy are the vertical and horizontal distances between
    * the circle centers.
    */
  dx = x1 - x0;
  dy = y1 - y0;

  /* Determine the straight-line distance between the centers. */
  d = Math.sqrt((dy*dy) + (dx*dx));

  /* Check for solvability. */
  if (d > (r0 + r1)) {
      /* no solution. circles do not intersect. */
      return false;
  }
  if (d < Math.abs(r0 - r1)) {
      /* no solution. one circle is contained in the other */
      return false;
  }

  /* 'point 2' is the point where the line through the circle
    * intersection points crosses the line between the circle
    * centers.  
    */

  /* Determine the distance from point 0 to point 2. */
  a = ((r0*r0) - (r1*r1) + (d*d)) / (2.0 * d) ;

  /* Determine the coordinates of point 2. */
  x2 = x0 + (dx * a/d);
  y2 = y0 + (dy * a/d);

  /* Determine the distance from point 2 to either of the
    * intersection points.
    */
  h = Math.sqrt((r0*r0) - (a*a));

  /* Now determine the offsets of the intersection points from
    * point 2.
    */
  rx = -dy * (h/d);
  ry = dx * (h/d);

  /* Determine the absolute intersection points. */
  var xi = x2 + rx;
  var xi_prime = x2 - rx;
  var yi = y2 + ry;
  var yi_prime = y2 - ry;

  return [xi, xi_prime, yi, yi_prime];
}
