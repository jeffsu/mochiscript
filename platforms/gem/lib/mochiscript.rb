require 'v8'
require 'json'

module Mochiscript
  VERSION = "0.4.0-pre6".sub("-", '.')
  class Context
    def initialize
      @ctx = V8::Context.new 
      @ctx['_$m_adapter'] = Adapter.new
      @ctx.eval(Parser::JAVASCRIPT)
    end

    def parse(str)
      @ctx.eval_js("$m.parse(#{str.to_json})")
    end

    def eval_ms(str)
      @ctx.eval_js(parse(str))
    end

    protected

    def method_missing(name, *args, &block)
      @ctx.send(name, *args, &block)
    end
  end

  class Adapter
    def out(arg)
      print arg
    end

    def outs(arg)
      puts arg
    end
  end

  class Parser
JAVASCRIPT = <<'FINISH'
var $m  = { ROOT: this, ADAPTER: _$m_adapter };
var JS2 = $m; 
(function () {
  
// CLASS HELPERS
(function (undefined, $m) {

  var OO = function (klass, par) {
    this.klass = klass;
    this.par   = par;

    this.members       = {};
    this.staticMembers = {};
    this.children = [];
    this.included = [];

    if (this.par) this.par.OO.children.push(klass);
  };

  OO.prototype = {
    forbiddenMembers: { 
      'prototype': undefined, 
      'OO': undefined 
    },
 
    include: function(module) {
      this.included.push(module);
      var members = module.OO.members;
      for (var name in members) {
        if (members.hasOwnProperty(name)) {
          this.addMember(name, members[name]);
        }
      }

      var staticMembers = module.OO.staticMembers;
      for (var name in staticMembers) {
        if (staticMembers.hasOwnProperty(name)) {
          this.addStaticMember(name, staticMembers[name]);
        }
      }

      if (typeof staticMembers['included'] == 'function') {
        staticMembers['included'](this.klass);
      }
    },

    createNamespace: function(name) {
      var splitted = name.split('.');
      var klassName = splitted.pop();
      var root = $m.ROOT;

      while (splitted.length > 0) {
        var name = splitted.shift();
        if (!root[name]) root[name] = $m.Class.extend({});
        root = root[name];
      }

      return [ root, klassName ];
    },

    makeSuper: function(newMethod, oldMethod) {
      if (!oldMethod) return newMethod;

      return function() {
        this.$super = oldMethod;
        return newMethod.apply(this, arguments);
      };
    },

    addMember: function(name, member) {
      if (this.forbiddenMembers.hasOwnProperty(name)) return;

      var proto = this.klass.prototype;
      if (typeof proto[name] == 'function' && !(proto[name] instanceof RegExp)) {
        member = this.makeSuper(member, proto[name]);
      }

      proto[name] = member;
      this.members[name] = member;
    },

    addStaticMember: function(name, member) {
      if (this.forbiddenMembers.hasOwnProperty(name)) return;

      if (typeof this.klass[name] == 'function') {
        if (!this.klass.hasOwnProperty(name)) {
          member = this.makeSuper(member, this.klass[name]);
        }
      }
      
      this.klass[name] = member;
      this.staticMembers[name] = member;
    }
  };

  $m.Class = function() { this.initialize.apply(this, arguments); };
  $m.Class.OO = new OO($m.Class);
  $m.Class.prototype = {
    initialize: function () {},
    oo: $m.Class.OO
  };

  var namedClasses = {};
  $m.getClass = function(name) {
    return namedClasses[name];
  };

  var noInit = false;
  $m.Class.extend = function(name, klassDef) {
    var klass = function() { if (!noInit) this.initialize.apply(this, arguments); };
    klass.OO  = new OO(klass, this);

    if (typeof name != 'string') {
      klassDef = name;
    } else {
      namedClasses[name] = klass;
      var namespace = this.OO.createNamespace(name);
      namespace[0][namespace[1]] = klass;
    }

    // create instance of this as prototype for new this
    noInit = true;
    var proto = new this();
    noInit = false;

    klass.prototype = proto;
    var oo   = klass.OO;
    proto.OO = oo;

    for (var name in this) {
      oo.addStaticMember(name, this[name]);
    }

    if (typeof klassDef == 'function') {
      klassDef(klass, oo);
    } else {
      for (var name in klassDef) {
        oo.addMember(name, klassDef[name]);
      }
    }

    return klass;
  };

  $m.Module = $m.Class;

  var assert = {
    'eq': function(expected, actual) { if (expected != actual) $m.outs("Expected "+expected+", but got "+actual+".") },
    'isFalse': function(val) { if (val) $m.outs("Expected false, but got "+JSON.stringify(val)+".") },
    'isTrue': function(val) { if (!val) $m.outs("Expected true, but got " +val+".") }
  };

  $m.test = function(message, callback) {
    if (!callback) callback = message;
    callback(assert);
  };

  function addListener(type, listener) {
    var events = this.__$events || (this.__$events = {});
    this.emit('newListener', type, listener);
    if (!events[type]) events[type] = [];
    events[type].push(listener);
  }

  $m.EventEmitter = $m.Module.extend({
    emit: function () {
      // TODO optimize
      var type     = arguments[0];
      var events   = this.__$events || (this.__$events = {});
      var handlers = events[type];

      if (!handlers) return false;

      var args = [];
      for (var i=1,len=arguments.length; i<len; i++) args[i-1] = arguments[i];
      for (var i=0,len=handlers.length; i<len; i++) handlers[i].apply(this, args);
    },

    addListener: addListener,
    on: addListener
  });

  $m.out = function () {
    for(var i=0,_c1=arguments,_l1=_c1.length,arg;(arg=_c1[i])||(i<_l1);i++){
      $m.ADAPTER.out(arg);
      if (i < arguments.length-1) {
        $m.ADAPTER.out(',');
      }
    }
  };

  $m.outs = function () {
    for(var _i1=0,_c1=arguments,_l1=_c1.length,arg;(arg=_c1[_i1])||(_i1<_l1);_i1++){
      $m.ADAPTER.outs(arg);
    }
  };


  return $m;
})(undefined, $m);


  var IDENT  = "[\\$\\w]+";
var TOKENS = [
  [ "SPACE", "\\s+"  ],

  [ "STATIC",   "static\\b" ], 
  [ "MODULE",   "module\\b", 'ModuleParser' ], 
  [ "CLASS",    "class\\b",  'ClassParser' ], 
  [ "FUNCTION", "function\\b" ], 
  [ "INCLUDE",  "include\\b" ], 
  [ "VAR",      "var\\b" ], 
  [ "PRIVATE",  "private\\b" ], 
  [ "EXTENDS",  "extends\\b" ], 
  [ "FOREACH",  "foreach\\b", 'ForeachParser' ], 

  [ "SHORTHAND_FUNCTION", "#(?:{|\\()", 'ShorthandFunctionParser' ], 
  [ "ISTRING_START", "%{", 'IStringParser' ], 
  [ "HEREDOC", "<<[A-Z][0-9A-Z]*", 'HereDocParser' ], 

  [ "DSTRING", "\"(?:\\\\.|[^\"])*\"" ], 
  [ "SSTRING", "\'(?:\\\\.|[^\'])*\'" ], 

  [ "SEMICOLON", ";" ], 
  [ "OPERATOR",  "\\+|\\-|\\++" ],
  [ "EQUALS",    "=" ],

  [ "COMMENT", "\\/\\/|\\/\\*", "CommentParser" ], 
  [ "REGEX", "/", 'RegexParser' ], 

  [ "LBRACE", "\\(" ],
  [ "RBRACE", "\\)" ],
  [ "LCURLY", "\\{" ],
  [ "RCURLY", "\\}" ],

  [ "IDENT", IDENT ], 
  [ "WHATEVER", "." ]
];

var $c      = $m.ROOT;
var TYPES   = {};
var REGEXES = [];
var MAIN_REGEX = null;

for(var i=0,_c1=TOKENS,_l1=_c1.length,t;(t=_c1[i])||(i<_l1);i++){
  TYPES[t[0]] = i; 
  REGEXES.push("(" + t[1] + ")");
}

var EXTRA_REGEX_STRINGS = {
  ARGS: "\\(\s*(?:" + IDENT + ")?(?:\\s*,\\s*" + IDENT + ")*\s*\\)",
  CLASSNAME: "[\\$\\w\\.]+"
};

var MAIN_REGEX = new RegExp("^" + REGEXES.join('|'));

JS2.Class.extend('Tokens', function(KLASS, OO){
  OO.addMember("initialize",function (str) {
    this.orig     = str;
    this.str      = str;
    this.iterator = 0;
    this.consumed = 0;
  });

  OO.addMember("peek",function () {
    if (this._peek) return this._peek;

    var m = this.str.match(MAIN_REGEX);
    if (!m) return null;

    for(var i=0,_c1=TOKENS,_l1=_c1.length,ele;(ele=_c1[i])||(i<_l1);i++){
      if (m[i+1]) return this._peek = [ i, m[i+1], ele[2] ];
    }
  });

  OO.addStaticMember("regex",function (str) {
    var regexStr = str.replace(/\*\*/g, "\\s*").replace(/\s+/g, "\\s+").replace(/\>\</g, ">\\s*<").replace(/\<(\w+)\>/g, function($1,$2,$3){
      return "(" + (EXTRA_REGEX_STRINGS[$2] || TOKENS[TYPES[$2]][1])  + ")";
    });

    return new RegExp("^" + regexStr);
  });

  OO.addMember("consume",function (n) {
    this.str   = this.str.substr(n, this.str.length-n);
    this._peek = null;
    this.consumed += n;
  });

  OO.addMember("lookback",function (n) {
    var starting = this.consumed;
    while (this.orig.charAt(starting).match(/\s/)) starting--;
    return this.orig.substr(starting-1-n, n);
  });

  OO.addMember("any",function () {
    return this.str.length > 0;
  });

  OO.addMember("match",function (regex) {
    return this.str.match(regex);
  });
});
var Tokens = $c.Tokens;


$m.parse = function (str) {
  var parser = new $c.RootParser();
  parser.parse(new $c.Tokens(str));
  return parser.toString();
};

JS2.Class.extend('RootParser', function(KLASS, OO){
  OO.addMember("handlers",{});

  OO.addMember("initialize",function () {
    this.out = [];
    this.finished = false;
  });

  OO.addMember("parse",function (tokens) {
    this.startParse(tokens);
    this.parseTokens(tokens);
    this.endParse(tokens);
  });

  OO.addMember("parseTokens",function (tokens) {
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
  });

  OO.addMember("startParse",function () { });
  OO.addMember("endParse",function () { });

  OO.addMember("handleToken",function (token, tokens) {
    this.out.push(token[1]);
    tokens.consume(token[1].length);
  });

  OO.addMember("toString",function () {
    var ret = [];
    for(var _i1=0,_c1=this.out,_l1=_c1.length,ele;(ele=_c1[_i1])||(_i1<_l1);_i1++){
      ret.push(ele.toString()); 
    }
    return ret.join("");
  });

  OO.addMember("getHandler",function (token) {
    return null;
  });

  OO.addMember("chop",function () {
    this.out.pop();
  });
});

var RootParser = $c.RootParser;

RootParser.extend('ClassParser', function(KLASS, OO){
  // private closure

    var REGEX   = Tokens.regex("<CLASS> <CLASSNAME><LCURLY>");
    var EXTENDS = Tokens.regex("<CLASS> <CLASSNAME><EXTENDS><CLASSNAME><LCURLY>");
  

  OO.addMember("parse",function (tokens) {
    var m = tokens.match(REGEX) || tokens.match(EXTENDS);
    var name      = m[2];
    var extending = m[4] || "$m.Class";

    tokens.consume(m[0].length-1);

    var content = new $c.ClassContentParser();
    content.parse(tokens);

    this.out = [ "var ", name, " = " + extending + ".extend(function(KLASS, OO)", content, ");" ];
  });
});

RootParser.extend('ModuleParser', function(KLASS, OO){
  // private closure

    var REGEX = Tokens.regex("<MODULE> <CLASSNAME><LCURLY>");
  

  OO.addMember("parse",function (tokens) {
    var m = tokens.match(REGEX);
    if (!m) return false;
    var name = m[2];
    tokens.consume(m[0].length-1);

    var content = new $c.ClassContentParser();
    content.parse(tokens);

    this.out = [ "var ", name, " = $m.Module.extend(function(KLASS, OO)", content, ");" ];
  });
});

RootParser.extend('CurlyParser', function(KLASS, OO){
  OO.addMember("initialize",function (chop) {
    this.chop = chop;
    this.$super();
  });

  OO.addMember("handleToken",function (token, tokens) {
    if (this.curly === undefined) this.curly = 0;
    if (token[0] == TYPES.RCURLY) {
      this.curly--;
    } else if (token[0] == TYPES.LCURLY) {
      this.curly++;
    }

    this.$super(token, tokens);
    if (this.curly == 0) this.finished = true;
  });

  OO.addMember("endParse",function (tokens) {
    if (this.chop) {
      this.out.pop();
      this.out.shift();
    }
  });
});

var CurlyParser = $c.CurlyParser;

CurlyParser.extend('ClassContentParser', function(KLASS, OO){
  OO.addMember("getHandler",function (token) {
    switch(token[0]) {
      case TYPES.STATIC:   return "StaticParser";
      case TYPES.VAR:      return "MemberParser";
      case TYPES.FUNCTION: return "MethodParser";
      case TYPES.PRIVATE:  return "PrivateParser";
      case TYPES.INCLUDE:  return "IncludeParser";
    }
  });

});

RootParser.extend('LineParser', function(KLASS, OO){
  OO.addMember("handleToken",function (token, tokens) {
    this.$super(token, tokens);
    if (token[0] == TYPES.SEMICOLON) {
      this.finished = true;
    }
  });
});

CurlyParser.extend('PrivateParser', function(KLASS, OO){
  // private closure

    var REGEX = Tokens.regex("<PRIVATE>\\s*");
  

  OO.addMember("startParse",function (tokens) {
    var m = tokens.match(REGEX);
    tokens.consume(m[0].length);
  });

  OO.addMember("endParse",function (tokens) {
    this.out.pop();
    this.out.shift();
  });
});


RootParser.extend('IStringParser', function(KLASS, OO){
  // private closure

    var BEGIN = Tokens.regex("<ISTRING_START>");
  

  OO.addMember("parse",function (tokens) {
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
  });

  OO.addMember("parseMiddle",function (tokens) {
    var parser = new CurlyParser(true); 
    parser.parse(tokens);
    this.out.push(parser);
  });
});

RootParser.extend('StaticParser', function(KLASS, OO){
  // private closure

    var VAR_REGEX = Tokens.regex("(<STATIC>(\\s+))<VAR>");
    var FUNCT_REGEX = Tokens.regex("(<STATIC>(\\s+))<FUNCTION>");
  

  OO.addMember("parseTokens",function (tokens) {
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
  });

  


});

RootParser.extend('MemberParser', function(KLASS, OO){
  // private closure

    var REGEX = Tokens.regex("var <IDENT>\\s*=\\s*?");
  

  OO.addMember("parse",function (tokens) {
    var m = tokens.str.match(REGEX);
    this.name = m[1];
    tokens.consume(m[0].length);

    var parser = new $c.LineParser();
    parser.parse(tokens);
    parser.chop();
    var addMethod = this.isStatic ? 'addStaticMember' : 'addMember';

    this.out = [ "OO." + addMethod + "(", JSON.stringify(this.name), ",",  parser, ");" ];
  });
});



RootParser.extend('IncludeParser', function(KLASS, OO){
  // private closure

    var REGEX = Tokens.regex("<INCLUDE> <CLASSNAME><SEMICOLON>");
  

  OO.addMember("parse",function (tokens) {
    var m = tokens.match(REGEX);
    tokens.consume(m[0].length);
    this.out = [ 'OO.include(',  m[2], ');' ];
  });
});

RootParser.extend('HereDocParser', function(KLASS, OO){
  // private closure

    var REGEX = Tokens.regex("<HEREDOC>");
  

  OO.addMember("parse",function (tokens) {
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
  });
});

RootParser.extend('MethodParser', function(KLASS, OO){
  // private closure

    var REGEX = Tokens.regex("<FUNCTION> <IDENT><ARGS><SPACE>");
  

  OO.addMember("parse",function (tokens) {
    var m = tokens.str.match(REGEX);
    tokens.consume(m[0].length);
    var name = m[2];
    var args = m[3];

    var body = new CurlyParser();
    body.parse(tokens);

    var addMethod = this.isStatic ? 'addStaticMember' : 'addMember';
    

    this.out = [ 'OO.' + addMethod + '(', JSON.stringify(name), ', function', args, body, ');' ];
  });
});

RootParser.extend('ShorthandFunctionParser', function(KLASS, OO){
  // private closure

    var ARGS_REGEX = Tokens.regex("<ARGS>\\s*");
  

  OO.addMember("parse",function (tokens) {
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
  });
});

RootParser.extend('CommentParser', function(KLASS, OO){
  OO.addMember("parse",function (tokens) {
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
  });
});

RootParser.extend('RegexParser', function(KLASS, OO){
  // private closure

    var REGEX  = /^\/(?!\s)[^[\/\n\\]*(?:(?:\\[\s\S]|\[[^\]\n\\]*(?:\\[\s\S][^\]\n\\]*)*])[^[\/\n\\]*)*\/[imgy]{0,4}(?!\w)/;
    var DIVIDE = /(\}|\)|\+\+|\-\-|[\w\$])$/;
  

  OO.addMember("parseTokens",function (tokens) {
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
  });

});

