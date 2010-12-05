# -- coding: utf-8

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
require "rubygems"
require "benchmark"
require 'kyoto_tycoon.rb'

kt = KyotoTycoon.new
bulk={}
str = "string ああ" * 10000
100.times.map{|n|
  bulk[n.to_s] = str
}
job = lambda {|kt|
  kt.set_bulk(bulk)
  kt.get_bulk(bulk.keys)
  kt.clear
}
Benchmark.bm do |x|
  x.report('default') {
    kt.serializer=:default
    job.call(kt)
  }
  x.report('msgpack') {
    kt.serializer=:msgpack
    job.call(kt)
  }
end
