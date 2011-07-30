# -- coding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

describe KyotoTycoon do
  before(:each) do
    @kt = KyotoTycoon.new('localhost', 19999)
    100.times{|n|
      @kt["#{n}foo"] = "foo#{n}"
    }
  end
  it 'should handle cursor' do
    @kt.cur_jump("42foo")
    @kt.cur_get_key.should == "42foo"
    @kt.cur_get_value.should == "foo42"
    @kt.cur_get.should == ["42foo", "foo42"]
    @kt.cur_seize.should == ["42foo", "foo42"]
    @kt["42foo"].should == nil
    @kt.cur_step
    @kt.cur_get_key
    @kt.cur_step_back
    @kt.cur_get_key.should_not == "42foo"
  end

  it 'should handle cursor with option' do
    @kt.cur_jump('42foo')
    @kt.cur_get_key(true).should == '42foo'
    @kt.cur_get_key.should == '43foo'

    @kt.cur_get_value(true).should == 'foo43'
    @kt.cur_get_value.should == 'foo44'
    @kt.cur_set_value('new')
    @kt.cur_get_value.should == 'new'

    @kt.cur_remove
    @kt["foo44"].should == nil
  end

  it 'should handle cur_jump' do
    @kt.cur_jump('55')
    @kt.cur_get_key.should == '55foo'

    @kt.cur_jump_back('66')
    @kt.cur_get_key.should == '65foo'
  end

end
