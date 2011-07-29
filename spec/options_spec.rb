# -- coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

describe KyotoTycoon do
  [:U, :B].each{|colenc|
    context "colenc=#{colenc}" do
      before(:each) do
        @kt.colenc = colenc
      end

      [:default, :msgpack].each{|serializer|
        context "serializer=#{serializer}" do
          before(:each) do
            @kt.serializer = serializer
          end

          it 'should provide simple kvs feature' do
            @kt.set('a', 'b')
            @kt.get('a').should == 'b'
            @kt['foo'] = 'bar'
            @kt['foo'].should == 'bar'
            @kt.delete('foo')
            @kt['foo'].should be_nil

            @kt.add('123', '123')
            @kt['123'].should == '123'
            @kt.replace('123', '456')
            @kt['123'].should == '456'
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
            @kt.clear

            @kt[:longvalue] = "-" * 2048
            @kt[:longvalue].should == '-' * 2048
          end

          it 'should provide bulk' do
            data = {}
            10.times{|n|
              data[n.to_s] = n.to_s
            }
            @kt.set_bulk(data)
            @kt.get_bulk(data.keys).sort.should == data.sort
            @kt.remove_bulk(data.keys)
            @kt.get_bulk(data.keys).should == {}
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

          if serializer == :msgpack
            it 'should keep variable type(int) with msgpack' do
              @kt["foo"] = 42
              @kt["foo"].should == 42
            end
          end
        end
      }
    end
  }
end