CurlyParser.extend('ForeachParser', function(KLASS, OO){
  // private closure

    var REGEX = Tokens.regex("<FOREACH><LBRACE><VAR> <IDENT>(?:**:**<IDENT>)? in (.*?)**<RBRACE>**{");
  

  OO.addMember("startParse",function (tokens) {
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
  });

  OO.addMember("endParse",function (tokens) {
    tokens.iterator--;
  });
 
});


JS2.Class.extend('JSML', function(KLASS, OO){
  OO.addStaticMember("process",function (txt) {
    return new KLASS(txt);
  });

  OO.addMember("initialize",function (txt) {
    var lines = txt.split(/\n/);
    this.root    = new JS2.JSMLElement();
    this.stack   = [ this.root ];

    for(var _i1=0,_c1=lines,_l1=_c1.length,l;(l=_c1[_i1])||(_i1<_l1);_i1++){
      if (l.match(/^\s*$/)) continue;
      this.processLine(l);
    }

    var toEval = 'function process() { var out = [];\n' + this.flatten().join('') + '\n return out.join("");\n}';
    eval(toEval);

    this.result = function(bound) {
      bound = bound || {};
      return process.call(bound);
    };
  });

  OO.addMember("flatten",function () {
    return this.root.flatten();
  });

  OO.addMember("processLine",function (line) {
    if (line.match(/^\s*$/)) return;

    var ele   = new JS2.JSMLElement(line);
    var scope = this.getScope();

    if (ele.scope == scope) {
      this.stack.pop();
      this.getLast().push(ele);
      this.stack.push(ele);
    } else if (ele.scope > scope) {
      this.getLast().push(ele); 
      this.stack.push(ele);
    } else if (ele.scope < scope) {
      var diff = scope - ele.scope + 1;
      while(diff-- > 0) {
        this.stack.pop();
      }
      this.getLast().push(ele);
      this.stack.push(ele);
    }
  });


  OO.addMember("getScope",function () {
    return this.stack.length - 1;
  });

  OO.addMember("getLast",function () {
    return this.stack[this.stack.length-1];
  });

});

