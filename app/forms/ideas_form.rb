class IdeasForm < BaseForm
  model Idea

  # TODO: validates :title, presence: true

  # TODO: The required flag should add the validation automatically
  field :title, :text_field, required: true
  field :body, :text_area
end
