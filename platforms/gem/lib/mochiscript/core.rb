require 'v8'
require 'json'

module Mochiscript
  class Context
    def initialize
      @ctx = V8::Context.new
      @ctx['_$m_adapter'] = Adapter.new
      @ctx.eval(Parser::JAVASCRIPT)
    end

    def parse(str)
      @ctx.eval_js("$m.parse(#{str.to_json})")
    end

    def to_json(str)
      @ctx.eval_js("$m.toJSON(#{str.to_json})")
    end

    def pp(str)
      return @ctx.eval_js("$m.pp(#{str.to_json})")
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
var $m  = { ROOT: this, ADAPTER: _$m_adapter, PLATFORM: 'ruby' };
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

  $m.PUSH_ROOT = function (r) {
    this.ROOTS = this.ROOTS || [];
    this.ROOTS.push(r);
    this.ROOT = r;
  };

  $m.POP_ROOT = function () {
    this.ROOTS = this.ROOTS || [];
    if (this.ROOTS.length) {
      this.ROOTS.pop();
      this.ROOT = this.ROOTS[this.ROOTS.length-1];
    }

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

  $m.out = function () {
    for (var i=0,arg=null,_list_0=arguments,_len_0=_list_0.length;(arg=_list_0[i])||i<_len_0;i++){
      $m.ADAPTER.out(arg);
      if (i < arguments.length-1) {
        $m.ADAPTER.out(',');
      }
    }
  };

  $m.outs = function () {
    for (var _i_0=0,arg=null,_list_0=arguments,_len_0=_list_0.length;(arg=_list_0[_i_0])||_i_0<_len_0;_i_0++){
      $m.ADAPTER.outs(arg);
    }
  };

  return $m;
})(undefined, $m);


$m.Class.extend("EventEmitter", function(KLASS, OO){
  
    this._maxListeners = 10;
    var isArray = Array.isArray;
  

  OO.addMember("emit", function(){
    var type = arguments[0];
    // If there is no 'error' event listener then throw.
    if (type === 'error') {
      if (!this._events || !this._events.error ||
          (isArray(this._events.error) && !this._events.error.length))
      {
        if (arguments[1] instanceof Error) {
          throw arguments[1]; // Unhandled 'error' event
        } else {
          throw new Error("Uncaught, unspecified 'error' event.");
        }
        return false;
      }
    }

    if (!this._events) return false;
    var handler = this._events[type];
    if (!handler) return false;

    if (typeof handler == 'function') {
      switch (arguments.length) {
        // fast cases
        case 1:
          handler.call(this);
          break;
        case 2:
          handler.call(this, arguments[1]);
          break;
        case 3:
          handler.call(this, arguments[1], arguments[2]);
          break;
        // slower
        default:
          var l = arguments.length;
          var args = new Array(l - 1);
          for (var i = 1; i < l; i++) args[i - 1] = arguments[i];
          handler.apply(this, args);
      }
      return true;

    } else if (isArray(handler)) {
      var l = arguments.length;
      var args = new Array(l - 1);
      for (var i = 1; i < l; i++) args[i - 1] = arguments[i];

      var listeners = handler.slice();
      for (var i = 0, l = listeners.length; i < l; i++) {
        listeners[i].apply(this, args);
      }
      return true;

    } else {
      return false;
    }

  }); 

  OO.addMember("addListener", function(type, listener){
    if ('function' !== typeof listener) {
      throw new Error('addListener only takes instances of Function');
    }

    if (!this._events) this._events = {};

    // To avoid recursion in the case that type == "newListeners"! Before
    // adding it to the listeners, first emit "newListeners".
    this.emit('newListener', type, typeof listener.listener === 'function' ?
              listener.listener : listener);

    if (!this._events[type]) {
      // Optimize the case of one listener. Don't need the extra array object.
      this._events[type] = listener;
    } else if (isArray(this._events[type])) {

      // If we've already got an array, just append.
      this._events[type].push(listener);

    } else {
      // Adding the second element, need to change to array.
      this._events[type] = [this._events[type], listener];

    }

    // Check for listener leak
    if (isArray(this._events[type]) && !this._events[type].warned) {
      var m;
      if (this._maxListeners !== undefined) {
        m = this._maxListeners;
      } else {
        m = defaultMaxListeners;
      }

      if (m && m > 0 && this._events[type].length > m) {
        this._events[type].warned = true;
        console.error('(node) warning: possible EventEmitter memory ' +
                      'leak detected. %d listeners added. ' +
                      'Use emitter.setMaxListeners() to increase limit.',
                      this._events[type].length);
        console.trace();
      }
    }

    return this;
  });

  OO.addMember("once", function(type, listener){
    if ('function' !== typeof listener) {
      throw new Error('.once only takes instances of Function');
    }

    function g() {
      self.removeListener(type, g);
      listener.apply(this, arguments);
    };

    g.listener = listener;
    this.on(type, g);

    return this;
  });

  OO.addMember("removeListener", function(type, listener){
    if ('function' !== typeof listener) {
      throw new Error('removeListener only takes instances of Function');
    }

    // does not use listeners(), so no side effect of creating _events[type]
    if (!this._events || !this._events[type]) return this;

    var list = this._events[type];

    if (isArray(list)) {
      var position = -1;
      for (var i = 0, length = list.length; i < length; i++) {
        if (list[i] === listener ||
            (list[i].listener && list[i].listener === listener))
        {
          position = i;
          break;
        }
      }

      if (position < 0) return this;
      list.splice(position, 1);
      if (list.length == 0)
        delete this._events[type];
    } else if (list === listener ||
               (list.listener && list.listener === listener))
    {
      delete this._events[type];
    }

    return this;
  });

  OO.addMember("removeAllListeners", function(type){
    if (arguments.length === 0) {
      this._events = {};
      return this;
    }

    // does not use listeners(), so no side effect of creating _events[type]
    if (type && this._events && this._events[type]) this._events[type] = null;
    return this;
  });

  OO.addMember("listeners", function(type){
    if (!this._events) this._events = {};
    if (!this._events[type]) this._events[type] = [];
    if (!isArray(this._events[type])) {
      this._events[type] = [this._events[type]];
    }
    return this._events[type];
  });
});

