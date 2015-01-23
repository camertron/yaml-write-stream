# encoding: UTF-8

require 'spec_helper'

describe YamlWriteStream::YieldingWriter do
  let(:stream) do
    StringIO.new.tap do |io|
      io.set_encoding(Encoding::UTF_8)
    end
  end

  let(:stream_writer) do
    StatefulRoundtripChecker.create_writer(stream)
  end

  def check_roundtrip(obj)
    StatefulRoundtripChecker.check_roundtrip(obj)
  end

  def utf8(str)
    str.encode(Encoding::UTF_8)
  end

  it_behaves_like 'a yaml stream'

  describe '#close' do
    it 'unwinds the stack, adds appropriate closing punctuation for each unclosed item, and closes the stream' do
      stream_writer.write_sequence
      stream_writer.write_element('abc')
      stream_writer.write_map
      stream_writer.write_key_value('def', 'ghi')
      stream_writer.close

      expect(stream.string).to eq(utf8("- abc\n- def: ghi\n"))
      expect(stream_writer).to be_closed
      expect(stream).to be_closed
    end

    it 'quotes empty strings' do
      stream_writer.write_map
      stream_writer.write_key_value('foo', '')
      stream_writer.close

      expect(stream.string).to eq(utf8("foo: \"\"\n"))
      expect(stream_writer).to be_closed
      expect(stream).to be_closed
    end

    it 'writes nils as blank entries' do
      stream_writer.write_map
      stream_writer.write_key_value('foo', nil)
      stream_writer.close

      expect(stream.string).to eq(utf8("foo: \n"))
      expect(stream_writer).to be_closed
      expect(stream).to be_closed
    end
  end

  describe '#closed?' do
    it 'returns false if the stream is still open' do
      expect(stream_writer).to_not be_closed
    end

    it 'returns true if the stream is closed' do
      stream_writer.close
      expect(stream_writer).to be_closed
    end
  end

  describe '#in_map?' do
    it 'returns true if the writer is currently writing a map' do
      stream_writer.write_map
      expect(stream_writer).to be_in_map
    end

    it 'returns false if the writer is not currently writing a map' do
      expect(stream_writer).to_not be_in_map
      stream_writer.write_sequence
      expect(stream_writer).to_not be_in_map
    end
  end

  describe '#in_sequence?' do
    it 'returns true if the writer is currently writing a sequence' do
      stream_writer.write_sequence
      expect(stream_writer).to be_in_sequence
    end

    it 'returns false if the writer is not currently writing a sequence' do
      expect(stream_writer).to_not be_in_sequence
      stream_writer.write_map
      expect(stream_writer).to_not be_in_sequence
    end
  end

  describe '#eos?' do
    it 'returns false if nothing has been written yet' do
      expect(stream_writer).to_not be_eos
    end

    it 'returns false if the writer is in the middle of writing' do
      stream_writer.write_map
      expect(stream_writer).to_not be_eos
    end

    it "returns true if the writer has finished it's top-level" do
      stream_writer.write_map
      stream_writer.close_map
      expect(stream_writer).to be_eos
    end

    it 'returns true if the writer is closed' do
      stream_writer.close
      expect(stream_writer).to be_eos
    end
  end

  describe '#close_map' do
    it 'raises an error if a map is not currently being written' do
      stream_writer.write_sequence
      expect(lambda { stream_writer.close_map }).to raise_error(YamlWriteStream::NotInMapError)
    end
  end

  describe '#close_sequence' do
    it 'raises an error if a sequence is not currently being written' do
      stream_writer.write_map
      expect(lambda { stream_writer.close_sequence }).to raise_error(YamlWriteStream::NotInSequenceError)
    end
  end

  context 'with a closed stream writer' do
    before(:each) do
      stream_writer.close
    end

    describe '#write_map' do
      it 'raises an error if eos' do
        expect(lambda { stream_writer.write_map }).to raise_error(YamlWriteStream::EndOfStreamError)
      end
    end

    describe '#write_sequence' do
      it 'raises an error if eos' do
        expect(lambda { stream_writer.write_map }).to raise_error(YamlWriteStream::EndOfStreamError)
      end
    end

    describe '#write_key_value' do
      it 'raises an error if eos' do
        expect(lambda { stream_writer.write_key_value('abc', 'def') }).to raise_error(YamlWriteStream::EndOfStreamError)
      end
    end

    describe '#write_element' do
      it 'raises an error if eos' do
        expect(lambda { stream_writer.write_element('foo') }).to raise_error(YamlWriteStream::EndOfStreamError)
      end
    end
  end
end
