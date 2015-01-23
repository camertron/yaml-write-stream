# encoding: UTF-8

class YamlWriteStream
  class YieldingWriter
    attr_reader :emitter, :stream, :first

    def initialize(emitter, stream)
      @emitter = emitter
      @stream = stream
      @first = true
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
      nil
    end

    def write_sequence
      @first = false

      # anchor, tag, implicit, style
      emitter.start_sequence(
        nil, nil, true, Psych::Nodes::Sequence::ANY
      )

      yield YieldingSequenceWriter.new(emitter, stream)
      emitter.end_sequence
    end

    def write_map
      @first = false

      # anchor, tag, implicit, style
      emitter.start_mapping(
        nil, nil, true, Psych::Nodes::Sequence::ANY
      )

      yield YieldingMappingWriter.new(emitter, stream)
      emitter.end_mapping
    end

    protected

    def write_scalar(value)
      @first = false

      style = if value == ''
        Psych::Nodes::Scalar::DOUBLE_QUOTED
      else
        Psych::Nodes::Scalar::ANY
      end

      quoted = value == ''
      value = value ? value : ''

      # value, anchor, tag, plain, quoted, style
      emitter.scalar(
        value, nil, nil, true, quoted, style
      )
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
      write_scalar(key)
      write_scalar(value)
    end
  end

  class YieldingSequenceWriter < YieldingWriter
    def write_element(element)
      write_scalar(element)
    end
  end
end
