# encoding: UTF-8

require 'spec_helper'

describe YamlWriteStream::YieldingWriter do
  let(:stream) do
    StringIO.new.tap do |io|
      io.set_encoding(Encoding::UTF_8)
    end
  end

  let(:stream_writer) do
    YieldingRoundtripChecker.create_writer(stream)
  end

  def check_roundtrip(obj)
    YieldingRoundtripChecker.check_roundtrip(obj)
  end

  def utf8(str)
    str.encode(Encoding::UTF_8)
  end

  it_behaves_like 'a yaml stream'

  describe '#close' do
    it 'closes the underlying stream' do
      stream_writer.close
      expect(stream).to be_closed
    end

    it 'quotes empty strings' do
      stream_writer.write_map do |map_writer|
        map_writer.write_key_value('foo', '')
      end

      stream_writer.close
      expect(stream.string).to eq("foo: \"\"\n")
    end

    it 'writes nils as blank entries' do
      stream_writer.write_map do |map_writer|
        map_writer.write_key_value('foo', nil)
      end

      stream_writer.close
      expect(stream.string).to eq("foo: \n")
    end
  end
end
