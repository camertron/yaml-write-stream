yaml-write-stream
=================

[![Build Status](https://travis-ci.org/camertron/yaml-write-stream.svg?branch=master)](http://travis-ci.org/camertron/yaml-write-stream)

An easy, streaming way to generate YAML.

## Installation

`gem install yaml-write-stream`

## Usage

```ruby
require 'yaml-write-stream'
```

### Examples for the Impatient

There are two types of YAML write stream: one that uses blocks and `yield` to delimit arrays (sequences) and objects (maps), and one that's purely stateful. Here are two examples that produce the same output:

Yielding:

```ruby
stream = StringIO.new
YamlWriteStream.from_stream(stream) do |writer|
  writer.write_map do |map_writer|
    map_writer.write_key_value('foo', 'bar')
    map_writer.write_sequence('baz') do |seq_writer|
      seq_writer.write_element('goo')
    end
  end
end
```

Stateful:

```ruby
stream = StringIO.new
writer = YamlWriteStream.from_stream(stream)
writer.write_map
writer.write_key_value('foo', 'bar')
writer.write_sequence('baz')
writer.write_element('goo')
writer.close  # automatically adds closing punctuation for all nested types
```

Output:

```ruby
stream.string # => foo: bar\nbaz:\n- goo\n
```

### Yielding Writers

As far as yielding writers go, the example above contains everything you need. The stream will be automatically closed when the outermost block terminates.

### Stateful Writers

Stateful writers have a number of additional methods:

```ruby
stream = StringIO.new
writer = YamlWriteStream.from_stream(stream)
writer.write_map

writer.in_map?         # => true, currently writing a map
writer.in_sequence?    # => false, not currently writing a sequence
writer.eos?            # => false, the stream is open and the outermost map hasn't been closed yet

writer.close_map       # explicitly close the current map
writer.eos?            # => true, the outermost map has been closed

writer.write_sequence  # => raises YamlWriteStream::EndOfStreamError
writer.close_sequence  # => raises YamlWriteStream::NotInArrayError

writer.closed?         # => false, the stream is still open
writer.close           # close the stream
writer.closed?         # => true, the stream has been closed
```

### Writing to a File

YamlWriteStream also supports streaming to a file via the `open` method:

Yielding:

```ruby
YamlWriteStream.open('path/to/file.yml') do |writer|
  writer.write_map do |map_writer|
    ...
  end
end
```

Stateful:

```ruby
writer = YamlWriteStream.open('path/to/file.yml')
writer.write_map
...
writer.close
```

## Requirements

No external requirements.

## Running Tests

`bundle exec rake` should do the trick. Alternatively you can run `bundle exec rspec`, which does the same thing.

## Authors

* Cameron C. Dutro: http://github.com/camertron
