# -- coding: utf-8

require File.expand_path("#{File.dirname(__FILE__)}/helper.rb")

bulk={}
50000.times.map{|n|
  bulk[n.to_s] = "#{n}-#{rand}"
}
job = lambda {|kt|
  kt.set_bulk(bulk)
  kt.get_bulk(bulk.keys)
  kt.clear
}

benchmark(job)
