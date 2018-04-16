class BaseForm
  class << self
    attr_reader :fields

    def field(name, type)
      @fields ||= []
      @fields.push(
        name: name,
        type: type
      )
    end

    def cleanup(params)
      form_name = name.tableize.gsub(/_forms$/, "").singularize.to_sym
      field_names = @fields.map { |field| field.fetch(:name) }
      params.require(form_name).permit(*field_names)
    end
  end

  include ActionView::Helpers::FormHelper

  attr_reader :model
  attr_reader :request_forgery_protection_token
  attr_reader :form_authenticity_token
  attr_accessor :output_buffer

  def initialize(model, request_forgery_protection_token, form_authenticity_token)
    @model = model
    @output_buffer = nil
    @request_forgery_protection_token = request_forgery_protection_token
    @form_authenticity_token = form_authenticity_token
  end

  # TODO: ActionView::Helpers::TagHelper
  def to_html(url)
    form_for(model, url: url, authenticity_token: form_authenticity_token) do |form|
      # TODO: Display errors

      # Fields
      self.class.fields.each do |field|
        @output_buffer << "<div class='field'>".html_safe
        @output_buffer << form.label(field.fetch(:name))
        @output_buffer << form.public_send(field.fetch(:type), field.fetch(:name))
        @output_buffer << "</div>".html_safe
      end

      # Actions
      @output_buffer << "<div class='actions'>".html_safe
      @output_buffer << form.submit
      @output_buffer << "</div>".html_safe
    end
  end

  def protect_against_forgery?
    true
  end
end
