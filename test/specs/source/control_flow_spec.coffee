describe "ControlFlow", ->

  R = Sirius.Internal.RouteSystem

  TestController =
    before_action: () ->
      "before"
    after_action: () ->
      "after"

    action: () ->
      "action"

    action0: () ->
      "action0"

    before_action1: () ->
      "before1"

    action1 : () ->
      "action1"

    not_a_fun: "test"

  it "check required arguments", ->
    expect(() ->
      new Sirius.Internal.ControlFlow({})
    ).toThrowError("Params must contain a Controller definition")

    expect(() ->
      new Sirius.Internal.ControlFlow({
        controller: TestController,
        action: 1
      })
    ).toThrowError("Action must be a string or a function")

    expect(() ->
      new Sirius.Internal.ControlFlow({
        controller: TestController,
        action: "foo_bar_baz"
      })
    ).toThrowError(/The action 'foo_bar_baz' was not found in the controller/)

    expect(() ->
      TestController1 =
        test: () -> "asd"
        before_test: 1

      new Sirius.Internal.ControlFlow({
        controller: TestController1,
        action: "test"
      })
    ).toThrowError("The Before method must be a string or a function")

    expect(() ->
      TestController1 =
        test: () -> "asd"

      new Sirius.Internal.ControlFlow({
        controller: TestController1,
        action: "test"
        before: "before"
      })
    ).toThrowError("The Before method must be a string or a function")

    expect(() -> new Sirius.Internal.ControlFlow()).toThrow()

    expect(() ->
      new Sirius.Internal.ControlFlow({
        controller: TestController,
        action: "action"
        guard: "not_a_fun"
      })
    ).toThrowError("The Guard method must be a string or a function")

  it "Params Guards", ->
    params =
      controller: TestController
      action    : "action"

    cf = new Sirius.Internal.ControlFlow(params)

    expect(cf.action).toEqual(TestController.action)
    expect(cf.before()).toEqual("before")
    expect(cf.after()).toEqual("after")

    params =
      controller: TestController
      action    : "action1"
      before    : () -> 1

    cf = new Sirius.Internal.ControlFlow(params)

    expect(cf.before()).toEqual(1)

    global = 1
    given  = null

    params =
      controller: TestController
      action    : "action1"
      before    : () ->
        global = 10
      guard     : (g) ->
        given = g
        false

    cf = new Sirius.Internal.ControlFlow(params)

    expect(cf.guard()).toBeFalse()

    cf.handle_event(null, "abc")

    expect(global).toEqual(1)
    expect(given).toEqual("abc")

  describe "helpers", ->
    it "is a hash route", ->
      expect(R._is_hash_route("#test")).toBeTrue()
      expect(R._is_hash_route("/test")).toBeFalse()

    it "is a plain route", ->
      expect(R._is_plain_route("/test")).toBeTrue()
      expect(R._is_plain_route("#test")).toBeFalse()

  describe "scheduler", ->
    it "is scheduler route", ->
      expect(R._is_scheduler_command("every 1m")).toBeTruthy()
      expect(R._is_scheduler_command("once 1m")).toBeTruthy()
      expect(R._is_scheduler_command("scheduler 1m")).toBeTruthy()
      expect(R._is_scheduler_command("every 1m 10s")).toBeTruthy()
      expect(R._is_scheduler_command("once 1m 300ms")).toBeTruthy()
      expect(R._is_scheduler_command("scheduler 1m 400s")).toBeTruthy()


    it "parse time units correctly", ->
      expect(R._get_time_unit("every 10s", "10s")).toEqual(10*1000)
      expect(R._get_time_unit("once 33ms", "33ms")).toEqual(33)
      expect(R._get_time_unit("scheduler 16m", "16m")).toEqual(16*60000)

    it "return params for scheduler from url", ->
      r = R._get_scheduler_params("every 10s")
      expect(r.delay).toBeNull()
      expect(r.time).toEqual(10*1000)

      r1 = R._get_scheduler_params("once 10s 25m")
      expect(r1.delay).toEqual(10*1000)
      expect(r1.time).toEqual(25*60000)

      r2 = R._get_scheduler_params("scheduler 30ms 1s")
      expect(r2.delay).toEqual(30)
      expect(r2.time).toEqual(1000)

    it "failed with bad time units", ->
      expect(() -> R._get_time_unit("every 10h", "10h")).toThrow()

    it "failed when too long scheduler definition", ->
      expect(() -> R._get_scheduler_params("scheduler 30 ms 1s")).toThrow()










