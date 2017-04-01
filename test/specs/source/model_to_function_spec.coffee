describe "Model or View To Function", ->
  it "push attribute changes from model to function", ->
    _tmp_attr = null
    _tmp_value = null
    t = "new"
    f = (attr, value) ->
      _tmp_attr = attr
      _tmp_value = value

    model = new MyTestModel2FunctionSpecModel()
    model.pipe(f)

    model.name(t)
    expect(model.name()).toEqual(t)
    expect(_tmp_attr).toEqual("name")
    expect(_tmp_value).toEqual(t)

  it "failed when 'from' is not present", ->
    element = "#view2function"
    f = "input[name='email']"
    view = new Sirius.View(element)
    func = () -> 1
    pipe = {"selector": {}}
    expect(() -> view.pipe(func, pipe)).toThrow()

  it "push changes from view to function", ->
    element = "#view2function"
    f = "input[name='email']"
    view = new Sirius.View(element)
    need = null
    func = (result, view, logger) ->
      need = result['text']

    pipe = Sirius.Transformer.draw({
      "#{f}": {
        from: 'text'
      }
    })
    view.pipe(func, pipe)
    t = "baz"
    input_text("#{element} #{f}", t)

    expect(need).toEqual(t)