JS2.Class.extend('JSMLElement', function(KLASS, OO){
  OO.addMember("SCOPE_REGEX",/^(\s*)(.*)$/);
  OO.addMember("SPLIT_REGEX",/^((?:\.|\#|\%)[^=\s\{]*)?(\{.*\})?(=|-)?(?:\s*)(.*)$/);
  OO.addMember("TOKEN_REGEX",/(\%|\#|\.)([\w][\w\-]*)/g);
  OO.addMember("JS_REGEX",/^(-|=)(.*)$/g);
  OO.addMember("SCOPE_OFFSET",1);
  OO.addMember("SELF_CLOSING",{ area: null, basefont: null, br: null, hr: null, input: null, img: null, link: null, meta: null });

  OO.addMember("initialize",function (line) {
    this.children = [];

    if (line == null) {
      this.scope = this.SCOPE_OFFSET;
      return;
    }

    var spaceMatch = line.match(this.SCOPE_REGEX);
    this.scope = spaceMatch[1].length / 2 + this.SCOPE_OFFSET;

    this.classes  = [];
    this.nodeID   = null;

    this.parse(spaceMatch[2]);
  });

  OO.addMember("push",function (child) {
    this.children.push(child);
  });

  OO.addMember("parse",function (line) {
    this.attributes;
    this.line = line;
    var self = this;

    var splitted = line.match(this.SPLIT_REGEX);
    var tokens   = splitted[1];
    var attrs    = splitted[2];
    var jsType   = splitted[3];
    var content  = splitted[4];

    if (tokens) {
      tokens.replace(this.TOKEN_REGEX, function(match, type, name){ 
        switch(type) {
          case '%': self.nodeType = name; break;
          case '.': self.classes.push(name); break;
          case '#': self.nodeID = name; break;
        } 
        return '';
      });
    }

    if (jsType == '=') {
      this.jsEQ = content;
    } else if (jsType == '-') {
      this.jsExec = content;
    } else {
      this.content = content;
    }

    if (attrs) {
      this.attributes = attrs;
    }

    if (!this.nodeType && (this.classes.length || this.nodeID)) {
      this.nodeType = 'div';
    }

    if (this.SELF_CLOSING.hasOwnProperty(this.nodeType) && this.children.length == 0) {
      this.selfClose = '/';
    } else {
      this.selfClose = '';
    }
  });

  OO.addMember("flatten",function () {
    var out = [];
   
    for(var _i1=0,_c1=this.children,_l1=_c1.length,c;(c=_c1[_i1])||(_i1<_l1);_i1++){
      var arr = c.flatten();
      for(var _i2=0,_c2=arr,_l2=_c2.length,item;(item=_c2[_i2])||(_i2<_l2);_i2++){
        out.push(item);
      }
    }

    if (this.nodeType) {
      this.handleJsEQ(out);
      this.handleContent(out);
      out.unshift('out.push("<' + this.nodeType + '"+JS2.JSMLElement.parseAttributes(' + (this.attributes || "{}") + ', ' + JSON.stringify(this.classes || []) + ', ' + JSON.stringify(this.id || null) + ')+"' + this.selfClose + '>");\n');
      if (this.selfClose == '') {
        out.push('out.push(' + JSON.stringify("</"+(this.nodeType)+">") + ');\n');
      }
    } else {
      this.handleJsExec(out);
      this.handleJsEQ(out);
      this.handleContent(out);
    }

    return out;
  });

  OO.addMember("handleJsEQ",function (out) {
    if (this.jsEQ) {
      this.jsEQ = this.jsEQ.replace(/;\s*$/, '');
      out.unshift('out.push(' + this.jsEQ + ');\n');
    }
  });

  OO.addMember("handleContent",function (out) {
    if (this.content != null && this.content.length > 0) {
      out.unshift('out.push(' + JSON.stringify(this.content) + ');\n');
    }
  });


  OO.addMember("handleJsExec",function (out) {
    if (this.jsExec) {
      out.unshift(this.jsExec);
      if (this.jsExec.match(/\{\s*$/)) {
        out.push("}\n");
      }
    }
  });

  OO.addStaticMember("parseAttributes",function (hash, classes, id) {
    var out = [];
    classes = classes || [];
    if (hash['class']) classes.push(hash['class']);
    if (classes.length) hash['class'] = classes.join(" ");

    for (var k in hash) {
      if (hash.hasOwnProperty(k)) {
        out.push(k + '=' + JSON.stringify(hash[k]));
      }
    }
    return (out.length ? ' ' : '') + out.join(' ');
  });
});


JS2.Class.extend('CLI', function(KLASS, OO){
  // private closure

    var COMMANDS = {
      help:    'help',
      render:  'render',
      compile: 'compile',
      watch:   'watch'
    };
  

  OO.addMember("run",function (args) {
    var opts = this.parseOpts(args);
    var options = opts[0];
    var command = opts[1];
    var files   = opts[2];
  });

  OO.addMember("parseOpts",function (args) {
    var files   = [];
    var options = {};
    var command = null;

    var endedArgs = false;

    for(var i=0,_c1=args,_l1=_c1.length,arg;(arg=_c1[i])||(i<_l1);i++){
      if (endedArgs) {
        files.push(arg);
      }
      
      else if (COMMANDS[arg]) {
        command   = arg;
        endedArgs = true;
      }

      else {
        var setting = arg.match(/^(\w+)(?:=(.*))?$/);
        if (setting) options[setting[0]] = setting[1] || 'true';
      }
    }

    return [ options, command, files ];
  });
});


})();
FINISH
  end
end
