suite("ControlFlow", function() {
  test("params guards", function() {
    var params, cf;

    params = {
      controller: Controller0,
      action: "action"
    };
    cf = new ControlFlow(params);
    assert(cf.action == Controller0.action);
    assert(cf.before == Controller0.before_action);
    assert(cf.after == Controller0.after_action)

    params = {
      controller: Controller0,
      action: "action0"
    };
    cf = new ControlFlow(params);
    assert(cf.action == Controller0.action0);
    assert(cf.before);
    assert(cf.after);

    params = {
      controller: Controller0,
      action: "action1",
      before: "before_action1"
    };
    cf = new ControlFlow(params);
    assert(cf.action == Controller0.action1);
    assert(cf.before == Controller0.before_action1);

    params = {
      controller: Controller0,
      action: "action1",
      before: function() {return 1;}
    };
    var cf = new ControlFlow(params);
    assert(cf.action == Controller0.action1);
    assert(cf.before() == 1);

    params = {
      controller: Controller0,
      action: "action1",
      before: 1
    };
    assert.throw(function(){ new ControlFlow(params); });
    assert.throw(function(){ new ControlFlow({}); });
    assert.throw(function(){ new ControlFlow({controller: Controller0, action: "some-action"}); });
  });
});