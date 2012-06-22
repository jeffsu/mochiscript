$m.parse = function (str) {
  var parser = new $c.RootParser();
  parser.parse(new $c.Tokens(str));
  return parser.toString();
};

$m.toJSON = function (str, options) {
  var parser = new $c.RootParser();
  parser.parse(new $c.Tokens(str));
  return parser.toJSON();
};

$m.pp = function (str, options) {
  var parser = new $c.RootParser();
  parser.parse(new $c.Tokens(str));
  return parser.pp();
};

var OPTIONS = {};

class RootParser {
  var handlers = {};

  function initialize() {
    this.out = [];
    this.finished = false;
  }

  function parse(tokens) {
    var len = tokens.length();
    if (this.startParse(tokens) === false || this.parseTokens(tokens) === false || this.endParse(tokens) === false) return false
    return len != tokens.length();
  }

  // TODO: messy clean this process up
  function parseTokens(tokens) {
    var sanity  = 100;
    var origLen = tokens.length();

    while (tokens.any()) {
      var token   = tokens.peek();
      if (!token) break;

      // has a parser class associated with this token
      var handlerClass = this.getHandler(token) || token[2];
      if (handlerClass) {
        var handler = new $c[handlerClass];
        handler._TYPE = handlerClass;
        if (handler.parse(tokens) !== false) {
          this.out.push(handler);
          tokens.lastHandler = handler;
        } else {
          this.handleToken(token, tokens);
        }
      }

      // no parser class, use "this" to just consume it
      else {
        this.handleToken(token, tokens);
      }

      if (this.finished) break;

      if (origLen == tokens.length() && sanity-- == 0) {
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
    for (var i=0; i<this.out.length; i++) {
      var ele = this.out[i];
      ret.push(ele === undefined ? '' : ele.toString());
    }
    return ret.join("");
  }

  function toJSON() {
    return JSON.stringify(this.toStruct());
  }

  function pp(space) {
    space = space == null ? "  " : space + "  ";

    var ret = [ space + (this._TYPE || 'NODE') ];
    var generic = [];
    foreach (var ele in this.out) {
      if (ele === undefined) {
        ret.push(space + "  UNDEFINED!");
        continue;
      }

      if (ele.pp) {
        if (generic.length) {
          ret.push(space + "  TOKENS:" + JSON.stringify(generic.join('')));
          generic = [];
        }
        ret.push(ele.pp(space));
      }

      else {
        generic.push(ele);
      }
    }

    if (generic.length) {
      ret.push(space + "  TOKENS:" + JSON.stringify(generic.join('')));
    }

    return ret.join("\n");
  }

  function toStruct() {
    var ret = [];
    foreach (var ele in this.out) {
      ret.push(ele.toStruct ? ele.toStruct() : ele);
    }
    return ret;
  }

  // intercepts parser class for special cases
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
    var REGEX   = Tokens.regex("(?:<EXPORT>|<PUBLIC>|<CLASS>) <CLASSNAME><LCURLY>");
    var EXTENDS = Tokens.regex("(?:<EXPORT>|<PUBLIC>|<CLASS>) <CLASSNAME><EXTENDS><CLASSNAME><LCURLY>");
  }

  function parse(tokens) {
    var m = tokens.match(REGEX) || tokens.match(EXTENDS);
    var name      = m[4];
    var extending = m[6] || "$m.Class";

    tokens.consume(m[0].length-1);

    var content = new $c.ClassContentParser();
    content.parse(tokens);

    var isPublic  = ($m.PLATFORM == 'node' && m[2] && m[2].indexOf('public') == 0) ? "exports." + name + '=' + name + ';' : '';
    var isExports = ($m.PLATFORM == 'node' && m[1] && m[1].indexOf('export') == 0) ? "module.exports=" + name + ';' : '';

    this.out = [ extending, ".extend(", JSON.stringify(name), ", function(KLASS, OO)", content, ");", isPublic, isExports ];
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

    this.out = [ "$m.Module.extend(", JSON.stringify(name), ", function(KLASS, OO)", content, ");" ];
  }
}

class CurlyParser extends RootParser {
  var _TYPE = 'CurlyParser';

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

