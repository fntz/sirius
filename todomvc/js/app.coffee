
"use strict"

TodoList = new Sirius.Collection(Task)

TodoList.subscribe('add', (todo) -> Renderer.append(todo))
TodoList.subscribe('remove', (todo) -> $("\##{todo.id()}").remove())


# ----------------------- Routing ----------------- #

routes =
  '#/'               : {controller: MainController, action: 'root'}
  '#/active'        :  {controller: MainController, action: 'active'}
  '#/completed'     :  {controller: MainController, action: 'completed'}
  'application:run' : {controller: MainController, action: 'start'}
  'todo:create' :     {controller: TodoController, action: 'create', guard: 'is_enter', after: 'clear_input'}
  'application:urlchange': {controller: LinkController, action: 'url'}
  'click #toggle-all'     : {controller: TodoController, action: 'mark_all', data: 'class'}
  'collection:change' : {controller: AdditionalInfoController, action: 'change'}
  'click button.destroy'  : {controller: TodoController, action: 'destroy', data: 'data-id'}
  'click #clear-completed': {controller: AdditionalInfoController, action: 'clear'}

# ----------------------- Start -------------------- #

$ ->
  options =
    route   : routes
    adapter : new JQueryAdapter()
    enable_logging: true

  Sirius.Application.run options

