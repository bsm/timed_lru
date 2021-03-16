require 'monitor'
require 'forwardable'

class TimedLRU
  include MonitorMixin
  extend Forwardable

  module ThreadUnsafe
    def mon_synchronize
      yield
    end
  end

  Node = Struct.new(:key, :value, :left, :right, :expires_at)
  def_delegators :@hash, :size, :keys, :each_key, :empty?

  # @attr_reader [Integer] max_size
  attr_reader :max_size

  # @attr_reader [Integer,NilClass] ttl
  attr_reader :ttl

  # @param [Hash] opts options
  # @option opts [Integer] max_size
  #   maximum allowed number of items, defaults to 100
  # @option opts [Integer,Float] ttl
  #   the TTL in seconds
  # @option opts [Boolean] thread_safe
  #   true by default, set to false if you are not using threads a *really* need
  #   that extra bit of performance
  def initialize(max_size: 100, ttl: nil, thread_safe: true)
    super() # MonitorMixin

    @hash     = {}
    @max_size = Integer(max_size)
    @ttl      = Float(ttl) if ttl

    raise ArgumentError, 'Option :max_size must be > 0' unless max_size.positive?
    raise ArgumentError, 'Option :ttl must be > 0' unless ttl.nil? || ttl.positive?

    extend ThreadUnsafe if thread_safe == false
  end

  # Stores a `value` by `key`
  # @param [Object] key the storage key
  # @param [Object] value the associated value
  # @return [Object] the value
  def store(key, value)
    mon_synchronize do
      node = (@hash[key] ||= Node.new(key))
      node.value = value
      touch(node)
      compact!
      node.value
    end
  end
  alias []= store

  # Retrieves a `value` by `key`
  # @param [Object] key the storage key
  # @return [Object,NilClass] value the associated value (or nil)
  def fetch(key)
    mon_synchronize do
      node = @hash[key]
      break unless node

      touch(node)
      node.value
    end
  end
  alias [] fetch

  # Deletes by `key`
  # @param [Object] key the storage key
  # @return [Object,NilClass] value the deleted value (or nil)
  def delete(key)
    mon_synchronize do
      node = @hash[key]
      remove(node).value if node
    end
  end

  private

  def compact!
    remove(@tail) while @hash.size > max_size
    remove(@tail) while ttl && @tail.expires_at < Time.now.to_f
  end

  def remove(node)
    @hash.delete(node.key)
    left = node.left
    right = node.right
    left.nil?  ? @head = right : left.right = right
    right.nil? ? @tail = left : right.left = left
    node
  end

  def touch(node)
    node.expires_at = Time.now.to_f + ttl if ttl
    return if node == @head

    left = node.left
    right = node.right
    node.left = nil
    node.right = @head
    @head.left = node if @head

    left.right = right if left
    right.left = left  if right

    @tail = left if @tail == node
    @head = node
    @tail ||= @head
  end
end
