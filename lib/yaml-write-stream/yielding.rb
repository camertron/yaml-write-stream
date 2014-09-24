# encoding: UTF-8

class YamlWriteStream
  class YieldingWriter
    attr_reader :emitter, :stream

    def initialize(emitter, stream)
      @emitter = emitter
      @stream = stream
    end

    def close
      emitter.end_document(true)
      emitter.end_stream
      stream.close
    end

    def write_array
      # anchor, tag, implicit, style
      emitter.start_sequence(
        nil, nil, true, Psych::Nodes::Sequence::ANY
      )

      yield YieldingSequenceWriter.new(emitter, stream)
      emitter.end_sequence
    end

    def write_hash
      # anchor, tag, implicit, style
      emitter.start_mapping(
        nil, nil, true, Psych::Nodes::Sequence::ANY
      )

      yield YieldingMappingWriter.new(emitter, stream)
      emitter.end_mapping
    end

    protected

    def write_scalar(value)
        # value, anchor, tag, plain, quoted, style
      emitter.scalar(
        value, nil, nil, true, false, Psych::Nodes::Scalar::ANY
      )
    end
  end

  class YieldingMappingWriter < YieldingWriter
    def write_hash(key)
      write_scalar(key)
      super()
    end

    def write_array(key)
      write_scalar(key)
      super()
    end

    def write_key_value(key, value)
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
