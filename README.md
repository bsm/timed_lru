Timed LRU
=========

[![Build Status](https://secure.travis-ci.org/bsm/timed_lru.png)](http://travis-ci.org/bsm/timed_lru)
[![Dependency Status](https://gemnasium.com/bsm/timed_lru.png)](https://gemnasium.com/bsm/timed_lru)
[![Coverage Status](https://coveralls.io/repos/bsm/timed_lru/badge.png)](https://coveralls.io/r/bsm/timed_lru)

My implementation of a simple, thread-safe LRU with (optional) TTLs
and constant time operations. There are many LRUs for Ruby available but
I was unable to find one that matches all three requirements.

Install
-------

Install it via `gem`:

```ruby
gem install timed_lru
```

Or just bundle it with your project.

Usage Example
-------------

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

Licence
-------

```
Copyright (c) 2013 Black Square Media Ltd

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
