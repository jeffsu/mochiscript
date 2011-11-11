var foo = <<END:jsml;
%div hello world
END

$m.test(#(assert){
  assert.eq('<div>hello world</div>', foo.result());
});
