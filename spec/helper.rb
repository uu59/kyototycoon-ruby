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

describe do
  before(:all) do
    @kt = KyotoTycoon.new('0.0.0.0', 19999)
    @kt.serializer=:default # or :msgpack
    @kt.logger=nil
  end

  before(:each) do
  end

  after(:each) do
    @kt.clear
  end

  it 'should handle multi servers' do
    kt = KyotoTycoon.new('www.example.com', 11111)
    kt.connect_timeout = 0.1
    kt.servers << ['example.net', 1978]
    kt.servers << ['0.0.0.0', 19999]
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

  it 'should can handle strange key/value' do
    # '+' is known ambiguity key on URL encode/decode processing
    %w!a\tb a\nb a\r\nb a*-b a^@b!.each{|outlaw|
      @kt[outlaw] = outlaw
      @kt[outlaw].should == outlaw
    }
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
    @kt.increment('foo', -10).should == 3
    @kt.decrement('foo', 5).should == -2
    @kt.incr('foo', 5).should == 3
    @kt.decr('foo', 5).should == -2
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

  it 'should configure/create method works' do
    logger = Logger.new(STDOUT)
    KyotoTycoon.configure(:test) do |kt|
      kt.logger = logger
      kt.serializer = :msgpack
      kt.db = 'foobar'
    end
    KyotoTycoon.configure(:test2, 'host', 1999) do |kt|
      kt.logger = logger
      kt.serializer = :msgpack
      kt.db = 'foobar'
    end
    %w!test test2!.each{|name|
      kt = KyotoTycoon.create(name.to_sym)
      kt.logger.should == logger
      kt.serializer.should == KyotoTycoon::Serializer::Msgpack
      kt.db.should == 'foobar'
    }
  end
end
