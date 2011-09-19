var TOKENS = [
  [ "SPACE",    "\\s+"  ],
  [ "CLASS",    "class", 'ClassParser' ], 
  [ "IDENT",    "[\\$\\w]+" ], 
  [ "OPERATOR", "\\+|\\-|\\++" ],
  [ "LCURLY",   "\\{" ],
  [ "RCURLY",   "\\}" ]
];

var $c      = $m.ROOT;
var TYPES   = {};
var REGEXES = [];
var MAIN_REGEX = null;

foreach (var t:i in TOKENS) {
  TYPES[t[0]] = i; 
  REGEXES.push("(" + t[1] + ")");
}

var MAIN_REGEX = new RegExp("^" + REGEXES.join('|'));

$m.parse = function (str) {
  var parser = new $c.RootParser();
  parser.parse(new $c.Tokens(str));
  return parser.toString();
};
