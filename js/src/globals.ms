var TOKENS = [
  [ "SPACE",    "\s+" ],
  [ "CLASS",    "class" ], 
  [ "IDENT",    "[\\$\\w]+" ], 
  [ "OPERATOR", "\\+|\\-|\\++" ]
];

var TYPES   = {};
var REGEXES = [];
var MAIN_REGEX = null;

foreach (var t:i in TOKENS) {
  TYPES[t[0]] = i + 1; 
  REGEXES.push("(" + t[1] + ")");
}

var MAIN_REGEX = new RegExp("^" + REGEXES.join('|'));
var parsers    = null;

$m.parse = function (str) {
  loadParsers();
  var tokens = new Tokens(str);
  return parsers.root.parse(tokens);
};