    if (this.curly == 0) {
      this.finished = true;
    }
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
    var parser = new $c.CurlyParser(true);
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
      var parser = new $c.MemberParser();
      parser.isStatic = true;
      parser.parse(tokens);
      this.out.push(parser);
    }

    else {
      var functMatch = tokens.match(FUNCT_REGEX);
      tokens.consume(functMatch[1].length);

      var parser = new $c.MethodParser();
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

var MemberParser = $m.MemberParser;



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
    var beginning  = tokens.match(/^<<(\w+)(?::(\w+))?(.*?)\n/);
    var terminator = beginning[1];

    tokens.consume(beginning[0].length);

    var spacing  = tokens.match(/^(\s*)/);
    var regexSub = new RegExp("^" + (spacing[0] || ''), "mg");

    var strMatch = tokens.match(new RegExp("^([\\s\\S]*?)\\n\\s*" + terminator + "\\b"));
    var toParse  = strMatch[1] || '';

    toParse = toParse.replace(regexSub, '');
    toParse = toParse.replace(/\n/g, "\\n");

    // TODO handle options for interpolation
    var string = '"' + toParse.replace(/"/g, '\\"') + '"';
    tokens.consume(strMatch[0] ? strMatch[0].length : 0);

    // TODO put this in register
    if (beginning[2]) {
      console.log('DEPRECATED JSML: Use Jade!');
      this.out = [ '$m.JSML.process(', string, ')',  beginning[3] ];
    } else {
      this.out = [ string, beginning[3] ];
    }
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

    var body = new $c.CurlyParser();
    body.parse(tokens);
    body.out[0] = "{var self=this;";

    var addMethod = this.isStatic ? 'addStaticMember' : 'addMember';


    this.out = [ 'OO.' + addMethod + '(', JSON.stringify(name), ', function', args, body, ');' ];
  }
}

class ReturnParser extends RootParser {
  function parse(tokens) {
    tokens.consume(2);
    this.out = [ 'return ' ];
  }
}

class ShorthandMapperParser extends RootParser {
  private {
    var ARGS_REGEX = Tokens.regex("<ARGS>\\s*");
  }

  function parse(tokens) {
    tokens.consume(1);
    var nameMatch = tokens.match(/^([\w\$]+)\s*/);
    tokens.consume(nameMatch[0].length);

    var method = nameMatch[1];

    var argsMatch = tokens.match(ARGS_REGEX);
    var args = null;

    if (argsMatch) {
      args = argsMatch[0];
      tokens.consume(argsMatch[0].length);
    } else {
      args = "($1,$2,$3)";
    }

    var body = new $c.ReturnableCurlyParser();
    body.parse(tokens);

    this.out = [ '.', method, '(function', args, body, ')' ];
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

    var body = new $c.CurlyParser();
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

    var m2 = tokens.match(/^\/\*[\s\S]*?\*\//);
    if (m2) {
      tokens.consume(m2[0].length);
      this.out = [ m2[0] ];
      return;
    }

    return false;
  }
}

class RegexParser extends RootParser {
  private {
    var REGEX  = /^\/(\\.|[^\/])+\/[imgy]{0,4}/;
    var DIVIDE = /(\}|\)|\+\+|\-\-|[\w\$]|\]|\})$/;
  }

  function parseTokens(tokens) {
    var back = tokens.lookback(2);

    if (back.match(DIVIDE)) {
      this._TYPE = 'DIVIDE';
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

class ReturnableCurlyParser extends CurlyParser {
  function toString() {
    var ret = this.$super();
    return ret.replace(/^{(\s*)(return)?/, '{$1return ');
  }
}



class ForeachParser extends CurlyParser {
  var _TYPE = 'Foreach';

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

    this.out = [ "for (var ", declare, ";", bool, ';', this.iterator + "++)" ];
  }

  function endParse(tokens) {
    tokens.iterator--;
  }

}
