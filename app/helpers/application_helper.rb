module ApplicationHelper
  # Render a form object as a form
  #
  # You can provide all options you provide to form_with
  def render_form(form_object, **options)
    form_with(model: form_object, **options) do |form|
      render(
        form_object,
        errors: form_object.errors,
        model_name: form_object.class.model_name,
        form: form,
        fields: form_object.class.fields
      )
    end
  end
end
