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

  it 'should handle multi servers' do
    kt = KyotoTycoon.new('8.8.8.8', 11111)
    kt.db='*'
    kt.connect_timeout = 0.1
    kt.add_server('0.0.0.0', 1978)
    kt.add_server('example.com', 1978)
    kt['foo'] = 'bar'
    kt[:foo].should == 'bar'
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
    @kt.clear

    @kt['foo'] ||= 'aaa'
    @kt['foo'] ||= 'bbb'
    @kt['foo'].should == 'aaa'
    @kt.clear

    @kt[:a] = 1
    @kt[:b] = 1
    @kt.keys.sort.should == %w!a b!.sort
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
    @kt.get_bulk(data.keys).sort.should == receive.sort
    @kt.remove_bulk(data.keys)
    @kt.get_bulk(data.keys).should == {'num' => '0'}
  end

  it 'should provide delete variation' do
    build = lambda {|kt|
      kt.clear
      kt.set_bulk({
        :a => 1,
        :b => 1,
        :c => 1,
      })
    }
    build.call(@kt)
    @kt.delete('a','b')
    @kt.keys.should == ['c']

    build.call(@kt)
    @kt.delete(['a', 'b'])
    @kt.keys.should == ['c']
  end

  it 'should increment' do
    @kt.increment('foo').should == 1
    @kt.increment('foo').should == 2
    @kt.increment('foo').should == 3
    @kt.increment('foo', 10).should == 13
  end

  it 'should provide status/report' do
    @kt[:a] = 1
    @kt[:b] = 2
    @kt.report['db_total_count'].to_i.should == 2
    @kt.status['count'].to_i.should == 2
  end

  it 'should match prefixes' do
    @kt['123'] = 1
    @kt['124'] = 1
    @kt['125'] = 1
    @kt['999'] = 1
    @kt['9999'] = 1
    @kt.match_prefix("12").sort.should == %w!123 124 125!.sort
    @kt.match_prefix("9").sort.should == %w!999 9999!.sort
    @kt.match_prefix("9999").sort.should == %w!9999!
    @kt.match_regex(/^12/).sort.should == %w!123 124 125!.sort
    @kt.match_regex(/^9+$/).sort.should == %w!999 9999!.sort
  end
end
