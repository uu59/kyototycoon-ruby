# -- coding: utf-8

$LOAD_PATH.unshift(File.dirname(__FILE__) + "/../lib")
require "rubygems"
require "kyoto_tycoon.rb"

describe do
  before(:all) do
    @kt = KyotoTycoon.new
    @kt.serializer=:default # or :msgpack
    @kt.db='*' # in memory
    @kt.logger=nil
  end

  before(:each) do
    @kt.clear
  end

  it 'should provide simple kvs feature' do
    @kt.set('a', 'b')
    @kt.get('a').should == 'b'
    @kt['foo'] = 'bar'
    @kt['foo'].should == 'bar'
    @kt.delete('foo')
    @kt['foo'].should be_nil
    @kt.clear
    @kt.report['db_total_count'].to_i.should == 0
    @kt.status['count'].to_i.should == 0

    @kt['foo'] = 'oldbaz'
    @kt.cas('foo', 'oldbaz', 'newbaz').should be_true
    @kt.cas('foo', 'oldbaz', 'newbaz').should be_false
    @kt.get('foo').should == 'newbaz'
  end

  it 'should provide bulk' do
    data = {}
    receive = {}
    10.times{|n|
      data[n.to_s] = n.to_s
      receive["_#{n}"] = n.to_s
    }
    receive['num'] = "10"
    @kt.set_bulk(data)
    @kt.get_bulk(data.keys).should == receive
    @kt.remove_bulk(data.keys)
    @kt.get_bulk(data.keys).should == {'num' => '0'}
  end

  it 'should increment' do
    @kt.increment('foo').should == 1
    @kt.increment('foo').should == 2
    @kt.increment('foo').should == 3
    @kt.increment('foo', 10).should == 13
  end

  it 'should keepalive switch' do
    @kt.keepalive=true
    @kt.tsvrpc.nethttp.active?.should be_true
    @kt.keepalive=false
    @kt.tsvrpc.nethttp.active?.should be_false
  end
end
