suite("ControlFlow", function() {
  test("params guards", function() {
    var params, cf;

    params = {
      controller: Controller0,
      action: "action"
    };
    cf = new Sirius.ControlFlow(params);
    assert(cf.action == Controller0.action);
    assert(cf.before == Controller0.before_action);
    assert(cf.after == Controller0.after_action)

    params = {
      controller: Controller0,
      action: "action0"
    };
    cf = new Sirius.ControlFlow(params);
    assert(cf.action == Controller0.action0);
    assert(cf.before);
    assert(cf.after);

    params = {
      controller: Controller0,
      action: "action1",
      before: "before_action1"
    };
    cf = new Sirius.ControlFlow(params);
    assert(cf.action == Controller0.action1);
    assert(cf.before == Controller0.before_action1);

    params = {
      controller: Controller0,
      action: "action1",
      before: function() {return 1;}
    };
    var cf = new Sirius.ControlFlow(params);
    assert(cf.action == Controller0.action1);
    assert(cf.before() == 1);

    params = {
      controller: Controller0,
      action: "action1",
      before: 1
    };

    assert.throw(function(){ new Sirius.ControlFlow(params); });

    var global = 1, given = null;
    params = {
      controller: Controller0,
      action: "action1",
      before: function() {
        global = 10;
      },
      guard: function(g) {
        given = g;
        return false;
      }
    };

    cf = new Sirius.ControlFlow(params);
    assert(cf.guard);
    assert(!cf.guard());

    cf.handle_event(null, "abc");

    assert(global == 1);
    assert(given == "abc");

    assert.throw(function(){ new Sirius.ControlFlow({}); });
    assert.throw(function(){ new Sirius.ControlFlow({controller: Controller0, action: "some-action"}); });
  });
});