$m.EventEmitter = $m.ROOT.EventEmitter;


  var IDENT  = "[\\$\\w]+";
var TOKENS = [
  [ "SPACE", "\\s+"  ],

  [ "STATIC",   "static\\b" ],
  [ "MODULE",   "module\\b", 'ModuleParser' ],

  [ "EXPORT",   "export\\s+class\\b", 'ClassParser' ],
  [ "PUBLIC",   "public\\s+class\\b", 'ClassParser' ],

  [ "CLASS",    "class\\b",  'ClassParser' ],
  [ "FUNCTION", "function\\b" ],
  [ "INCLUDE",  "include\\b" ],
  [ "VAR",      "var\\b" ],
  [ "PRIVATE",  "private\\b" ],
  [ "EXTENDS",  "extends\\b" ],
  [ "FOREACH",  "foreach\\b", 'ForeachParser' ],

  [ "SHORTHAND_MAPPER",   "#[\\w\\$]+\\s*(?:{|\\()", 'ShorthandMapperParser' ],
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
var RTYPES  = {};

for (var i=0,t=null,_list_0=TOKENS,_len_0=_list_0.length;(t=_list_0[i])||i<_len_0;i++){
  TYPES[t[0]] = i;
  RTYPES[i]   = t[0];
  REGEXES.push("(" + t[1] + ")");
}

var EXTRA_REGEX_STRINGS = {
  ARGS: "\\(\s*(?:" + IDENT + ")?(?:\\s*,\\s*" + IDENT + ")*\s*\\)",
  CLASSNAME: "[\\$\\w\\.]+"
};

var MAIN_REGEX = new RegExp("^" + REGEXES.join('|'));

$m.Class.extend("Tokens", function(KLASS, OO){
  OO.addMember("initialize", function(str){
    this.orig     = str;
    this.str      = str;
    this.iterator = 0;
    this.consumed = 0;
  });

  OO.addMember("peek", function(){
    if (this._peek) return this._peek;

    var m = this.str.match(MAIN_REGEX);
    if (!m) return null;

    for (var i=0,ele=null,_list_0=TOKENS,_len_0=_list_0.length;(ele=_list_0[i])||i<_len_0;i++){
      if (m[i+1]) return this._peek = [ i, m[i+1], ele[2] ];
    }
  });

  OO.addStaticMember("regex", function(str){
    var regexStr = str.replace(/\*\*/g, "\\s*").replace(/\s+/g, "\\s+").replace(/\>\</g, ">\\s*<").replace(/\<(\w+)\>/g, function($1,$2,$3){
      return "(" + (EXTRA_REGEX_STRINGS[$2] || TOKENS[TYPES[$2]][1])  + ")";
    });

    return new RegExp("^" + regexStr);
  });

  OO.addMember("consume", function(n){
    this.str   = this.str.substr(n, this.str.length-n);
    this._peek = null;
    this.consumed += n;
  });

  OO.addMember("length", function(){
    return this.str.length;
  });

  OO.addMember("lookback", function(n){
    var starting = this.consumed - 1;

    //$m.outs(JSON.stringify(this.orig.substr(starting-10, 10)));
    //$m.outs(JSON.stringify(this.orig.charAt(starting)));
    while (this.orig.charAt(starting).match(/\s/)) {
      //$m.outs("back");
      starting--;
    }

    //$m.outs(n + "= " + JSON.stringify(this.orig.substr(starting-n, n)));
    return this.orig.substr(starting-n+1, n);
  });

  OO.addMember("lookahead", function(n){
    var starting = this.consumed;
    while (this.orig.charAt(starting).match(/\s/)) starting++;
    return this.orig.substr(starting, n);
  });


  OO.addMember("any", function(){
    return this.str.length > 0;
  });

  OO.addMember("match", function(regex){
    return this.str.match(regex);
  });
});
var Tokens = $c.Tokens;


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

$m.Class.extend("RootParser", function(KLASS, OO){
  OO.addMember("handlers", {});

  OO.addMember("initialize", function(){
    this.out = [];
    this.finished = false;
  });

  OO.addMember("parse", function(tokens){
    var len = tokens.length();
    if (this.startParse(tokens) === false || this.parseTokens(tokens) === false || this.endParse(tokens) === false) return false
    return len != tokens.length();
  });

  // TODO: messy clean this process up
  OO.addMember("parseTokens", function(tokens){
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
  });

  OO.addMember("startParse", function(){ });
  OO.addMember("endParse", function(){ });

  OO.addMember("handleToken", function(token, tokens){
    this.out.push(token[1]);
    tokens.consume(token[1].length);
  });

  OO.addMember("toString", function(){
    var ret = [];
    for (var i=0; i<this.out.length; i++) {
      var ele = this.out[i];
      ret.push(ele === undefined ? '' : ele.toString());
    }
    return ret.join("");
  });

  OO.addMember("toJSON", function(){
    return JSON.stringify(this.toStruct());
  });

  OO.addMember("pp", function(space){
    space = space == null ? "  " : space + "  ";

    var ret = [ space + (this._TYPE || 'NODE') ];
    var generic = [];
    for (var _i_0=0,ele=null,_list_0=this.out,_len_0=_list_0.length;(ele=_list_0[_i_0])||_i_0<_len_0;_i_0++){
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
  });

  OO.addMember("toStruct", function(){
    var ret = [];
    for (var _i_0=0,ele=null,_list_0=this.out,_len_0=_list_0.length;(ele=_list_0[_i_0])||_i_0<_len_0;_i_0++){
      ret.push(ele.toStruct ? ele.toStruct() : ele);
    }
    return ret;
  });

  // intercepts parser class for special cases
  OO.addMember("getHandler", function(token){
    return null;
  });

  OO.addMember("chop", function(){
    this.out.pop();
  });
});

var RootParser = $c.RootParser;

RootParser.extend("ClassParser", function(KLASS, OO){
  
    var REGEX   = Tokens.regex("(?:<EXPORT>|<PUBLIC>|<CLASS>) <CLASSNAME><LCURLY>");
    var EXTENDS = Tokens.regex("(?:<EXPORT>|<PUBLIC>|<CLASS>) <CLASSNAME><EXTENDS><CLASSNAME><LCURLY>");
  

  OO.addMember("parse", function(tokens){
    var m = tokens.match(REGEX) || tokens.match(EXTENDS);
    var name      = m[4];
    var extending = m[6] || "$m.Class";

    tokens.consume(m[0].length-1);

    var content = new $c.ClassContentParser();
    content.parse(tokens);

    var isPublic  = ($m.PLATFORM == 'node' && m[2] && m[2].indexOf('public') == 0) ? "exports." + name + '=' + name + ';' : '';
    var isExports = ($m.PLATFORM == 'node' && m[1] && m[1].indexOf('export') == 0) ? "module.exports=" + name + ';' : '';

    this.out = [ extending, ".extend(", JSON.stringify(name), ", function(KLASS, OO)", content, ");", isPublic, isExports ];
  });
});

RootParser.extend("ModuleParser", function(KLASS, OO){
  
    var REGEX = Tokens.regex("<MODULE> <CLASSNAME><LCURLY>");
  

  OO.addMember("parse", function(tokens){
    var m = tokens.match(REGEX);
    if (!m) return false;
    var name = m[2];
    tokens.consume(m[0].length-1);

    var content = new $c.ClassContentParser();
    content.parse(tokens);

    this.out = [ "$m.Module.extend(", JSON.stringify(name), ", function(KLASS, OO)", content, ");" ];
  });
});

RootParser.extend("CurlyParser", function(KLASS, OO){
  OO.addMember("_TYPE", 'CurlyParser');

  OO.addMember("initialize", function(chop){
    this.chop = chop;
    this.$super();
  });

  OO.addMember("handleToken", function(token, tokens){
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
  });

  OO.addMember("endParse", function(tokens){
    if (this.chop) {
      this.out.pop();
      this.out.shift();
    }
  });
});

var CurlyParser = $c.CurlyParser;

CurlyParser.extend("ClassContentParser", function(KLASS, OO){
  OO.addMember("getHandler", function(token){
    switch(token[0]) {
      case TYPES.STATIC:   return "StaticParser";
      case TYPES.VAR:      return "MemberParser";
      case TYPES.FUNCTION: return "MethodParser";
      case TYPES.PRIVATE:  return "PrivateParser";
      case TYPES.INCLUDE:  return "IncludeParser";
    }
  });
});

RootParser.extend("LineParser", function(KLASS, OO){
  OO.addMember("handleToken", function(token, tokens){
    this.$super(token, tokens);
    if (token[0] == TYPES.SEMICOLON) {
      this.finished = true;
    }
  });
});

CurlyParser.extend("PrivateParser", function(KLASS, OO){
  
    var REGEX = Tokens.regex("<PRIVATE>\\s*");
  

  OO.addMember("startParse", function(tokens){
    var m = tokens.match(REGEX);
    tokens.consume(m[0].length);
  });

  OO.addMember("endParse", function(tokens){
    this.out.pop();
    this.out.shift();
  });
});


RootParser.extend("IStringParser", function(KLASS, OO){
  
    var BEGIN = Tokens.regex("<ISTRING_START>");
  

  OO.addMember("parse", function(tokens){
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

  OO.addMember("parseMiddle", function(tokens){
    var parser = new $c.CurlyParser(true);
    parser.parse(tokens);
    this.out.push(parser);
  });
});

RootParser.extend("StaticParser", function(KLASS, OO){
  
    var VAR_REGEX = Tokens.regex("(<STATIC>(\\s+))<VAR>");
    var FUNCT_REGEX = Tokens.regex("(<STATIC>(\\s+))<FUNCTION>");
  

  OO.addMember("parseTokens", function(tokens){
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
  });
});

RootParser.extend("MemberParser", function(KLASS, OO){
  
    var REGEX = Tokens.regex("var <IDENT>\\s*=\\s*?");
  

  OO.addMember("parse", function(tokens){
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

var MemberParser = $m.MemberParser;



RootParser.extend("IncludeParser", function(KLASS, OO){
  
    var REGEX = Tokens.regex("<INCLUDE> <CLASSNAME><SEMICOLON>");
  

  OO.addMember("parse", function(tokens){
    var m = tokens.match(REGEX);
    tokens.consume(m[0].length);
    this.out = [ 'OO.include(',  m[2], ');' ];
  });
});

RootParser.extend("HereDocParser", function(KLASS, OO){
  
    var REGEX = Tokens.regex("<HEREDOC>");
  

  OO.addMember("parse", function(tokens){
    var beginning  = tokens.match(/^<<(\w+)(?::(\w+))?\s*([;\)])*\n/);
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
      this.out = [ '$m.JSML.process(', string, ')',  beginning[3] || ';' ];
    } else {
      this.out = [ string, beginning[3] || ';' ];
    }
  });
});

RootParser.extend("MethodParser", function(KLASS, OO){
  
    var REGEX = Tokens.regex("<FUNCTION> <IDENT><ARGS><SPACE>");
  

  OO.addMember("parse", function(tokens){
    var m = tokens.str.match(REGEX);
    tokens.consume(m[0].length);
    var name = m[2];
    var args = m[3];

    var body = new $c.CurlyParser();
    body.parse(tokens);
    body.out[0] = "{var self=this;";

    var addMethod = this.isStatic ? 'addStaticMember' : 'addMember';


    this.out = [ 'OO.' + addMethod + '(', JSON.stringify(name), ', function', args, body, ');' ];
  });
});

RootParser.extend("ShorthandMapperParser", function(KLASS, OO){
  
    var ARGS_REGEX = Tokens.regex("<ARGS>\\s*");
  

  OO.addMember("parse", function(tokens){
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
  });
});

RootParser.extend("ShorthandFunctionParser", function(KLASS, OO){
  
    var ARGS_REGEX = Tokens.regex("<ARGS>\\s*");
  

  OO.addMember("parse", function(tokens){
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
  });
});

RootParser.extend("CommentParser", function(KLASS, OO){
  OO.addMember("parse", function(tokens){
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
  });
});

RootParser.extend("RegexParser", function(KLASS, OO){
  
    var REGEX  = /^\/(\\.|[^\/])+\/[imgy]{0,4}/;
    var DIVIDE = /(\}|\)|\+\+|\-\-|[\w\$])$/;
  

  OO.addMember("parseTokens", function(tokens){
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

  });

});

CurlyParser.extend("ReturnableCurlyParser", function(KLASS, OO){
  OO.addMember("toString", function(){
    var ret = this.$super();
    return ret.replace(/^{(\s*)(return)?/, '{$1return ');
  });
});


CurlyParser.extend("ForeachParser", function(KLASS, OO){
  OO.addMember("_TYPE", 'Foreach');

  
    var REGEX = Tokens.regex("<FOREACH><LBRACE><VAR> <IDENT>(?:**:**<IDENT>)? in (.*?)**<RBRACE>**{");
  

  OO.addMember("startParse", function(tokens){
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
  });

  OO.addMember("endParse", function(tokens){
    tokens.iterator--;
  });

});


$m.Class.extend("CLI", function(KLASS, OO){
  
    var COMMANDS = {
      help:    'help',
      render:  'render',
      compile: 'compile',
      watch:   'watch'
    };
  

  OO.addMember("run", function(args){
    var opts = this.parseOpts(args);
    var options = opts[0];
    var command = opts[1];
    var files   = opts[2];
  });

  OO.addMember("parseOpts", function(args){
    var files   = [];
    var options = {};
    var command = null;

    var endedArgs = false;

    for (var i=0,arg=null,_list_0=args,_len_0=_list_0.length;(arg=_list_0[i])||i<_len_0;i++){
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
