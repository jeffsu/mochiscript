//var crypto = require('crypto');
//var qs     = require('querystring');
//var url    = require('url');

//var ApiError = require('./errormessage').ApiError;

//var secretLookup  = {};

class OAuth {
  function getResponse(metadata, request) {
    return { passed: true };
    var headers = this.parseHeaders(request);

    var oauthKey       = this.oauthHeaders['oauth_consumer_key'];
    var oauthSignature = this.oauthHeaders['oauth_signature'];
    var oauthMethod    = this.oauthHeaders['oauth_signature_method'];

    var ret = {};

    if (oauthKey) {
      ret.useOAuth = true;
      ret.passed   = this.verifySignature(oauthMethod, oauthKey, oauthSignature, request);
    }
  }

/*
  function verifySignature(method, oauthKey, signature, $r) {
    var storedSecret = secretLookup[oauthKey];
    if (!storedSecret) {
      console.log('oauth key fist hit, pass');
      return true;
    }

    var verified = this.verify($r, storedSecret, signature, method);
    return verified;
  }

  function verify($r, consumer_secret, signature, method) {
    if (method == 'PLAINTEXT') {
      return (signature == consumer_secret);

    } else if (method == 'HMAC-SHA1') {
      secret = consumer_secret + '&';
      var hmac = crypto.createHmac('sha1', secret);
      var baseString = this.baseString($r);
      hmac.update(baseString);

      var digest = hmac.digest('base64');
      return (signature == digest);
    } else {
      return false;
    }
  }

  function uriEscape(str) {
    // fixing nodejs bug
    return qs.escape(str.replace("'", "%27"));
  };

  function baseString($r) {
    var req = $r.frontend.request;

    var reqMethod     = req.method.toUpperCase();
    var baseStringURI = this.uriEscape(this.oauthBaseStringURI(req));
    var paramsString  = this.uriEscape(this.oauthParamsString($r));

    return [reqMethod, baseStringURI, paramsString].join('&');
  }

  function oauthBaseStringURI(req) {
    var scheme   = req.connection.verifyPeer != undefined ? 'https' : 'http';
    var hostname = req.headers['host'].split(':')[0].toLowerCase();
    var port     = parseInt(req.headers['host'].split(':')[1], 10);

    if ((!isNaN(port))
        && (scheme != 'http' || port != 80)
        && (scheme != 'https' || port != 443))
      hostname = hostname + ':' + port;

    var pathname = url.parse(req.url).pathname;
    return scheme + "://" + hostname + pathname;
  }

  function oauthParamsString($r) {
    var req = $r.frontend.request;
    var params = [];

    // Add encoded counterparts of query string parameters
    for (var key in $r.url.query)
      if (key != 'oauth_signature')
        params.push([ qs.escape(key), qs.escape($r.url.query[key]) ]);

    // Add encoded counterparts of OAuth header parameters
    for (var key in this.oauthHeaders)
    if (key.match(/^oauth_/)
          && key != 'oauth_signature')
        params.push([ qs.escape(key), qs.escape(this.oauthHeaders[key]) ]);

    // Add encoded counterparts of body parameters
    if (req.method == 'POST')
      for (var key in req.body)
        if (key != 'oauth_signature')
          params.push([ qs.escape(key), qs.escape(req.body[key]) ]);

    params.sort();

    var paramString = "";
    for (var i = 0; i < params.length; i++)
      paramString += (paramString ? '&' : '') + params[i][0] + '=' + params[i][1];

    return paramString;
  }

  function parseHeaders(req) {
    var oauthHeaders = {};

    for (var key in req.query) {
       if (key.match(/^oauth_/)) {
         oauthHeaders[key] = req.query[key];
       }
    }

    for (var key in req.body) {
       if (key.match(/^oauth_/)) {
         oauthHeaders[key] = req.query[key];
       }
    }

    var authHeader = req.headers['authorization'];
    if (authHeader && authHeader.match(/^OAuth\b/i)) {
      var params = authHeader.match(/[^=\s]+="[^"]*"(?:,\s*)?/g);
      for (var i=0; i < params.length; i++) {
        var match = params[i].match(/([^=\s]+)="([^"]*)"/);
        var key   = qs.unescape(match[1]);
        var value = qs.unescape(match[2]);
        oauthHeaders[key] = value;
      }
    }

    return oauthHeaders;
  }

  function post($r) {
    this.saveSecretLookup($r);
  }

  function saveSecretLookup($r) {
    var headers   = $r.backend.response.headers;
    var oauthKey  = headers['x-factual-oauth-key'];
    var oauthSecret = headers['x-factual-oauth-secret'];
    if (oauthKey && oauthSecret) {
      secretLookup[oauthKey] = oauthSecret;

      $r.state.oauthKey    = oauthKey;
      $r.state.oauthSecret = oauthSecret;
    }
  }
  */
}
