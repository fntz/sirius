
describe "Model To Function Transformation", ->
  it "push attribute changes from model to function", ->
    class Test1 extends Sirius.BaseModel
      @attrs: ["name"]

    tmp = []
    new_name = "new"
    f = (attr, value) ->
      tmp.push(attr, value)

    model = new Test1()
    model.pipe(f)

    model.name(new_name)
    expect(model.name()).toEqual(new_name)
    expect(tmp).toEqual(["name", new_name])

    new_name1 = "boo"
    model.set("name", new_name1)
    expect(model.get('name')).toEqual(new_name1)
    expect(tmp).toEqual(["name", new_name, "name", new_name1])


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
