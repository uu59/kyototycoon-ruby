# -- coding: utf-8

require "rubygems"
require "benchmark"
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'kyototycoon.rb'

kt = KyotoTycoon.new
job = lambda {|kt|
  10000.times{|n|
    kt.set(n.to_s, n)
    kt.get(n)
  }
  kt.clear
}
Benchmark.bm do |x|
  x.report('skinny') {
    kt.agent = :skinny
    kt.serializer=:default
    job.call(kt)
  }
  x.report('nethttp') {
    kt.agent = :nethttp
    kt.serializer=:default
    job.call(kt)
  }
end
