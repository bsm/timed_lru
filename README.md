# Timed LRU

[![Build Status](https://travis-ci.org/bsm/timed_lru.png)](https://travis-ci.org/bsm/timed_lru)
[![Dependency Status](https://gemnasium.com/bsm/timed_lru.png)](https://gemnasium.com/bsm/timed_lru)

My implementation of a simple, thread-safe LRU with (optional) TTLs
and constant time operations. There are many LRUs for Ruby available but
I was unable to find one that matches all three requirements.

## Install

Install it via `gem`:

```ruby
gem install timed_lru
```

Or just bundle it with your project.

## Usage Example

```ruby
# Initialize with a max size (default: 100) and a TTL (default: none)
lru = TimedLRU.new max_size: 3, ttl: 5

# Add values
lru["a"] = "value 1"
lru["b"] = "value 2"
lru["c"] = "value 3"
lru.keys # => ["a", "b"]

# Wait a second
sleep(1)

# Add more values
lru["d"] = "value 4"
lru.keys # => ["b", "c", "d"]

# Sleep a little longer
sleep(4)
lru["c"] # => "value 3"
lru.keys # => ["c", "d"]
```
