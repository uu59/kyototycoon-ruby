# -- coding: utf-8


require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

describe KyotoTycoon do
  it 'should handle multi servers' do
    kt = KyotoTycoon.new('www.example.com', 11111)
    kt.connect_timeout = 0.1
    kt.servers << ['example.net', 1978]
    kt.servers << ['0.0.0.0', 19999]
    kt['foo'] = 'bar'
    kt[:foo].should == 'bar'
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
    lambda { KyotoTycoon.configure(:test2) }.should raise_error(StandardError)
    lambda { KyotoTycoon.create(:not_exists) }.should raise_error(StandardError)

    KyotoTycoon.configures.length.should == 2
    KyotoTycoon.configure_reset!
    KyotoTycoon.configures.length.should == 0
  end

  it 'should handle `ktremotemgr slave`' do
    io = File.open("#{File.dirname(__FILE__)}/ktslave.txt", "r")
    current = 0
    KyotoTycoon::Stream.run(io){|line|
      case current
        when 0 # clear command
          line.cmd.should == 'clear'
          line.xt_time.should == Time.at(0)
          line.value.should be_nil
          line.key.should be_nil
          line.value.should be_nil
        when 1 # set foo bar
          line.cmd.should == 'set'
          line.xt_time.should > Time.now
          line.key.should == 'foo'
          line.value.should == 'bar'
        when 2 # set fooxt bar with xt(2010-12-23 22:09:49 +0900)
          line.cmd.should == 'set'
          line.key.should == 'fooxt'
          line.value.should == 'bar'
          line.xt_time.should > Time.at(1234567890)
          line.xt_time.should < Time.at(1334567890)
        when 3 # remove foo
          line.cmd.should == 'remove'
          line.key.should == 'foo'
          line.value.should be_nil
      end
      current += 1
    }
  end
end
