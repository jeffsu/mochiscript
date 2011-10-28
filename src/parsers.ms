$m.parse = function (str) {
  var parser = new $c.RootParser();
  parser.parse(new $c.Tokens(str));
  return parser.toString();
};

class RootParser {
  var handlers = {};

  function initialize() {
    this.out = [];
    this.finished = false;
  }

  function parse(tokens) {
    this.startParse(tokens);
    this.parseTokens(tokens);
    this.endParse(tokens);
  }

  function parseTokens(tokens) {
    var sanity = 100;
    while (tokens.any()) {
      var origLen = tokens.length;
      var token = tokens.peek();
      if (!token) break;
      var handlerClass = this.getHandler(token) || token[2];
      if (handlerClass) {
        var handler = new $c[handlerClass];
        if (handler.parse(tokens) === false) {
          this.handleToken(token, tokens);
        } else {
          this.out.push(handler); 
        }
      } else {
        this.handleToken(token, tokens);
      }
      if (this.finished) break;

      if (origLen == tokens.length && sanity-- == 0) {
        throw "parse error";
      } else {
        sanity = 100;
      }
    }
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
    var REGEX   = Tokens.regex("<CLASS> <CLASSNAME><LCURLY>");
    var EXTENDS = Tokens.regex("<CLASS> <CLASSNAME><EXTENDS><CLASSNAME><LCURLY>");
  }

  function parse(tokens) {
    var m = tokens.match(REGEX) || tokens.match(EXTENDS);
    var name      = m[2];
    var extending = m[4] || "$m.Class";

    tokens.consume(m[0].length-1);

    var content = new $c.ClassContentParser();
    content.parse(tokens);

    this.out = [ "var ", name, " = " + extending + ".extend(function(KLASS, OO)", content, ");" ];
  }
}

class ModuleParser extends RootParser {
  private {
    var REGEX = Tokens.regex("<MODULE> <CLASSNAME><LCURLY>");
  }

