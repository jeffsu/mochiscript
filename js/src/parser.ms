class RootParser {
  var handlers = {};

  function initialize() {
    this.out = [];
    this.finished = false;
  }

  function parse(tokens) {
    while (tokens.any()) {
      var token = tokens.peek();
      if (!token) return;
      var handlerClass = token[2] || this.getHandler(token);
      console.log(handlerClass, this.handlers, token);
      if (handlerClass) {
        var handler = new $c[handlerClass];
        handler.parse(tokens);
        this.out.push(handler); 
      } else {
        this.handleToken(token, tokens);
        if (this.finished) return;
      }
    }
  }

  function handleToken(token, tokens) {
    this.out.push(token[1]);
    tokens.consume(token[1].length);
  }

  function toString() {
    var ret = [];
    foreach (var ele in this.out) {
      ret.push(ele.toString()); 
    }
    return ret.join("");
  }

  function getHandler() {
    return null;
  }

  function chop() {
    this.out.pop();
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

    tokens.consume(m[0].length-1);

    var content = new $c.ClassContentParser();
    content.parse(tokens);

    this.out = [ "(function ()", content, ")();" ];
  }
}

class CurlyParser extends RootParser {
  function handleToken(token, tokens) {
    if (token[0] == TYPES.RCURLY) {
      this.curly--;
    } else if (token[0] == TYPES.LCURLY) {
      this.curly++;
    }

    this.$super(token, tokens);
    if (this.curly == 0) this.finished = true;
  }
}

var CurlyParser = $c.CurlyParser;

class ClassContentParser extends CurlyParser {
  function getHandler(token) {
    switch(token[0]) {
      case TYPES.VAR: return "MemberParser";
      case TYPES.FUNCTION: return "MethodParser";
      case TYPES.PRIVATE: return "PrivateParser";
    }
  }
}

class LineParser extends RootParser {
  function handleToken(token, tokens) {
    this.$super(token, tokens);
    if (token[0] == TYPES.SEMICOLON) {
      this.finished = true;
    }
  }
}

class MemberParser extends RootParser {
  private {
    var REGEX = Tokens.regex("var <IDENT>\\s*=\\s*?");
  }

  function parse(tokens) {
    var m = tokens.str.match(REGEX);
    this.name = m[1];
    tokens.consume(m[0].length);

    var parser = new $c.LineParser();
    parser.parse(tokens);
    parser.chop();

    this.out = [ "OO.addMember(", JSON.stringify(this.name), ",",  parser, ");" ];
  }
}

class MethodParser extends RootParser {
  private {
    var REGEX = Tokens.regex("<FUNCTION>\\s*=\\s*?");
  }

}
