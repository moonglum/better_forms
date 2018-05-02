module ApplicationHelper
  # Render a form object as a form
  #
  # You can provide all options you provide to form_with,
  # and additionally you can choose a layout for your form
  # if you don't want to use the default layout
  def render_form(form_object, layout: :default, **options)
    form_with(model: form_object, **options) do |form|
      form_object.render(form, layout: layout)
    end
  end
end
