require 'yaml'

module Kafo
  class AnswerFile

    attr_reader :answers, :filename, :version

    def initialize(answer_filename, version: 1)
      @filename = answer_filename
      @version = version.nil? ? 1 : version

      begin
        @answers = YAML.load_file(@filename)
      rescue Errno::ENOENT
        KafoConfigure.exit(:no_answer_filename) do
          puts "No answer file found at #{@filename}"
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
      params = @answers[puppet_class]
      params.is_a?(Hash) ? params : {}
    end

    def class_enabled?(puppet_class)
      value = @answers[puppet_class.is_a?(String) ? puppet_class : puppet_class.identifier]
      !!value || value.is_a?(Hash)
    end

    private

    def validate
      invalid = @answers.reject do |puppet_class, value|
        value.is_a?(Hash) || [true, false].include?(value)
      end

      unless invalid.empty?
        KafoConfigure.exit(:invalid_values) do
          KafoConfigure.logger.error("Answer file at #{@filename} has invalid values for #{invalid}. Please ensure they are either a hash or true/false.")
        end
      end
    end

  end
end
