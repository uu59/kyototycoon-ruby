# -- coding: utf-8

require "benchmark"

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'kyototycoon.rb'

def benchmark(job)
  kt = KyotoTycoon.new('0.0.0.0', 19999)
  Benchmark.bm do |x|
    %w!B U!.each{|colenc|
      %w!default msgpack!.each{|serializer|
        x.report("#{serializer}, colenc=#{colenc}") {
          kt.serializer=serializer.to_sym
          kt.colenc = colenc.to_sym
          job.call(kt)
        }
      }
    }
  end
end

