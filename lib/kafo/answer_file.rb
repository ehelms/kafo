require 'yaml'

module Kafo
  class AnswerFile

    attr_reader :answers, :filename, :version

    def initialize(answer_filename, version: 1, exit_handler: KafoConfigure, logger: KafoConfigure.logger)
      @filename = answer_filename
      @version = version.nil? ? 1 : version
      @exit_handler = exit_handler
      @logger = logger

      begin
        @answers = YAML.load_file(@filename)
      rescue Errno::ENOENT
        @exit_handler.exit(:no_answer_file) do
          @logger.error "No answer file found at #{@filename}"
        end
      end

      validate
    end

    def filename
      @filename
    end

    def puppet_classes
      @answers.keys.sort
    end

    def parameters_for_class(puppet_class)
      if @version == 1
        params = @answers[puppet_class]
        params.is_a?(Hash) ? params : {}
      elsif @version == 2
        @answers[puppet_class]['parameters']
      end
    end

    def class_enabled?(puppet_class)
      if @version == 1
        value = @answers[puppet_class.is_a?(String) ? puppet_class : puppet_class.identifier]
        !!value || value.is_a?(Hash)
      elsif @version == 2
        @answers[puppet_class]['enabled']
      end
    end

    private

    def validate
      if @version == 1
        validate_version_1
      elsif @version == 2
        validate_version_2
      end
    end

    def validate_version_1
      invalid = @answers.reject do |puppet_class, value|
        value.is_a?(Hash) || [true, false].include?(value)
      end

      unless invalid.empty?
        @exit_handler.exit(:invalid_values) do
          @logger.error("Answer file at #{@filename} has invalid values for #{invalid.keys.join(', ')}. Please ensure they are either a hash or true/false.")
        end
      end
    end

    def validate_version_2
      missing_enabled = @answers.reject do |puppet_class, value|
        value && value.key?('enabled')
      end

      unless missing_enabled.empty?
        @exit_handler.exit(:invalid_values) do
          @logger.error("Answer file at #{@filename} is missing 'enabled' field for #{missing_enabled.keys.join(', ')}.")
        end
      end

      valid_enabled_values = @answers.reject do |puppet_class, value|
        [true, false, 'always'].include?(value['enabled'])
      end

      unless valid_enabled_values.empty?
        @exit_handler.exit(:invalid_values) do
          @logger.error("Answer file at #{@filename} has invalid values for 'enabled' field for #{valid_enabled_values.keys.join(', ')}.")
        end
      end
    end

  end
end
