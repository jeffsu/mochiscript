JS2.fs = new JS2.FileSystem(new JS2.FILE_ADAPTER_CLASS());
JS2.require = function(file) {
  var full = this.fs.expandPath(file + '.js2');
  if (this.fs.isFile(full)) {
    eval(this.render(this.fs.read(full)));
  }
}
