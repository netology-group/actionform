module ActionForm
  module FormHelpers
    ATTRIBUTES_KEY_REGEXP = /^(.+)_attributes$/

    def submit(params)
      params.each do |key, value|
        if nested_params?(key)
          fill_association_with_attributes(key, value)
        else
          send("#{key}=", value) if respond_to?("#{key}=")
        end
      end
    end

    def valid?
      super
      model.valid?

      collect_errors_from(model)
      aggregate_form_errors

      errors.empty?
    end

    def nested_params?(key)
      ATTRIBUTES_KEY_REGEXP.match(key).present?
    end

    def find_association_name_in(key)
      ATTRIBUTES_KEY_REGEXP.match(key)[1]
    end

    def fill_association_with_attributes(association, attributes)
      assoc_name = find_association_name_in(association).to_sym
      form = find_form_by_assoc_name(assoc_name)

      form.submit(attributes)
    end

    def find_form_by_assoc_name(assoc_name)
      forms.select { |form| form.represents?(assoc_name) }.first
    end

    def aggregate_form_errors
      forms.each do |form|
        form.valid?
        collect_errors_from(form)
      end
    end

    def collect_errors_from(validatable_object)
      validatable_object.errors.each do |error|
        key = if validatable_object.respond_to?(:association_name)
          "#{validatable_object.association_name}.#{error.attribute}"
        else
          error.attribute
        end

        errors.add(key, error.message)
      end
    end
  end
end
