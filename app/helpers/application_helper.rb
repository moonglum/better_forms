module ApplicationHelper
  # Render a form object as a form
  #
  # You can provide all options you provide to form_with
  def render_form(form_object, **options)
    form_with(model: form_object, **options) do |form|
      render(partial: form_object, as: :form_object, locals: { form: form })
    end
  end
end
