class Tokens {
  function initialize(str) {
    this.orig = str;
    this.str  = str;
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
    var regexStr = str.replace(" ", "\\s+").replace("><", ">\\s*<").replace(/\<(\w+)\>/g, #{
      return "(" + (EXTRA_REGEX_STRINGS[$2] || TOKENS[TYPES[$2]][1])  + ")";
    });

    return new RegExp(regexStr);
  }

  function consume(n) {
    this.str   = this.str.substr(n, this.str.length-n);
    this._peek = null;
  }

  function any() {
    return this.str.length > 0;
  }

  function match(regex) {
    return this.str.match(regex);
  }
}
var Tokens = $c.Tokens;
