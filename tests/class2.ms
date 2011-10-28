class Proxy {
  function initialize() {
    this.metadata  = new Metadata();
    this.validator = new Validator();
  }

  function listen(port) {
    var self = this;
    this.server = http.createServer(function (req, res) {
      self.handleRequest(request, response);
    });
    this.server.listen(port); 
  }

  function handleRequest(request, response) {
    var params = {};

    var self = this;
    self.metadata.retrieve('viewId', 'apiKey', function (metadata) {
      if (self.validator.isValid(metadata)) {
        self.rewriter.rewrite(metadata, response); 
        self.proxy(request, response);
      } 
    });
  }

  function proxy(request, response) {
    var proxy_request = proxy.request(request.method, request.url, request.headers);

    proxy_request.addListener('response', function (proxy_response) {
      proxy_response.addListener('data', function(chunk) {
        response.write(chunk, 'binary');
      });
      
      proxy_response.addListener('end', function() {
        response.end();
      });

      response.writeHead(proxy_response.statusCode, proxy_response.headers);
    });
  
    request.addListener('data', function(chunk) {
      proxy_request.write(chunk, 'binary');
    });
  
    request.addListener('end', function() {
      proxy_request.end();
    });
  }
}

var module = {};
module.exports = Proxy;
