describe "View2View", ->

  it "failed when draw without 'to'", ->
    input2input = "#input2input"
    v1 = new Sirius.View("#{input2input}")
    v2 = new Sirius.View("#{input2input}")
    expect(() -> v1.bind(v2, {"abc": "sample"})).toThrow()

  it "failed when draw with 'to', but is not array or string", ->
    input2input = "#input2input"
    v1 = new Sirius.View("#{input2input}")
    v2 = new Sirius.View("#{input2input}")
    expect(() -> v1.bind(v2, {"to": {}})).toThrow()

  it "failed when object without 'selector' property", ->
    input2input = "#input2input"
    v1 = new Sirius.View("#{input2input}")
    v2 = new Sirius.View("#{input2input}")
    expect(() -> v1.bind(v2, {"to": [{"non-selector": "#my-id"}]})).toThrow()


