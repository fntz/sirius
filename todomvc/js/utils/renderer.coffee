
Renderer =
  todo_template: () -> ejs.compile(Template.todo_template)

  view: new Sirius.View(HtmlElements.todo_list)
  clear_view: new Sirius.View(HtmlElements.clear_completed, (size) -> "Clear completed (#{size})")

  render: (todo_list) ->
    @view.render().clear()
    for todo in todo_list
      @append(todo)

  append: (todo) ->

    template = @todo_template()({todo: todo})

    @view.render(template).append()
    id = "\##{todo.id()}"

    todo_view = new Sirius.View(id)
    to_view_transformer = Sirius.Transformer.draw({
      'completed': {
        to: "input[type='checkbox']",
        via: (value, selector, view, attribute) ->
          view.zoom(selector).render(value).swap('checked')
      },
      'title': {
        to: 'label'
      }
    })
    todo.bind(todo_view, to_view_transformer)

    to_model_transformer = Sirius.Transformer.draw({
      "input[type='checkbox']": {
        to: 'completed',
        from: 'checked',
        via: (value, view, selector, attribute) ->
          view.zoom(selector).get_attr(attribute)
      },
      "input.edit": {
        to: 'title'
      }
    })
    todo_view.bind(todo, to_model_transformer)

    todo_view.on('div', 'dblclick', (x) ->
      todo_view.render('editing').swap('class')
    )
    todo_view.on('input.edit', 'keypress', (x) ->
      if x.keyCode == 13
        todo_view.render("").swap('class')
    )

    Utils.fire()

    return

  clear: (size) ->
    if size != 0
      @clear_view.render(size).swap()
    else
      @clear_view.render().clear()