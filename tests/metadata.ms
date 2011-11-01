class Metadata {
  function parseRequest(request) {
    var url = URL.parse(request.url, true);
    var headers = request.headers;

    return {
      headers     : headers,
      queryString : url.search.replace( /^\?/, '')
    };
  }

  function retrieve(request, callback) {
  }
}
