module ApplicationHelper
  def render_form(form_object, options = {})
    form_with(model: form_object, **options) do |form|
      form_object.to_html(form)
    end
  end
end
