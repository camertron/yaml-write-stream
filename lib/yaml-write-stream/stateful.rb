# encoding: UTF-8

class YamlWriteStream
  class NotInMapError < StandardError; end
  class NotInSequenceError < StandardError; end
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
      @first = true
    end

    def after_initialize
      @first = true
    end

    def flush
      # psych gets confused if you open a file and don't at least
      # pretend to write something
      write_scalar('') if first

      until stack.empty?
        if in_map?
          close_map
        else
          close_sequence
        end
      end

      emitter.end_document(true)
      emitter.end_stream
      stream.flush
      @closed = true
      nil
    end

    def close
      flush
      stream.close
      nil
    end

    def write_map(*args)
      check_eos
      @first = false
      current.write_map(*args) if current
      stack.push(StatefulMappingWriter.new(emitter, stream))
    end

    def write_sequence(*args)
      check_eos
      @first = false
      current.write_sequence(*args) if current
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

    def in_map?
      current ? current.is_map? : false
    end

    def in_sequence?
      current ? current.is_sequence? : false
    end

    def close_map
      if in_map?
        stack.pop.close
      else
        raise NotInMapError, 'not currently writing a map.'
      end
    end

    def close_sequence
      if in_sequence?
        stack.pop.close
      else
        raise NotInSequenceError, 'not currently writing an sequence.'
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

    def write_scalar(value, quote = false)
      style = if value == ''
        Psych::Nodes::Scalar::DOUBLE_QUOTED
      else
        if !quote || !value
          Psych::Nodes::Scalar::ANY
        else
          Psych::Nodes::Scalar::DOUBLE_QUOTED
        end
      end

      quoted = value == ''
      value = value ? value : ''

      # value, anchor, tag, plain, quoted, style
      emitter.scalar(
        value, nil, nil, true, quoted, style
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

    def write_map(key)
      write_scalar(key)
    end

    def write_sequence(key)
      write_scalar(key)
    end

    def write_key_value(key, value)
      write_scalar(key)
      write_scalar(value, true)
    end

    def close
      emitter.end_mapping
    end

    def is_map?
      true
    end

    def is_sequence?
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

    def write_map
    end

    def write_sequence
    end

    def close
      emitter.end_sequence
    end

    def is_map?
      false
    end

    def is_sequence?
      true
    end
  end
end
