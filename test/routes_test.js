suite("Routing", function() {
  test("RoutePart", function() {
    var r ;
    r = new RoutePart("#");
    assert(r.match("#/"));
    assert(!r.match("/abc"));
    assert(r.args.length == 0);


    r = new RoutePart("#/*");
    assert(!r.end == true);
    assert(r.match("#/title/id/date/param1/"));
    assert(r.args.length == 4);

    r = new RoutePart("#/:title/:id")
    assert(r.end);
    assert(r.match("#/post/1"));
    assert(r.args.length == 2)
    assert(!r.match("#/post/zik/1"));
    assert(r.args.length == 0);

    r = new RoutePart("#/title");
    assert(r.end);
    assert(r.match("#/title"));
    assert(!r.match("#/title1"));

    r = new RoutePart("#/post/[0-9]+");
    assert(r.match("#/post/190"));
    assert(r.args.length == 1);
    assert(!r.match(("#/post/a90")));
    assert(r.args.length == 0);
    assert(!r.match("#/post/title"));
  });
});