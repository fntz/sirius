
suite("Colleciton", function() {
  test("base methods", function(){
    var m = new MyModel({"id": 10});
    var assert1 = assert;
    var assert2 = assert;
    var monitor = false;
    var options = {
      on_add: function(model) {
        if (!monitor) {
          assert1(model.get("id") == 10);
          monitor = true;
        }
      },
      on_remove: function(model) {
        assert2(model.get("id") == 10);
      }
    };

    var mc = new Sirius.Collection(MyModel, [], options);

    assert(mc.size() == 0);
    assert(mc.find("id", 10) == null);
    assert(mc.find_all("id", 10).length == 0);

    mc.add(m);

    assert(mc.size() == 1);
    assert(mc.find("id", 10) == m);

    mc.push(new MyModel({"id": 100}));

    assert(mc.size() == 2);
    assert(mc.find("id", 10) == m);
    assert(mc.find_all("id", 100).length == 1);

    assert(mc.index(m) == 0);
    assert(mc.filter(function(m) { return m.get("id") > 1; }).length == 2);
    assert(mc.filter(function(m) { return m.get("id") > 10; }).length == 1);

    assert(mc.last().get("id") == 100);
    mc.remove(m);

  });
  test("sync", function() {

  });
});