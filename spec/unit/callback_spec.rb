require 'spec_helper'

describe ActiveFedora::Base do
  before :all do
    class CallbackStub < ActiveFedora::Base
      has_metadata :type=>ActiveFedora::MetadataDatastream, :name=>"someData" do |m|
        m.field "fubar", :string
        m.field "swank", :text
      end
      delegate :fubar, :to=>'someData'
      delegate :swank, :to=>'someData'

      after_initialize :a_init
      before_assign_pid :b_assign_pid
      after_assign_pid :a_assign_pid
      before_save :b_save
      after_save :a_save
      before_create :b_create
      after_create :a_create
      before_update :b_update
      after_update :a_update
      after_find :a_find
      
    end
  end
  after :all do
    Object.send(:remove_const, :CallbackStub)
  end

  it "Should have after_initialize, before_save,after_save, before_create, after_create, after_update, before_update" do
    CallbackStub.any_instance.expects(:a_init).twice
    CallbackStub.any_instance.expects :b_create
    CallbackStub.any_instance.expects :a_create
    CallbackStub.any_instance.expects(:a_assign_pid)
    CallbackStub.any_instance.expects(:b_assign_pid)
    CallbackStub.any_instance.expects(:b_save).twice
    CallbackStub.any_instance.expects(:a_save).twice
    CallbackStub.any_instance.expects(:a_find)
    CallbackStub.any_instance.expects(:b_update)
    CallbackStub.any_instance.expects(:a_update)
    cb = CallbackStub.new
    cb.save

    cb2 = CallbackStub.find(cb.pid)
    cb2.save
  end

end
