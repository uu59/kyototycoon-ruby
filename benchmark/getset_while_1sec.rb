# -- coding: utf-8

require File.expand_path("#{File.dirname(__FILE__)}/helper.rb")

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

benchmark(job)
