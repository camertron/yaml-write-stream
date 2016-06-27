# encoding: UTF-8

class YamlWriteStream
  class YieldingWriter
    attr_reader :emitter, :stream, :first, :closed
    alias_method :closed?, :closed

    def initialize(emitter, stream)
      @emitter = emitter
      @stream = stream
      @first = true
      @closed = false
    end

    def flush
      # psych gets confused if you open a file and don't at least
      # pretend to write something
      write_scalar('') if first
      emitter.end_document(true)
      emitter.end_stream
      nil
    end

    def close
      flush
      stream.close
      @closed = true
      nil
    end

    def write_sequence
      @first = false

      # anchor, tag, implicit, style
      emitter.start_sequence(
        nil, nil, false, Psych::Nodes::Sequence::ANY
      )

      yield YieldingSequenceWriter.new(emitter, stream)
      emitter.end_sequence
    end

    def write_map
      @first = false

      # anchor, tag, implicit, style
      emitter.start_mapping(
        nil, nil, false, Psych::Nodes::Sequence::ANY
      )

      yield YieldingMappingWriter.new(emitter, stream)
      emitter.end_mapping
    end

    protected

    def write_scalar(value, quote = false)
      case value
        when Numeric
          write_numeric_scalar(value)
        when NilClass
          write_nil_scalar
        else
          write_string_scalar(value.to_s, quote)
      end
    end

    def write_string_scalar(value, quote = false)
      style = if quote
        Psych::Nodes::Scalar::DOUBLE_QUOTED
      else
        Psych::Nodes::Scalar::PLAIN
      end

      # value, anchor, tag, plain, quoted, style
      emitter.scalar(
        value, nil, nil, true, true, style
      )
    end

    def write_numeric_scalar(value)
      # value, anchor, tag, plain, quoted, style
      emitter.scalar(
        value.to_s, nil, nil, true, false, Psych::Nodes::Scalar::PLAIN
      )
    end

    def write_nil_scalar
      write_string_scalar('')
    end
  end

  class YieldingMappingWriter < YieldingWriter
    def write_map(key)
      write_scalar(key)
      super()
    end

    def write_sequence(key)
      write_scalar(key)
      super()
    end

    def write_key_value(key, value)
      @first = false
      quote_key = !!(key =~ /\A\d+\z/)
      write_scalar(key, quote_key)
      write_scalar(value, true)
    end
  end

  class YieldingSequenceWriter < YieldingWriter
    def write_element(element)
      write_scalar(element)
    end
  end
end
