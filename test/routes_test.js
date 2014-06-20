suite("Routing", function() {
  test("RoutePart", function() {
    var r ;
    r = new Sirius.RoutePart("#");
    assert(r.match("#/"));
    assert(!r.match("/abc"));
    assert(r.args.length == 0);


    r = new Sirius.RoutePart("#/*");
    assert(!r.end == true);
    assert(r.match("#/title/id/date/param1/"));
    assert(r.args.length == 4);

    r = new Sirius.RoutePart("#/:title/:id")
    assert(r.end);
    assert(r.match("#/post/1"));
    assert(r.args.length == 2)
    assert(!r.match("#/post/zik/1"));
    assert(r.args.length == 0);

    r = new Sirius.RoutePart("#/title");
    assert(r.end);
    assert(r.match("#/title"));
    assert(!r.match("#/title1"));

    r = new Sirius.RoutePart("#/post/[0-9]+");
    assert(r.match("#/post/190"));
    assert(r.args.length == 1);
    assert(!r.match(("#/post/a90")));
    assert(r.args.length == 0);
    assert(!r.match("#/post/title"));
  });

  test("Routes&Controllers", function() {
    var a = assert;
    window.location.hash = "";
    var Controller = {
      error: function(current) {
        a(current == "#/dsa");
      },
      action: function(e, id, klass) {
        a(id == "my-div");
        a(klass == "abc");
      },
      title: function(title) {
        a(title == "abc");
      }
    };

    var r = {
      "#/" : function() {
        a(arguments.length == 0);
      },
      "#/post/[0-9]+" : function(id) {
        a(arguments.length == 1);
        a(id == "12");
      },
      "#/post/:title" : {controller: Controller, action: "title"},
      "#/post/x/*" : function(){
        a(arguments.length == 3);
      },
      "#/static" : function(){
        a(arguments.length == 0);
      },
      404: {controller: Controller, action: "error"},

      "event:custom" : function(e, p0) {
        a(p0 == 0);
      },
      "click #my-div" : {controller: Controller, action: "action", data: ["id", "class"]}
    };
    var j = new JQueryAdapter();
    Sirius.Application.adapter = j;

    Sirius.RouteSystem.create(r);

    setTimeout(function() {
      window.location.hash = "#/";
    }, 0);
    setTimeout(function() {
      window.location.hash = "#/post/12";
    }, 400);
    setTimeout(function() {
      window.location.hash = "#/post/abc";
    }, 800);
    setTimeout(function() {
      window.location.hash = "#/post/x/a/b/c";
    }, 1200);
    setTimeout(function() {
      window.location.hash = "#/static";
    }, 1600);
    setTimeout(function() {
      window.location.hash = "#/dsa";
    }, 2000);
    setTimeout(function() {
      window.location.hash = "";
    }, 2400);

    j.fire(document, "event:custom", [0]);

    $("#my-div").trigger("click");
  });

});