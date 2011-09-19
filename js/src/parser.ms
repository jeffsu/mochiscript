class RootParser {
  var handlers = {};

  function initialize() {
    this.out = [];
  }

  function parse(tokens) {
    while (tokens.any()) {
      var token = tokens.peek();
      if (!token) return;
      var handlerClass = token[2];
      if (handlerClass) {
        var handler = new $c[handlerClass];
        handler.parse(tokens);
        this.out.push(handler); 
      } else {
        this.out.push(token[1]);
        tokens.consume(token[1].length);
      }
    }
  }

  function toString() {
    var ret = [];
    foreach (var ele in this.out) {
      ret.push(ele.toString()); 
    }
    return ret.join("");
  }
}

var RootParser = $c.RootParser;

class ClassParser extends RootParser {
  private {
    var REGEX = Tokens.regex("<CLASS> <IDENT><LCURLY>");
  }

  function parse(tokens) {
    var m = tokens.str.match(REGEX);
    var name = m[1];
    tokens.consume(m[0].length);
    this.out.push([ "(function () { }" ]);
  }
}
