# encoding: UTF-8

require 'rspec'
require 'yaml-write-stream'
require 'shared_examples'
require 'pry-byebug'

RSpec.configure do |config|
  config.mock_with :rr
end

class RoundtripChecker
  class << self
    include RSpec::Matchers

    def check_roundtrip(obj)
      stream = StringIO.new
      writer = create_writer(stream)
      serialize(obj, writer)
      writer.close
      new_obj = Psych.load(stream.string)
      compare(obj, new_obj)
    end

    protected

    def create_emitter(stream)
      Psych::Emitter.new(stream).tap do |emitter|
        emitter.start_stream(Psych::Parser::UTF8)
        emitter.start_document([], [], true)
      end
    end

    private

    def compare(old_obj, new_obj)
      expect(old_obj.class).to equal(new_obj.class)

      case old_obj
        when Hash
          expect(old_obj.keys).to eq(new_obj.keys)

          old_obj.each_pair do |key, old_val|
            compare(old_val, new_obj[key])
          end
        when Array
          old_obj.each_with_index do |old_element, idx|
            compare(old_element, new_obj[idx])
          end
        else
          expect(old_obj).to eq(new_obj)
      end
    end
  end
end

class YieldingRoundtripChecker < RoundtripChecker
  class << self
    def create_writer(stream)
      YamlWriteStream::YieldingWriter.new(
        create_emitter(stream), stream
      )
    end

    protected

    def serialize(obj, writer)
      case obj
        when Hash
          writer.write_map do |map_writer|
            serialize_map(obj, map_writer)
          end
        when Array
          writer.write_sequence do |sequence_writer|
            serialize_sequence(obj, sequence_writer)
          end
      end
    end

    def serialize_map(obj, writer)
      obj.each_pair do |key, val|
        case val
          when Hash
            writer.write_map(key) do |map_writer|
              serialize_map(val, map_writer)
            end
          when Array
            writer.write_sequence(key) do |sequence_writer|
              serialize_sequence(val, sequence_writer)
            end
          else
            writer.write_key_value(key, val)
        end
      end
    end

    def serialize_sequence(obj, writer)
      obj.each do |element|
        case element
          when Hash
            writer.write_map do |map_writer|
              serialize_map(element, map_writer)
            end
          when Array
            writer.write_sequence do |sequence_writer|
              serialize_sequence(element, sequence_writer)
            end
          else
            writer.write_element(element)
        end
      end
    end
  end
end

class StatefulRoundtripChecker < RoundtripChecker
  class << self
    def create_writer(stream)
      YamlWriteStream::StatefulWriter.new(
        create_emitter(stream), stream
      )
    end

    protected

    def serialize(obj, writer)
      case obj
        when Hash
          writer.write_map
          serialize_map(obj, writer)
          writer.close_map
        when Array
          writer.write_sequence
          serialize_sequence(obj, writer)
          writer.close_sequence
      end
    end

    def serialize_map(obj, writer)
      obj.each_pair do |key, val|
        case val
          when Hash
            writer.write_map(key)
            serialize_map(val, writer)
            writer.close_map
          when Array
            writer.write_sequence(key)
            serialize_sequence(val, writer)
            writer.close_sequence
          else
            writer.write_key_value(key, val)
        end
      end
    end

    def serialize_sequence(obj, writer)
      obj.each do |element|
        case element
          when Hash
            writer.write_map
            serialize_map(element, writer)
            writer.close_map
          when Array
            writer.write_sequence
            serialize_sequence(element, writer)
            writer.close_sequence
          else
            writer.write_element(element)
        end
      end
    end
  end
end
