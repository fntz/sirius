class MyModel extends BaseModel
  @attrs: ["id", {title: "default title"}, "description"]
  @to:
    id          : tag: "b", class: 'my-model-id'
    title       : tag: "span", class: "my-model-title"
    description : class: "description"

class ModelwithValidators extends BaseModel
  @attrs: ["id", {title: "t"}, "description"]
  @validate :
    id:
      presence: true,
      numericality: only_integers: true
      inclusion: within: [1..10]

    title:
      presence: true
      format: with: /^[A-Z].+/
      length: min: 3, max: 7
      exclusion: ["title"]