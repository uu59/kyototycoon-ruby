# -- coding: utf-8

require "rubygems"
require "benchmark"
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require "msgpack"
require 'kyoto_tycoon.rb'

job = lambda {|kt|
  cnt = 0
  begin
    timeout(1){
      loop do
        kt[:foo] = :bar
        kt[:foo]
        cnt += 1
      end
    }
  rescue Timeout::Error
  end
  kt.clear
  cnt
}

kt = KyotoTycoon.new

%w"nethttp skinny".each{|agent|
  %w!default msgpack!.each{|serializer|
    kt.agent = agent.to_sym
    kt.serializer = serializer.to_sym
    puts "#{agent}/#{serializer}: #{job.call(kt)}"
  }
}
