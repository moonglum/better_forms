# TODO: Gem name idea "santana" – Santana::Form
class BaseForm
  class << self
    attr_reader :fields

    def method_missing(method_name, *args)
      if respond_to_missing?(method_name)
        add_field(method_name, *args)
      else
        super
      end
    end

    def respond_to_missing?(field_type, _include_all = nil)
      FormField.key?(field_type)
    end

    # This is basically the name of the resource
    # We remove the Form from that name
    def model_name
      ActiveModel::Name.new(self, nil, name.gsub(/Form\z/, ""))
    end

    def i18n_scope
      :form
    end

    private

    def add_field(field_type, name, options = {})
      field_class = FormField.fetch(field_type)
      field = field_class.new(name, options)

      field.each_parameter do |parameter, type, validations|
        attribute parameter, type
        validates parameter, validations if validations.any?
      end

      @fields ||= []
      @fields.push(field)
    end
  end

  include ActiveModel::Model
  include ActiveModel::Attributes

  # Initialize the form, optionally providing a parameter for the form
  #
  # If you form is called FooForm, then the form will post to foo_path
  # If you provide a param, it will post to foo_path(param)
  def initialize(param: nil)
    super()
    @param = param
  end

  # Prefill your form with a hash
  #
  # This is useful for update forms. It will ignore all attributes it doesn't know.
  def prefill_with(hash)
    assign_attributes(from_model_attributes(hash))
  end

  # Apply parameters to your target object or objects
  #
  # This will first clean the parameters and check their validity
  # It will then call the update method, see below
  def apply(params, to:)
    assign_attributes(params.require(self.class.model_name.param_key).permit(*attributes.keys))
    return false unless valid?
    # TODO: If this returns false, we need to provide errors
    # Can we just overwrite errors to delegate to the object
    # if there are no errors?
    update(to, to_model_attributes)
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
      partial: "forms/#{layout}",
      locals: {
        errors: errors,
        model_name: self.class.model_name,
        form: form,
        fields: self.class.fields
      }
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

  private

  def to_model_attributes
    self.class.fields.each_with_object({}) do |field, result|
      result[field.name] = field.to_model_attribute(attributes)
    end
  end

  def from_model_attributes(hash)
    self.class.fields.each_with_object({}) do |field, result|
      result.merge!(field.from_model_attributes(hash))
    end
  end
end

class FormField
  class << self
    delegate :fetch, :key?, to: :@children

    def inherited(klass)
      @children[klass.name.underscore.to_sym] = klass
    end

    def parameter(type)
      @parameters = { nil => type }
    end

    def parameters(hash = nil)
      return @parameters if hash.nil?

      @parameters = hash
    end
  end

  @children = {}

  def initialize(name, options)
    @name = name
    @options = options
  end

  def name(suffix = nil)
    return @name if suffix.nil?
    "#{@name}-#{suffix}"
  end

  def each_parameter
    self.class.parameters.each do |suffix, type|
      # TODO: All parameters share the same validations...
      yield name(suffix), type, validations
    end
  end

  # required, pattern, min, max, step, maxlength, disabled
  # autocomplete, autofocus, placeholder
  # Bootstrap: helptext
  # TODO: All parameters share the same validations...
  def html_options
    @options
  end

  # Some validations may come from the field itself, e.g. a NumberField could add a numericality validation
  def validations
    options_to_validations(@options)
  end

  def to_model_attribute(hash)
    hash[name.to_s]
  end

  def from_model_attributes(hash)
    { name => hash[name.to_s] }
  end

  def to_partial_path
    "fields/#{self.class.name.underscore}"
  end

  private

  # TODO: Add missing validations:
  # acceptance, confirmation, exclusion, format, inclusion, length, numericality, absence
  def options_to_validations(options)
    validations = {}
    validations[:presence] = true if options[:required]
    validations
  end
end

class TextField < FormField
  parameter :string
end

class TextArea < FormField
  parameter :string
end

class NumberField < FormField
  parameter :integer
end

# class CompoundDateField < FormField
#   parameters year: :integer, month: :integer, day: :integer

#   def to_model_attribute(params)
#     Date.new(params[name(:year)], params[name(:month)], params[name(:day)])
#   end

#   def from_model_attributes(hash)
#     {
#       name(:year) => hash[name].year,
#       name(:month) => hash[name].month,
#       name(:day) => hash[name].day
#     }
#   end

#   # TODO: What is the solution for this?
#   def year_options
#     (2015..2018).to_a
#   end

#   def month_options
#     (1..12).to_a
#   end

#   def day_options
#     (1..31).to_a
#   end
# end

# class DecorativeElement < FormField
#   # If you don't provide any parameters, this will be a decorative element
# end
