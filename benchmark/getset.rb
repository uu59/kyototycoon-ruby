# -- coding: utf-8

require File.expand_path("#{File.dirname(__FILE__)}/helper.rb")

job = lambda {|kt|
  1000.times{|n|
    kt.set(n.to_s, n)
    kt.get(n)
  }
  kt.clear
}
benchmark(job)
