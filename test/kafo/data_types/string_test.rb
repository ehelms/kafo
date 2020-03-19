require 'test_helper'

module Kafo
  module DataTypes
    describe String do
      describe "registered" do
        it { _(DataType.new_from_string('String')).must_be_instance_of String }
      end

      describe "#to_s" do
        it { _(String.new.to_s).must_equal 'string' }
        it { _(String.new(2).to_s).must_equal 'string (at least 2 characters)' }
        it { _(String.new(0, 2).to_s).must_equal 'string (up to 2 characters)' }
        it { _(String.new(1, 2).to_s).must_equal 'string (between 1 and 2 characters)' }
      end

      describe "#valid?" do
        it { _(String.new.valid?(1)).must_equal false }
        it { _(String.new.valid?('foo')).must_equal true }
        it { _(String.new(1).valid?('foo')).must_equal true }
        it { _(String.new(2).valid?('f')).must_equal false }
        it { _(String.new(1, 2).valid?('fo')).must_equal true }
        it { _(String.new(1, 2).valid?('foo')).must_equal false }
      end
    end
  end
end
