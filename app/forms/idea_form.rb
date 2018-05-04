class IdeaForm < BaseForm
  # Maybe nicer? text_field :title, validates: { presence: true }
  field :title, :text_field, validates: {
    presence: true
  }
  field :body, :text_area
end
