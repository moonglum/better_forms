module ApplicationHelper
  def better_form_for(form_object, options = {})
    form_with(model: form_object.model, **options) do |form|
      output_buffer = ActiveSupport::SafeBuffer.new

      # TODO: Display errors

      # Fields
      form_object.fields.each do |field|
        output_buffer.concat(
          content_tag(:div, class: "field") do
            form.label(field.fetch(:name))
              .concat(form.public_send(field.fetch(:type), field.fetch(:name)))
          end
        )
      end

      # Actions
      output_buffer.concat(content_tag(:div, class: "actions") do
        form.submit
      end)

      output_buffer
    end
  end
end
