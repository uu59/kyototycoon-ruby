# -- coding: utf-8

require File.expand_path("#{File.dirname(__FILE__)}/helper.rb")

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
benchmark(job)
