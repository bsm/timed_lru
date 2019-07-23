require 'spec_helper'

describe TimedLRU do

  subject { described_class.new max_size: 4 }

  def full_chain
    return [] unless head

    res = [head]
    loop do
      current = res.last.right
      break unless current

      expect(current.left).to eq(res.last)
      res << current
    end
    expect(head.left).to be_nil
    expect(tail.right).to be_nil
    expect(res.last).to eq(tail)
    res
  end

  def chain
    full_chain.map(&:key)
  end

  def head
    subject.instance_variable_get(:@head)
  end

  def tail
    subject.instance_variable_get(:@tail)
  end

  describe 'defaults' do
    subject { described_class.new }

    describe '#max_size' do
      subject { super().max_size }
      it { is_expected.to be(100) }
    end

    describe '#ttl' do
      subject { super().ttl }
      it { is_expected.to be_nil }
    end

    it { is_expected.to be_a(MonitorMixin) }
    it { is_expected.not_to be_a(described_class::ThreadUnsafe) }
    it { is_expected.to respond_to(:empty?) }
    it { is_expected.to respond_to(:keys) }
    it { is_expected.to respond_to(:size) }
    it { is_expected.to respond_to(:each_key) }
  end

  describe 'init' do
    subject { described_class.new max_size: 25, ttl: 120, thread_safe: false }

    describe '#max_size' do
      subject { super().max_size }
      it { is_expected.to be(25) }
    end

    describe '#ttl' do
      subject { super().ttl }
      it { is_expected.to be(120) }
    end
    it { is_expected.to be_a(described_class::ThreadUnsafe) }

    it 'should assert correct option values' do
      expect { described_class.new(max_size: 'X') }.to raise_error(ArgumentError)
      expect { described_class.new(max_size: -1) }.to raise_error(ArgumentError)
      expect { described_class.new(max_size: 0) }.to raise_error(ArgumentError)

      expect { described_class.new(ttl: 'X') }.to raise_error(ArgumentError)
      expect { described_class.new(ttl: true) }.to raise_error(TypeError)
      expect { described_class.new(ttl: 0) }.to raise_error(ArgumentError)
    end
  end

  describe 'storing' do

    it 'should set head + tail on first item' do
      expect do
        expect(subject.store('a', 1)).to eq(1)
      end.to change { chain }.from([]).to(['a'])
    end

    it 'should shift chain when new items are added' do
      subject['a'] = 1
      expect { subject['b'] = 2 }.to change { chain }.from(%w[a]).to(%w[b a])
      expect { subject['c'] = 3 }.to change { chain }.to(%w[c b a])
      expect { subject['d'] = 4 }.to change { chain }.to(%w[d c b a])
    end

    it 'should expire LRU items when chain exceeds max size' do
      ('a'..'d').each {|x| subject[x] = 1 }
      expect { subject['e'] = 5 }.to change { chain }.to(%w[e d c b])
      expect { subject['f'] = 6 }.to change { chain }.to(%w[f e d c])
    end

    it 'should update items' do
      ('a'..'d').each {|x| subject[x] = 1 }
      expect { subject['d'] = 2 }.not_to change { chain }
      expect { subject['c'] = 2 }.to change { chain }.to(%w[c d b a])
      expect { subject['b'] = 2 }.to change { chain }.to(%w[b c d a])
      expect { subject['a'] = 2 }.to change { chain }.to(%w[a b c d])
    end

  end

  describe 'retrieving' do

    it 'should fetch values' do
      expect(subject.fetch('a')).to be_nil
      expect(subject['a']).to be_nil
      subject['a'] = 1
      expect(subject['a']).to eq(1)
    end

    it 'should renew membership on access' do
      ('a'..'d').each {|x| subject[x] = 1 }
      expect { subject['d'] }.not_to change { chain }
      expect { subject['c'] }.to change { chain }.to(%w[c d b a])
      expect { subject['b'] }.to change { chain }.to(%w[b c d a])
      expect { subject['a'] }.to change { chain }.to(%w[a b c d])
      expect { subject['x'] }.not_to change { chain }
    end

  end

  describe 'deleting' do

    it 'should delete an return values' do
      expect(subject.delete('a')).to be_nil
      subject['a'] = 1
      expect(subject.delete('a')).to eq(1)
    end

    it 'should re-arrange membership chain' do
      ('a'..'d').each {|x| subject[x] = 1 }
      expect { subject.delete('x') }.not_to change { chain }
      expect { subject.delete('c') }.to change { chain }.to(%w[d b a])
      expect { subject.delete('a') }.to change { chain }.to(%w[d b])
      expect { subject.delete('d') }.to change { chain }.to(%w[b])
      expect { subject.delete('b') }.to change { subject.size }.from(1).to(0)
    end

  end

  describe 'TTL expiration' do
    subject { described_class.new max_size: 4, ttl: 60 }

    def in_past(ago)
      allow(Time).to receive_messages now: (Time.now - ago)
      yield
    ensure
      allow(Time).to receive(:now).and_call_original
    end

    it 'should expire on access' do
      in_past(70) do
        subject['a'] = 1
        expect(chain).to eq(%w[a])
      end

      in_past(50) do
        subject['b'] = 2
        expect(chain).to eq(%w[b a])
      end

      subject['c'] = 3
      expect(chain).to eq(%w[c b])
    end

    it 'should renew expiration on access' do
      in_past(70) do
        subject['a'] = 1
        subject['b'] = 2
        expect(chain).to eq(%w[b a])
      end

      in_past(50) do
        expect(subject['a']).to eq(1)
        expect(chain).to eq(%w[a b])
      end

      subject['c'] = 3
      expect(chain).to eq(%w[c a])
    end

  end

end
