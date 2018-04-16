class BaseForm
  class << self
    attr_reader :fields

    def model(klass = nil)
      return @model if klass.nil?
      @model = klass
    end

    def field(name, type)
      @fields ||= []
      @fields.push(
        name: name,
        type: type
      )
    end

    def from(params)
      model.new(clean_params(params))
    end

    # TODO: form_name dependent on model?
    def clean_params(params)
      form_name = name.tableize.gsub(/_forms$/, "").singularize.to_sym
      field_names = @fields.map { |field| field.fetch(:name) }
      params.require(form_name).permit(*field_names)
    end
  end

  attr_reader :model

  delegate_missing_to :model

  # TODO: Maybe this should behave like from
  def initialize(model)
    @model = model
  end

  def fields
    self.class.fields
  end
end
