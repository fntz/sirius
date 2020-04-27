
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

    Sirius.Materializer.build(todo, todo_view)
      .field((m) -> m.completed)
        .to("input[type='checkbox']")
        .handle((view, result) ->
          view.render(result).swap('checked')
        )
      .field((m) -> m.title)
        .to("label")
      .run()

    Sirius.Materializer.build(todo_view, todo)
      .field((v) -> v.zoom("input[type='checkbox']"))
        .to((m) -> m.completed)
        .transform((r) -> r.state)
     .field((v) -> v.zoom("input.edit"))
        .to((m) -> m.title)
        .transform((r) -> r.text).run()

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