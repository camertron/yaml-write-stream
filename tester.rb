require 'pry-nav'
require 'yaml-write-stream'

f = YamlWriteStream.open('/Users/cameron/Desktop/foo.yml')
f.write_hash
f.write_array('foo')
f.write_element('bar')
f.close_array
f.close_hash
f.close
