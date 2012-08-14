var IDENT  = "[\\$\\w]+";
var TOKENS = [
  [ "SPACE", "\\s+"  ],
  [ "RETURN", "=>", 'ReturnParser' ],

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
  [ "SHORTHAND_FUNCTION", "##?(?:{|\\()", 'ShorthandFunctionParser' ],
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

foreach (var t:i in TOKENS) {
  TYPES[t[0]] = i;
  RTYPES[i]   = t[0];
  REGEXES.push("(" + t[1] + ")");
}

var EXTRA_REGEX_STRINGS = {
  ARGS: "\\(\\s*(?:" + IDENT + ")?(?:\\s*,\\s*" + IDENT + ")*\\s*\\)",
  CLASSNAME: "[\\$\\w\\.]+"
};

var MAIN_REGEX = new RegExp("^" + REGEXES.join('|'));

class Tokens {
  function initialize(str) {
    this.orig     = str;
    this.str      = str;
    this.iterator = 0;
    this.consumed = 0;
  }

  function peek() {
    if (this._peek) return this._peek;

    var m = this.str.match(MAIN_REGEX);
    if (!m) return null;

    foreach (var ele:i in TOKENS) {
      if (m[i+1]) return this._peek = [ i, m[i+1], ele[2] ];
    }
  }

  static function regex(str) {
    var regexStr = str.replace(/\*\*/g, "\\s*").replace(/\s+/g, "\\s+").replace(/\>\</g, ">\\s*<").replace(/\<(\w+)\>/g, #{
      return "(" + (EXTRA_REGEX_STRINGS[$2] || TOKENS[TYPES[$2]][1])  + ")";
    });

    return new RegExp("^" + regexStr);
  }

  function consume(n) {
    this.str   = this.str.substr(n, this.str.length-n);
    this._peek = null;
    this.consumed += n;
  }

  function length() {
    return this.str.length;
  }

  function lookback(n) {
    var starting = this.consumed - 1;

    while (this.orig.charAt(starting).match(/\s/)) {
      starting--;
    }

    return this.orig.substr(starting-n+1, n);
  }

  function lookahead(n) {
    var starting = this.consumed;
    while (this.orig.charAt(starting).match(/\s/)) starting++;
    return this.orig.substr(starting, n);
  }


  function any() {
    return this.str.length > 0;
  }

  function match(regex) {
    return this.str.match(regex);
  }
}
var Tokens = $c.Tokens;
