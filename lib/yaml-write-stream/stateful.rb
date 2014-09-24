# encoding: UTF-8

class YamlWriteStream
  class NotInHashError < StandardError; end
  class NotInArrayError < StandardError; end
  class EndOfStreamError < StandardError; end

  class StatefulWriter
    attr_reader :emitter, :stream, :stack, :closed, :first
    alias :closed? :closed

    def initialize(emitter, stream)
      @emitter = emitter
      @stream = stream
      @stack = []
      @closed = false
      after_initialize
    end

    def after_initialize
      @first = true
    end

    def close
      until stack.empty?
        if in_hash?
          close_hash
        else
          close_array
        end
      end

      emitter.end_document(true)
      emitter.end_stream
      stream.close
    end

    def write_hash(*args)
      check_eos
      @first = false
      current.write_hash(*args) if current
      stack.push(StatefulMappingWriter.new(emitter, stream))
    end

    def write_array(*args)
      check_eos
      @first = false
      current.write_array(*args) if current
      stack.push(StatefulSequenceWriter.new(emitter, stream))
    end

    def write_key_value(*args)
      check_eos
      @first = false
      current.write_key_value(*args)
    end

    def write_element(*args)
      check_eos
      @first = false
      current.write_element(*args)
    end

    def eos?
      closed? || (!first && stack.size == 0)
    end

    def in_hash?
      current ? current.is_hash? : false
    end

    def in_array?
      current ? current.is_array? : false
    end

    def close_hash
      if in_hash?
        stack.pop.close
      else
        raise NotInHashError, 'not currently writing a hash.'
      end
    end

    def close_array
      if in_array?
        stack.pop.close
      else
        raise NotInArrayError, 'not currently writing an array.'
      end
    end

    protected

    def check_eos
      if eos?
        raise EndOfStreamError, 'end of stream.'
      end
    end

    def current
      stack.last
    end

    def write_scalar(value)
        # value, anchor, tag, plain, quoted, style
      emitter.scalar(
        value, nil, nil, true, false, Psych::Nodes::Scalar::ANY
      )
    end
  end

  class StatefulMappingWriter < StatefulWriter
    def after_initialize
      # anchor, tag, implicit, style
      emitter.start_mapping(
        nil, nil, true, Psych::Nodes::Sequence::BLOCK
      )
    end

    def write_hash(key)
      write_scalar(key)
    end

    def write_array(key)
      write_scalar(key)
    end

    def write_key_value(key, value)
      write_scalar(key)
      write_scalar(value)
    end

    def close
      emitter.end_mapping
    end

    def is_hash?
      true
    end

    def is_array?
      false
    end
  end

  class StatefulSequenceWriter < StatefulWriter
    def after_initialize
      # anchor, tag, implicit, style
      emitter.start_sequence(
        nil, nil, true, Psych::Nodes::Sequence::BLOCK
      )
    end

    def write_element(element)
      write_scalar(element)
    end

    def write_hash
    end

    def write_array
    end

    def close
      emitter.end_sequence
    end

    def is_hash?
      false
    end

    def is_array?
      true
    end
  end
end
