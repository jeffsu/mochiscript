class RootParser {
  var handlers = {};

  function initialize() {
    this.out = [];
    this.finished = false;
  }

  function parse(tokens) {
    this.startParse(tokens);

    while (tokens.any()) {
      var token = tokens.peek();
      if (!token) break;
      var handlerClass = this.getHandler(token) || token[2];
      if (handlerClass) {
        var handler = new $c[handlerClass];
        handler.parse(tokens);
        this.out.push(handler); 
      } else {
        this.handleToken(token, tokens);
      }
      if (this.finished) break;
    }

    this.endParse(tokens);
  }

  function startParse() { }
  function endParse() { }

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

  function getHandler(token) {
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
  function initialize(chop) {
    this.chop = chop;
    this.$super();
  }

  function handleToken(token, tokens) {
    if (this.curly === undefined) this.curly = 0;
    if (token[0] == TYPES.RCURLY) {
      this.curly--;
    } else if (token[0] == TYPES.LCURLY) {
      this.curly++;
    }

    this.$super(token, tokens);
    if (this.curly == 0) this.finished = true;
  }

  function endParse(tokens) {
    if (this.chop) {
      this.out.pop();
      this.out.shift();
    }
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

class PrivateParser extends CurlyParser {
  private {
    var REGEX = Tokens.regex("<PRIVATE>\\s*");
  }

  function startParse(tokens) {
    var m = tokens.match(REGEX);
    tokens.consume(m[0].length);
  }

  function endParse(tokens) {
    this.out.pop();
    this.out.shift();
  }
}

class IStringParser extends RootParser {
  private {
    var BEGIN = Tokens.regex("<ISTRING_START>");
  }

  function parse(tokens) {
    var m = tokens.match(BEGIN);
    tokens.consume(m[0].length);
    this.out.push('"');

    while (1) {
      var m = tokens.match(/^((?:\\.|.)*?)(#\{|})/);
      console.log(m);
      var str = m[1];
      var len = m[0].length;
      str.replace(/"/, '\\"');

      if (m[2] == '#{') {
        this.out.push(str+'"+(');
        tokens.consume(len-1);
        this.parseMiddle(tokens);
        this.out.push(')+"');
      } 
      
      else if (m[2] == '}') {
        this.out.push(str);
        this.out.push('"');
        tokens.consume(len);
        return;
      }
    }
  }

  function parseMiddle(tokens) {
    var parser = new CurlyParser(true); 
    parser.parse(tokens);
    this.out.push(parser);
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
    var REGEX = Tokens.regex("<FUNCTION> <IDENT><ARGS><SPACE>");
  }

  function parse(tokens) {
    var m = tokens.str.match(REGEX);
    tokens.consume(m[0].length);
    this.name = m[2];
    this.args = m[3];
    this.body = new CurlyParser();
    this.body.foo = true;
    this.body.parse(tokens);

    this.out = [ 'OO.addMember(', JSON.stringify(this.name), ', function', this.args, this.body, ');' ];
  }
}

class ForeachParser extends CurlyParser {
  private {
    var REGEX = Tokens.regex("<FOREACH><LBRACE><VAR> <IDENT>(?:**:**<IDENT>)? in (.*?)**<RBRACE>**{");
  }

  function startParse(tokens) {
    var m = tokens.match(REGEX);
    namespace = tokens.iterator++;

    this.item     = m[4];
    this.iterator = m[5] || "_i_" + namespace;
    this.list     = m[6];

    // TODO ugly, revisit this later
    tokens.consume(m[0].length-1);
    var declare = [ this.iterator + "=0", this.item + "=null", "_list_" + namespace + "=" + this.list, "_len_" + namespace + "=_list_.length" ].join(',');

    var bool = "(" + this.item + "=" + "_list_" + namespace + "[" + this.iterator + "])||" + this.iterator + "<_len_" + namespace;

    this.out = [ "for (", declare, ";", bool, ';', this.iterator + "++)" ];
  }

  function endParse(tokens) {
    tokens.iterator--;
  }
 
}
