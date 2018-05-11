class IdeaForm < BaseForm
  text_field :title, required: true
  text_area :body
end
