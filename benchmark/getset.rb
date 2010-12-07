# -- coding: utf-8

require "rubygems"
require "benchmark"
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'kyoto_tycoon.rb'

kt = KyotoTycoon.new
job = lambda {|kt|
  1000.times{|n|
    kt.set(n.to_s, n)
    kt.get(n)
  }
  kt.clear
}
Benchmark.bm do |x|
  x.report('default') {
    kt.agent = :nethttp
    kt.serializer=:default
    job.call(kt)
  }
  x.report('msgpack') {
    kt.agent = :nethttp
    kt.serializer=:msgpack
    job.call(kt)
  }
  x.report('default(skinny)') {
    kt.agent = :skinny
    kt.serializer=:default
    job.call(kt)
  }
  x.report('msgpack(skinny)') {
    kt.agent = :skinny
    kt.serializer=:msgpack
    job.call(kt)
  }
end
