(function ($m) {
  var TOKENS = [
    [ "KEYWORD",  "class|module" ], 
    [ "OPERATOR", "\\+|\\-|\\++" ],
    [ "IDENT",    "\\d+|[\\$\\w]+" ],
  ];

  var IDS = {};
  var TOKEN_REGEX = TOKENS.collect { 

  class Tokenizer {
    static tokenize(str) {
      var m = str.match(TOKEN_REGEX);
    }
  }

})($m);
