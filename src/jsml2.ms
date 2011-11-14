var foo = "%fieldset\n  %fields\n  %button{ onclick: \"c.addField(); return false\" } Add Field";
console.log(JSON.stringify($m.JSML.process(foo), null, 2));
console.log($m.JSML.process(foo).result());
