# TODO: Gem name idea "santana" – Santana::Form
class BaseForm
  class << self
    # Validations that require database access are not available:
    # * validates_associated
    # * uniqueness
    VALIDATIONS = %i[acceptance confirmation exclusion format inclusion length numericality presence absence validates_with].freeze

    attr_reader :fields

    def field(name, type, options = {})
      attr_accessor name

      validations = options.slice(*VALIDATIONS)
      validates name, validations unless validations.empty?

      @fields ||= []
      field_class = type.to_s.camelize.constantize
      @fields.push(field_class.new(name, validations, options.except(*VALIDATIONS)))
    end

    def model_name
      ActiveModel::Name.new(self, nil, name.gsub(/Form\z/, ""))
    end

    def i18n_scope
      :form
    end
  end

  include ActiveModel::AttributeAssignment
  include ActiveModel::Validations
  extend ActiveModel::Translation

  delegate :fields, to: :class

  # Initialize the form, optionally providing a parameter for the form
  #
  # If you form is called FooForm, then the form will post to foo_path
  # If you provide a param, it will post to foo_path(param)
  def initialize(param: nil)
    @param = param
  end

  # Prefill your form with a hash
  #
  # This is useful for update forms
  def prefill_with(attributes)
    assign_attributes(attributes.slice(*fields.map { |field| field.name.to_s }))
  end

  # Apply parameters to your target object or objects
  #
  # This will first clean the parameters and check their validity
  # It will then call the update method, see below
  def apply(dirty_params, to:)
    params = clean_params(dirty_params)
    assign_attributes(params)
    return false unless valid?
    update(to, params)
  end

  # Update the target object or objects
  #
  # In the default case, it will just call update on the target
  # This can be overwritten if you want to update more than just one model
  def update(target, params)
    target.update(params)
  end

  # Render the form (this is called by the render_form helper)
  #
  # You need to provide the name of the view you want to use as
  # the layout for your form
  def render(form, layout:)
    ApplicationController.new.render_to_string(
      "forms/#{layout}",
      locals: {
        errors: errors,
        model_name: self.class.model_name,
        form: form,
        fields: fields
      },
      layout: false
    )
  end

  # This is necessary for form_with
  # This is unfortunately named. It basically asks if the param should be used or not
  def persisted?
    @param.present?
  end

  # This is necessary for form_with
  def to_param
    @param
  end

  # This is necessary for form_with
  def to_model
    self
  end

  private

  def clean_params(params)
    fields.each_with_object({}) do |field, result|
      result[field.name] = field.transform(params[self.class.model_name.param_key])
    end
  end
end

class FormField
  attr_reader :name
  attr_reader :options

  def initialize(name, validations, options)
    @name = name
    @options = options.merge(validations_to_attributes(validations))
  end

  # Can be overwritten by child class for transforming to different type
  # or to collect multiple fields into one value
  def transform(params)
    params[name]
  end

  def to_partial_path
    "forms/#{self.class.name.underscore}"
  end

  private

  # TODO: Add missing validations:
  # acceptance, confirmation, exclusion, format, inclusion, length, numericality, absence
  def validations_to_attributes(validations)
    options = {}
    options[:required] = true if validations[:presence]
    options
  end
end

class TextField < FormField
end

class TextArea < FormField
end
