require 'rubygems'
require 'erb'
require 'json'
a=JSON.parse(File.read('keys.json'))
@config=a["global_conf"]
renderer=ERB.new(File.read('keys.erb'),nil, '<>')
filled=renderer.result(binding)
File.open('keys.output.txt', "w+") do |f|
  f.write(filled)
end
