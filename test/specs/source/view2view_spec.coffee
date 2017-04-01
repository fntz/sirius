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


  it "input text to view input text", ->
    input = "#input2input"
    v1 = new Sirius.View("#{input}")
    v2 = new Sirius.View("#{input}")
    e2 = "input[name='input-2']"
    p = Sirius.Transformer.draw({
      to: "#{e2}"
    })

    v1.bind(v2, p)

    # emulate event
    t = "input2input"
    v1._listeners[0]('text', t)
    expect(get_value(e2)).toEqual(t)


  it "input text to view attribute", ->
    input = "#input2attribute"
    v1 = new Sirius.View("#{input}")
    v2 = new Sirius.View("#{input}")
    e2 = "input[name='input-2']"
    p = Sirius.Transformer.draw({
      to: [
        {
          selector: "#{e2}",
          attribute: 'data-name'
        }
      ]
    })

    v1.bind(v2, p)

    # emulate event
    t = "abc"
    v1._listeners[0]('data-name', t)
    expect(adapter.get_attr("#{input} #{e2}", 'data-name')).toEqual(t)

  it "attribute to view attribute", ->
    input = "#attribute2attribute"
    v1 = new Sirius.View("#{input}")
    v2 = new Sirius.View("#{input}")
    e2 = "input[name='input-2']"
    p = Sirius.Transformer.draw({
      to: [
        {
          selector: "#{e2}",
          attribute: 'data-attr'
        }
      ],
      'from': 'data-attr'
    })

    v1.bind(v2, p)

    # emulate event
    t = "abc"
    v1._listeners[0]('data-attr', t)
    expect(adapter.get_attr("#{input} #{e2}", 'data-attr')).toEqual(t)

  it "attribute to view input text", ->
    input = "#attribute2text"
    v1 = new Sirius.View("#{input}")
    v2 = new Sirius.View("#{input}")
    e2 = "input[name='input-2']"
    p = Sirius.Transformer.draw({
      to: [
        {
          selector: "#{e2}"
        }
      ],
      'from': 'data-attr'
    })

    v1.bind(v2, p)

    # emulate event
    t = "bar"
    v1._listeners[0]('data-attr', t)
    expect(adapter.get("#{input} #{e2}").value).toEqual(t)
