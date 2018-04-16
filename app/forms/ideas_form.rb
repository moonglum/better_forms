class IdeasForm < BaseForm
  model Idea

  field :title, :text_field
  field :body, :text_area
end
