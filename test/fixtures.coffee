adapter = if JQueryAdapter?
    new JQueryAdapter()
  else if PrototypeAdapter?
    new PrototypeAdapter()
  else
    new VanillaJsAdapter()

Sirius.Application.adapter = adapter

get_text = (element) ->
  adapter.text(element)

set_value = (element, text) ->
  if JQueryAdapter?
    jQuery(element).val(text)
  else
    document.querySelector(element).value = text

set_check = (element, bool) ->
  document.querySelector(element).checked = bool

get_attr = (element, attr) ->
  adapter.get_attr(element, attr)

get_value = (element) ->
  document.querySelector(element).value

set_text = (element, text) ->
  if JQueryAdapter?
    jQuery(element).text(text)
  else
    e = adapter.get(element)
    if e.textContent
      e.textContent = text
    else
      e.innerHTML = text
  return

input_text = (element, value) ->
  set_value(element, value)

  _element = document.querySelector(element)

  event = new Event('input', {
    'bubbles': true,
    'cancelable': true
  })

  _element.dispatchEvent(event)

check_element = (element, should_be_checked) ->
  set_check(element, should_be_checked)

  _element = document.querySelector(element)

  event = new Event('change', {
    'bubbles': true,
    'cancelable': true
  })

  _element.dispatchEvent(event)

class MyModel extends Sirius.BaseModel
  @attrs: ["id", {title: "default title"}, "description"]

  compare: (other) ->
    @.get("id") == other.get("id")


class MyModel0 extends Sirius.BaseModel
  @attrs: ["id", {title: {}}, "description"]


class MyModelSkipFalse extends Sirius.BaseModel
  @attrs: ["id"]

class MyModelSkipTrue extends Sirius.BaseModel
  @attrs: ["id"]
  @skip: true

class MyCustomValidator extends Sirius.Validator
  validate: (value, attrs) ->
    if value?
      if value.length == 3
        true
      else
        @msg = "Value length must be 3"
        false
    else
      @msg = "Null given"
      false

Sirius.BaseModel.register_validator('custom', MyCustomValidator)

class ModelwithValidators extends Sirius.BaseModel
  @attrs: ["id", "title", "description"]
  @validate :
    id:
      presence: true,
      numericality: only_integers: true
      inclusion: within: [1..10]
      validate_with:  (value) ->
        #@msg = ....
        true

    title:
      presence: true
      format: with: /^[A-Z].+/
      length: min: 3, max: 7
      exclusion: within: ["Title"]

    description:
      custom: true
      validate_with: (desc) ->
        if desc == "foo"
          true
        else
          @msg = "Description must be foo"
          false



class TodoList extends Sirius.BaseModel
  @attrs: ["title", {completed: {}}, "id"]
  @guid_for : "id"
  is_active: () ->
    !@completed()

  is_completed: () ->
    @completed()

#### controllers #######

Controller0 =
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

class SkipFieldsModel extends Sirius.BaseModel
  @attrs: ["id"]
  @skip : true


class MyTestIndexModel extends Sirius.BaseModel
  @attrs: ["name"]

class MyTestView2ModelSpecModel extends Sirius.BaseModel
  @attrs: ["name"]


class MyTestModel2ViewSpecModel extends Sirius.BaseModel
  @attrs: ["name"]

class MyTestModel2FunctionSpecModel extends Sirius.BaseModel
  @attrs: ["name"]