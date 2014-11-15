describe "ControlFlow", ->

  it "Params Guards", ->
    params =
      controller: Controller0
      action    : "action"

#    cf = new Sirius.ControlFlow(params)
#
#    expect(cf.action).toEqual(Controller0.action)
#    expect(cf.before()).toEqual("before")
#
#    params =
#      controller: Controller0
#      action    : "action1"
#      before    : () -> 1
#
#    cf = new Sirius.ControlFlow(params)
#
#    expect(cf.before()).toEqual(1)
#
#    params =
#      controller: Controller0
#      action    : "action1"
#      before    : 1
#
#    expect(() ->
#      new Sirius.ControlFlow(params)
#    ).toThrow()
#
#    global = 1
#    given  = null
#
#    params =
#      controller: Controller0
#      action    : "action1"
#      before    : () -> global = 10
#      guard     : (g) ->
#        given = g
#        false
#
#    cf = new Sirius.ControlFlow(params)
#
#    expect(cf.guard()).toBeFalsy()
#
#    cf.handle_event(null, "abc")
#
#    expect(global).toEqual(1)
#    expect(given).toEqual("abc")
#
#    expect(() -> new Sirius.ControlFlow()).toThrow()

    params =
      controller: Controller0,
      action    : "some-action"

    expect(() -> new Sirius.ControlFlow(params)).toThrow()











