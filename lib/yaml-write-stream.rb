# encoding: UTF-8

require 'psych'
require 'yaml-write-stream/yielding'
require 'yaml-write-stream/stateful'

class YamlWriteStream
  class << self
    def open(path, encoding = Psych::Parser::UTF8, &block)
      handle = ::File.open(path, 'w')
      from_stream(handle, encoding, &block)
    end

    def from_stream(stream, encoding = Psych::Parser::UTF8)
      emitter = Psych::Emitter.new(stream)
      emitter.start_stream(convert_encoding(encoding))

      # version, tag_directives, implicit
      emitter.start_document([], [], true)

      if block_given?
        yield writer = YieldingWriter.new(emitter, stream)
        writer.close
        nil
      else
        StatefulWriter.new(emitter, stream)
      end
    end

    private

    def convert_encoding(encoding)
      case encoding
        when Encoding
          case encoding
            when Encoding::UTF_8
              Psych::Parser::UTF8
            when Encoding::UTF_16BE
              Psych::Parser::UTF16BE
            when Encoding::UTF_16LE
              Psych::Parser::UTF16LE
            else
              raise ArgumentError, "'#{encoding}' encoding is not supported by Psych."
          end
        when Fixnum
          encoding
        when String
          convert_encoding(Encoding.find(encoding))
        else
          raise ArgumentError, "encoding of type #{encoding.class} is not supported, please provide an Encoding or a Fixnum."
      end
    end
  end
end
