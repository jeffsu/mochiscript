(function (undefined, JS2) {
  JS2.require = function(file, callback) {
    var xmlhttp;
    if (window.XMLHttpRequest) { // code for IE7+, Firefox, Chrome, Opera, Safari
      xmlhttp = new XMLHttpRequest();
    } else { 
      xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
    }

    xmlhttp.onreadystatechange = function() {
      if (xmlhttp.readyState==4 && xmlhttp.status==200) {
        try {
          var code = file.match(/js2$/) ? JS2.render(xmlhttp.responseText) : xmlhttp.responseText;
          if (callback) { 
            callback(code);
          } else {
            eval(code);
          }
        } catch(e) {
          if (window.console) console.log(e);
        }
      }
    }

    xmlhttp.open("GET",file,true);
    xmlhttp.send();
  }
})(undefined, JS2);
