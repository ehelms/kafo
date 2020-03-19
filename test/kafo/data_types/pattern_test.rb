require 'test_helper'

module Kafo
  module DataTypes
    describe Pattern do
      describe "registered" do
        it { _(DataType.new_from_string('Pattern')).must_be_instance_of Pattern }
      end

      describe "#to_s" do
        it { _(Pattern.new('f..').to_s).must_equal 'regexes matching /f../' }
        it { _(Pattern.new('f..', 'b.*').to_s).must_equal 'regexes matching /f../ or /b.*/' }
      end

      describe "#valid?" do
        it { _(Pattern.new('f..').valid?(1)).must_equal false }
        it { _(Pattern.new('f..').valid?('foo')).must_equal true }
        it { _(Pattern.new('f..').valid?('bar')).must_equal false }
        it { _(Pattern.new('f..', 'b.*').valid?('bar')).must_equal true }
      end
    end
  end
end
