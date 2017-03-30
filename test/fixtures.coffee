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

class MyModel extends Sirius.BaseModel
  @attrs: ["id", {title: "default title"}, "description"]

  compare: (other) ->
    @.get("id") == other.get("id")


class MyModel0 extends Sirius.BaseModel
  @attrs: ["id", {title: {}}, "description"]

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



class Person extends Sirius.BaseModel
  @attrs: ["id"]
  @has_many : ["group"]
  @has_one : ["name"]


class Group extends Sirius.BaseModel
  @attrs: ["name", "person_id"]
  @belongs_to: [{model: "person", back: "id"}]

class Name extends Sirius.BaseModel
  @attrs: ["name", "person_id"]
  @belongs_to: [{model: "person", back: "id"}]


class UModel extends Sirius.BaseModel
  @attrs: ["id"]
  @guid_for : "id"


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


class ComputedFieldModel extends Sirius.BaseModel
  @attrs: ["first_name", "last_name"]
  @comp("full_name", "first_name", "last_name")
  @comp("full_name1", "first_name", "last_name", (f, l) -> "#{f}-#{l}")
  @comp("full", "full_name", "full_name1")
  @validate :
    full_name:
      length: min: 3, max: 7




class MyTestIndexModel extends Sirius.BaseModel
  @attrs: ["name"]

class MyTestView2ModelSpecModel extends Sirius.BaseModel
  @attrs: ["name"]


class MyTestModel2ViewSpecModel extends Sirius.BaseModel
  @attrs: ["name"]


