class IdeaForm < BaseForm
  text_field :title, validates: { presence: true }
  text_area :body
end
