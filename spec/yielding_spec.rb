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

    it 'correctly writes to and closes the stream without non-specific (implicit) tag notation' do
      stream_writer.write_sequence do |seq_writer|
        seq_writer.write_element('abc')
        seq_writer.write_map do |map_writer|
          map_writer.write_key_value('def', 'ghi')
        end
      end

      stream_writer.close
      expect(stream.string).to eq(utf8("- abc\n- def: \"ghi\"\n"))
      expect(stream_writer).to be_closed
      expect(stream).to be_closed
    end

    it 'dumps numbers without quotes and without non-specific (implicit) tag notation' do
      stream_writer.write_map do |map_writer|
        map_writer.write_key_value('abc', 7)
      end

      stream_writer.close
      expect(stream.string).to eq(utf8("abc: 7\n"))
      expect(stream_writer).to be_closed
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
