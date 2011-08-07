# -- coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

describe KyotoTycoon do
  before(:each) do
    @kt = KyotoTycoon.new('localhost', 19999)
    100.times{|n|
      @kt["#{"%02d" % n}foo"] = "foo#{n}"
    }
  end

  it 'should handle cursor object' do
    cur = @kt.cursor
    cur.jump("33")
    cur.key.should == "33foo"
    cur.value.should == "foo33"
    cur.current.should == [ "33foo","foo33" ]
    cur.value = "new"
    @kt["33foo"].should == "new"

    cur.step
    cur.key.should == "34foo"
    cur.value.should == "foo34"
    cur.remove
    @kt["34foo"].should be_nil

    cur.jump('55')
    cur.seize.should == ["55foo","foo55"]
    @kt["55foo"].should be_nil
  end

  it 'should handle cursor steps' do
    # If you got failed in this section, it's a KyotoCabinet's bug
    # It has been fixed at KyotoCabinet 1.2.70
    # c.f.
    # https://gist.github.com/1117611
    # https://twitter.com/#!/fallabs/status/98079688550916097
    cur = @kt.cursor
    cur.jump
    cur.key.should == "00foo"

    cur.jump_back
    cur.key.should == "99foo"
    cur.jump
    cur.key.should == "00foo"

    cur.jump("50")
    cur.step
    cur.key.should == "51foo"
    cur.step_back
    cur.key.should == "50foo"
    cur.step
    cur.key.should == "51foo"
  end

  it "should handle multiple cursors" do
    cur = @kt.cursor
    cur2 = @kt.cursor
    cur.jump("33")
    cur.cur.should_not == cur2.cur
    cur.key.should_not == cur2.key
  end

  it "should keep current position after called #each" do
    cur = @kt.cursor
    cur.jump("49")
    cur.each{|k,v| } # no-op
    cur.key.should == "49foo"
  end

  it "should handle #each" do
    cur = @kt.cursor
    cur.find{|k,v| k == "non-exists"}.should be_nil
    cur.find_all{|k,v| k.match(/3[234]foo/)}.should == [
      %w!32foo foo32!,
      %w!33foo foo33!,
      %w!34foo foo34!,
    ]
    cur.jump("33")
    cur.find_all{|k,v| k.match(/3[234]foo/)}.should == [
      %w!33foo foo33!,
      %w!34foo foo34!,
    ]

    cur.jump
    cur.find{|k,v| k == "15foo"}.should == ["15foo", "foo15"]
  end
end
