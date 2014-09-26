# encoding: UTF-8

require 'spec_helper'
require 'tempfile'

describe YamlWriteStream do
  let(:yielding_writer) { YamlWriteStream::YieldingWriter }
  let(:stateful_writer) { YamlWriteStream::StatefulWriter }
  let(:stream_writer) { YamlWriteStream }
  let(:tempfile) { Tempfile.new('temp') }
  let(:stream) { StringIO.new }

  def encodings_match?(outputs)
    flattened = flatten_encodings(outputs)
    flattened.uniq.size == flattened.size
  end

  def flatten_encodings(outputs)
    outputs.map do |encoding, value|
      bom = case encoding
        when Encoding::UTF_16LE, Encoding::UTF_16BE
          [239, 187, 191]
        else
          []
      end

      bom + value
        .force_encoding(encoding)
        .encode(Encoding::UTF_8)
        .bytes
        .to_a
    end
  end

  describe '#from_stream' do
    it 'yields a yielding stream if given a block' do
      stream_writer.from_stream(stream) do |writer|
        expect(writer).to be_a(yielding_writer)
        expect(writer.stream).to equal(stream)
      end
    end

    it 'returns a stateful writer if not given a block' do
      writer = stream_writer.from_stream(stream)
      expect(writer).to be_a(stateful_writer)
      expect(writer.stream).to equal(stream)
    end

    [Encoding::UTF_8, Encoding::UTF_16LE, Encoding::UTF_16BE].each do |encoding|
      it "supports specifying a #{encoding.name} encoding" do
        stream_writer.from_stream(stream, encoding) do |writer|
          writer.write_map do |map_writer|
            map_writer.write_key_value('foo', 'bar')
          end
        end

        expect(
          encodings_match?({
            encoding => stream.string,
            Encoding::UTF_8 => "foo: bar\n"
          })
        ).to eq(true)
      end
    end

    it "doesn't support other encodings" do
      expect(
        lambda do
          stream_writer.from_stream(stream, Encoding::US_ASCII)
        end
      ).to raise_error(ArgumentError)
    end

    it 'interprets string encoding names' do
      stream_writer.from_stream(stream, 'UTF-16BE') do |writer|
        writer.write_map do |map_writer|
          map_writer.write_key_value('foo', 'bar')
        end
      end

      expect(
        encodings_match?({
          Encoding::UTF_16BE => stream.string,
          Encoding::UTF_8 => "foo: bar\n"
        })
      )
    end

    it 'interprets Psych integer encodings' do
      stream_writer.from_stream(stream, Psych::Parser::UTF16BE) do |writer|
        writer.write_map do |map_writer|
          map_writer.write_key_value('foo', 'bar')
        end
      end

      expect(
        encodings_match?({
          Encoding::UTF_16BE => stream.string,
          Encoding::UTF_8 => "foo: bar\n"
        })
      )
    end

    it 'raises an error if an unrecognized type of object is given as encoding' do
      expect(
        lambda do
          stream_writer.from_stream(stream, Object.new)
        end
      ).to raise_error(ArgumentError)
    end
  end

  describe '#open' do
    it 'opens a file and yields a yielding stream if given a block' do
      mock.proxy(File).open(tempfile, 'w')
      stream_writer.open(tempfile) do |writer|
        expect(writer).to be_a(yielding_writer)
        expect(writer.stream.path).to eq(tempfile.path)
      end
    end

    it 'opens a file and returns a stateful writer if not given a block' do
      mock.proxy(File).open(tempfile, 'w')
      writer = stream_writer.open(tempfile)
      expect(writer).to be_a(stateful_writer)
      expect(writer.stream.path).to eq(tempfile.path)
    end

    [Encoding::UTF_8, Encoding::UTF_16LE, Encoding::UTF_16BE].each do |encoding|
      it "supports specifying a #{encoding.name} encoding" do
        stream_writer.open(tempfile, encoding) do |writer|
          writer.write_map do |map_writer|
            map_writer.write_key_value('foo', 'bar')
          end
        end

        expect(
          encodings_match?({
            encoding => stream.string,
            Encoding::UTF_8 => "foo: bar\n"
          })
        ).to eq(true)
      end
    end
  end
end