  function parse(tokens) {
    var m = tokens.match(REGEX);
    if (!m) return false;
    var name = m[2];
    tokens.consume(m[0].length-1);

    var content = new $c.ClassContentParser();
    content.parse(tokens);

    this.out = [ "var ", name, " = $m.Module.extend(function(KLASS, OO)", content, ");" ];
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
      case TYPES.STATIC:   return "StaticParser";
      case TYPES.VAR:      return "MemberParser";
      case TYPES.FUNCTION: return "MethodParser";
      case TYPES.PRIVATE:  return "PrivateParser";
      case TYPES.INCLUDE:  return "IncludeParser";
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

class StaticParser extends RootParser {
  private {
    var VAR_REGEX = Tokens.regex("(<STATIC>(\\s+))<VAR>");
    var FUNCT_REGEX = Tokens.regex("(<STATIC>(\\s+))<FUNCTION>");
  }

  function parseTokens(tokens) {
    var varMatch = tokens.match(VAR_REGEX);
    if (varMatch) {
      tokens.consume(varMatch[1].length);
      var parser = new MemberParser();
      parser.isStatic = true;
      parser.parse(tokens);
      this.out.push(parser);
    } 
    
    else {
      var functMatch = tokens.match(FUNCT_REGEX);
      tokens.consume(functMatch[1].length);

      var parser = new MethodParser();
      parser.isStatic = true;
      parser.parse(tokens);
      this.out.push(parser);
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
    var addMethod = this.isStatic ? 'addStaticMember' : 'addMember';

    this.out = [ "OO." + addMethod + "(", JSON.stringify(this.name), ",",  parser, ");" ];
  }
}



class IncludeParser extends RootParser {
  private {
    var REGEX = Tokens.regex("<INCLUDE> <CLASSNAME><SEMICOLON>");
  }

  function parse(tokens) {
    var m = tokens.match(REGEX);
    tokens.consume(m[0].length);
    this.out = [ 'OO.include(',  m[2], ');' ];
  }
}

class HereDocParser extends RootParser {
  private {
    var REGEX = Tokens.regex("<HEREDOC>");
  }

  function parse(tokens) {
    var beginning = tokens.match(/^<<(\w+)\s*([;\)])*\n/);
    tokens.consume(beginning[0].length);

    var spacing = tokens.match(/^(\s*)/);
    var regexSub = new RegExp("^" + (spacing[0] || ''), "mg");


    var strMatch = tokens.match(new RegExp("^([\\s\\S]*?)\\n\\s*" + beginning[1] + "\\s*\\n"));
    var toParse  = strMatch[1] || '';

    toParse = toParse.replace(regexSub, '');
    toParse = toParse.replace("\n", "\\n");

    var string = $m.parse('%{' + toParse + '}');
    tokens.consume(strMatch[0] ? strMatch[0].length : 0);

    this.out = [ string, beginning[2] || ';' ];
  }
}

class MethodParser extends RootParser {
  private {
    var REGEX = Tokens.regex("<FUNCTION> <IDENT><ARGS><SPACE>");
  }

  function parse(tokens) {
    var m = tokens.str.match(REGEX);
    tokens.consume(m[0].length);
    var name = m[2];
    var args = m[3];

    var body = new CurlyParser();
    body.parse(tokens);

    var addMethod = this.isStatic ? 'addStaticMember' : 'addMember';
    

    this.out = [ 'OO.' + addMethod + '(', JSON.stringify(name), ', function', args, body, ');' ];
  }
}

class ShorthandFunctionParser extends RootParser {
  private {
    var ARGS_REGEX = Tokens.regex("<ARGS>\\s*");
  }

  function parse(tokens) {
    tokens.consume(1);
    var argsMatch = tokens.match(ARGS_REGEX);
    var args = null;

    if (argsMatch) {
      args = argsMatch[0];
      tokens.consume(argsMatch[0].length);
    } else {
      args = "($1,$2,$3)";
    }

    var body = new CurlyParser();
    body.parse(tokens);
    var semi = tokens.match(/^\s*[,;\)]/) ? '' : ';';

    this.out = [ 'function', args, body, semi ];
  }
}

class CommentParser extends RootParser {
  function parse(tokens) {
    var m = tokens.match(/^\/\/.*?\n/);
    if (m) {
      tokens.consume(m[0].length);
      this.out = [ m[0] ];
      return;
    }

    var m2 = tokens.match(/^\/\*.*?\*\//);
    if (m2) {
      tokens.consume(m2[0].length);
      this.out = [ m2[0] ];
      return;
    }
  }
}

class RegexParser extends RootParser {
  private {
    var REGEX  = /^\/(?!\s)[^[\/\n\\]*(?:(?:\\[\s\S]|\[[^\]\n\\]*(?:\\[\s\S][^\]\n\\]*)*])[^[\/\n\\]*)*\/[imgy]{0,4}(?!\w)/;
    var DIVIDE = /(\}|\)|\+\+|\-\-|[\w\$])$/;
  }

  function parseTokens(tokens) {
    var back = tokens.lookback(2);
    if (back.match(DIVIDE)) {
      tokens.consume(1);
      this.out.push("/"); 
    } 
    
    else {
      var m = tokens.match(REGEX);
      if (m) {
        this.out.push(m[0]);
        tokens.consume(m[0].length);
      } else {
        return false;
      }
    }
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
    var declare = [ this.iterator + "=0", this.item + "=null", "_list_" + namespace + "=" + this.list, "_len_" + namespace + "=_list_" + namespace + ".length" ].join(',');

    var bool = "(" + this.item + "=" + "_list_" + namespace + "[" + this.iterator + "])||" + this.iterator + "<_len_" + namespace;

    this.out = [ "for (", declare, ";", bool, ';', this.iterator + "++)" ];
  }

  function endParse(tokens) {
    tokens.iterator--;
  }
 
}
