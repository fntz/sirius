
BottomController =
  length_view: new Sirius.View(HtmlElements.todo_count)
  footer: new Sirius.View(HtmlElements.footer)

  change: (ev) ->
    if TodoList.size() == 0
      @footer.render("hidden").swap("class")
    else
      @footer.render("").swap("class")

    items = TodoList.filter((t) -> t.is_completed()).length
    @length_view.zoom("strong").render(items).swap()

    Renderer.clear(TodoList.filter((t) -> t.is_completed()).length)


  clear: () ->
    TodoList.filter((t) -> t.is_completed()).map((t) -> TodoList.remove(t))
    @change()
