var IDENT  = "[\\$\\w]+";
var TOKENS = [
  [ "SPACE", "\\s+"  ],

  [ "CLASS",    "class", 'ClassParser' ], 
  [ "FUNCTION", "function\\b" ], 
  [ "VAR",      "var\\b" ], 
  [ "STATIC",   "static\\b" ], 
  [ "PRIVATE",  "private\\b" ], 
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

foreach (var t:i in TOKENS) {
  TYPES[t[0]] = i; 
  REGEXES.push("(" + t[1] + ")");
}

var EXTRA_REGEX_STRINGS = {
  ARGS: "\\(\s*(?:" + IDENT + ")?(?:\\s*,\\s*" + IDENT + ")*\s*\\)"
};

var MAIN_REGEX = new RegExp("^" + REGEXES.join('|'));

$m.parse = function (str) {
  var parser = new $c.RootParser();
  parser.parse(new $c.Tokens(str));
  return parser.toString();
};
