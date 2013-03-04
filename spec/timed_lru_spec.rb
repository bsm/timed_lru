require 'spec_helper'

describe TimedLRU do

  subject { described_class.new max_size: 4 }

  def full_chain
    return [] unless head

    res = [head]
    while curr = res.last.right
      curr.left.should == res.last
      res << curr
    end
    head.left.should be_nil
    tail.right.should be_nil
    res.last.should == tail
    res
  end

  def chain
    full_chain.map &:key
  end

  def head
    subject.instance_variable_get(:@head)
  end

  def tail
    subject.instance_variable_get(:@tail)
  end

  describe "defaults" do
    subject { described_class.new }

    its(:max_size) { should be(100) }
    its(:ttl)      { should be_nil }
    it             { should be_a(MonitorMixin) }
    it             { should_not be_a(described_class::ThreadUnsafe) }
    it             { should respond_to(:empty?) }
    it             { should respond_to(:keys) }
    it             { should respond_to(:size) }
    it             { should respond_to(:each_key) }
  end

  describe "init" do
    subject { described_class.new max_size: 25, ttl: 120, thread_safe: false }

    its(:max_size) { should be(25) }
    its(:ttl)      { should be(120) }
    it             { should be_a(described_class::ThreadUnsafe) }

    it 'should assert correct option values' do
      lambda { described_class.new(max_size: "X") }.should raise_error(ArgumentError)
      lambda { described_class.new(max_size: -1) }.should raise_error(ArgumentError)
      lambda { described_class.new(max_size: 0) }.should raise_error(ArgumentError)

      lambda { described_class.new(ttl: "X") }.should raise_error(ArgumentError)
      lambda { described_class.new(ttl: true) }.should raise_error(TypeError)
      lambda { described_class.new(ttl: 0) }.should raise_error(ArgumentError)
    end
  end

  describe "storing" do

    it "should set head + tail on first item" do
      lambda {
        subject.store("a", 1).should == 1
      }.should change { chain }.from([]).to(["a"])
    end

    it "should shift chain when new items are added" do
      subject["a"] = 1
      lambda { subject["b"] = 2 }.should change { chain }.from(%w|a|).to(%w|b a|)
      lambda { subject["c"] = 3 }.should change { chain }.to(%w|c b a|)
      lambda { subject["d"] = 4 }.should change { chain }.to(%w|d c b a|)
    end

    it "should expire LRU items when chain exceeds max size" do
      ("a".."d").each {|x| subject[x] = 1 }
      lambda { subject["e"] = 5 }.should change { chain }.to(%w|e d c b|)
      lambda { subject["f"] = 6 }.should change { chain }.to(%w|f e d c|)
    end

    it "should update items" do
      ("a".."d").each {|x| subject[x] = 1 }
      lambda { subject["d"] = 2 }.should_not change { chain }
      lambda { subject["c"] = 2 }.should change { chain }.to(%w|c d b a|)
      lambda { subject["b"] = 2 }.should change { chain }.to(%w|b c d a|)
      lambda { subject["a"] = 2 }.should change { chain }.to(%w|a b c d|)
    end

  end

  describe "retrieving" do

    it 'should fetch values' do
      subject.fetch("a").should be_nil
      subject["a"].should be_nil
      subject["a"] = 1
      subject["a"].should == 1
    end

    it 'should renew membership on access' do
      ("a".."d").each {|x| subject[x] = 1 }
      lambda { subject["d"] }.should_not change { chain }
      lambda { subject["c"] }.should change { chain }.to(%w|c d b a|)
      lambda { subject["b"] }.should change { chain }.to(%w|b c d a|)
      lambda { subject["a"] }.should change { chain }.to(%w|a b c d|)
      lambda { subject["x"] }.should_not change { chain }
    end

  end

  describe "deleting" do

    it 'should delete an return values' do
      subject.delete("a").should be_nil
      subject["a"] = 1
      subject.delete("a").should == 1
    end

    it 'should re-arrange membership chain' do
      ("a".."d").each {|x| subject[x] = 1 }
      lambda { subject.delete("x") }.should_not change { chain }
      lambda { subject.delete("c") }.should change { chain }.to(%w|d b a|)
      lambda { subject.delete("a") }.should change { chain }.to(%w|d b|)
      lambda { subject.delete("d") }.should change { chain }.to(%w|b|)
      lambda { subject.delete("b") }.should change { subject.size }.from(1).to(0)
    end

  end

  describe "TTL expiration" do
    subject    { described_class.new max_size: 4, ttl: 60 }

    def in_past(ago)
      Time.stub now: (Time.now - ago)
      yield
    ensure
      Time.unstub :now
    end

    it 'should expire on access' do
      in_past(70) do
        subject["a"] = 1
        chain.should == %w|a|
      end

      in_past(50) do
        subject["b"] = 2
        chain.should == %w|b a|
      end

      subject["c"] = 3
      chain.should == %w|c b|
    end

    it 'should renew expiration on access' do
      in_past(70) do
        subject["a"] = 1
        subject["b"] = 2
        chain.should == %w|b a|
      end

      in_past(50) do
        subject["a"].should == 1
        chain.should == %w|a b|
      end

      subject["c"] = 3
      chain.should == %w|c a|
    end

  end

end