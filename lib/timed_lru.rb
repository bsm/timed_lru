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
  # @option opts [Boolean] thread_safe
  #   true by default, set to false if you are not using threads a *really* need
  #   that extra bit of performance
  # @option opts [Integer] ttl
  #   the TTL in seconds
  def initialize(opts = {})
    super() # MonitorMixin

    @hash     = {}
    @max_size = Integer(opts[:max_size] || 100)
    @ttl      = Integer(opts[:ttl]) if opts[:ttl]

    raise ArgumentError, "Option :max_size must be > 0" unless max_size > 0
    raise ArgumentError, "Option :ttl must be > 0" unless ttl.nil? || ttl > 0

    extend ThreadUnsafe if opts[:thread_safe] == false
  end

  # Stores a `value` by `key`
  # @param [Object] key the storage key
  # @param [Object] value the associated value
  # @return [Object] the value
  def store(key, value)
    mon_synchronize do
      node = (@hash[key] ||= Node.new(key))
      node.value      = value
      touch(node)
      compact!
      node.value
    end
  end
  alias_method :[]=, :store

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
  alias_method :[], :fetch

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
      while @hash.size > max_size
        remove(@tail)
      end

      while ttl && @tail.expires_at < Time.now.to_i
        remove(@tail)
      end
    end

    def remove(node)
      @hash.delete(node.key)
      left, right = node.left, node.right
      left.nil?  ? @head = right : left.right = right
      right.nil? ? @tail = left : right.left = left
      node
    end

    def touch(node)
      node.expires_at = Time.now.to_i + ttl if ttl
      return if node == @head

      left, right = node.left, node.right
      node.left, node.right = nil, @head
      @head.left = node if @head

      left.right = right if left
      right.left = left  if right

      @tail = left if @tail == node
      @head = node
      @tail = @head unless @tail
    end

end
