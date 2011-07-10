# -- coding: utf-8

=begin

!!!!!!!!!!!!!
!! CAUTION !!
!!!!!!!!!!!!!

This script access http://0.0.0.0:19999/ and destroy all records.
Be carefully for run, and run `ktserver -port 19999 '*'` before testing.

=end

$LOAD_PATH.unshift(File.dirname(__FILE__) + "/../lib")
require "rubygems"
require "kyototycoon.rb"
require "kyototycoon/stream.rb"

RSpec.configure do |conf|
  conf.before(:all) do
    @kt = KyotoTycoon.new('0.0.0.0', 19999)
    @kt.serializer=:default # or :msgpack
    @kt.logger=nil
  end

  conf.before(:each) do
  end

  conf.after(:each) do
    @kt.clear
  end
end
