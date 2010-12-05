# Example

## Simple case

    @kt = KyotoTycoon.new

    # traditional style
    @kt.set('foo', 123)
    p @kt.get('foo') # => "123".  carefully, it is String, not Integer, by default

    # Ruby's hash style
    @kt['bar'] = 42
    p @kt['bar'] # => "42".
    @kt[:baz] = :aaa # => key/value are automatically #to_s

    @kt.delete(:foo)


## Complex case

    @kt = KyotoTycoon.new('remotehost', 12345) # connect any host, any port
    @kt.db = '*' # on memory, or DB file as KT known
    @kt.logger = 'ktlib.log' # => logfile or such as STDERR

    # using HTTP Keep-Alive.
    # `false` is default because seems like `true` has some problems(slow, and record consistency broken) on my environment.
    @kt.keepalive = true

    # set/bulk_set/get/bulk_get uses msgpack. default as :default
    @kt.serializer = :msgpack

    @kt.set('foo', 42, 100) # => expire at 100 seconds after
    @kt['foo'] # => 42. it is interger by msgpack serializer works
    @kt.increment('bar') # => 1
    @kt.increment('bar') # => 2
    @kt.increment('bar', 10) # => 12

    # it can store when msgpack using.
    @kt['baz'] = {'a' => 'a', 'b' => 'b}
    @kt['baz'] # => {'a' => 'a', 'b' => 'b}

    @kt.clear # delete all record
    @kt.set_bulk({
      'foo' => 'foo',
      'bar' => 'bar',
    })
    @kt.get_bulk([:foo, 'bar']) # => {'_foo' => 'foo', '_bar' => 'bar', 'num' => '2'}
    @kt.remove_bulk([:foo, :bar])

# Requirements

- msgpack(optinal)

# Trap

KyotoTycoon is based on HTTP so all variable types are become String.
It means `(@kt["counter"] ||= 1) < 10` does not work by default.

Using :msgpack serializer for avoid this trap.
