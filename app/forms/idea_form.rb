class IdeaForm < BaseForm
  field :title, :text_field, presence: true
  field :body, :text_area
end
