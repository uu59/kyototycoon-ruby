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

    # set/bulk_set/get/bulk_get uses msgpack. default as :default
    @kt.serializer = :msgpack

    # KT library logging
    logger = Logger.new(STDERR)
    logger.level = Logger::WARN
    @kt.logger = logger
    # or you can use these:
    # @kt.logger = 'ktlib.log'
    # @kt.logger = STDOUT
    # @kt.logger = Logger.new(STDOUT)

    # HTTP agent
    @kt.agent = :skinny # low-level socket communicate. a bit of faster than :nethttp(default). try benchmark/agent.rb

    # standby server
    @kt.connect_timeout = 0.5 # => wait 0.5 sec for connection open
    @kt.add_server('server2', 1978) # standby server that will use when primary server (a.k.a. KT#new(host, port)) is dead.
    @kt.add_server('server3', 1978) # same as above

    # get/set
    @kt.set('foo', 42, 100) # => expire at 100 seconds after
    @kt['foo'] # => 42. it is interger by msgpack serializer works

    # delete all record
    @kt.clear

    # bulk set/get
    @kt.set_bulk({
      'foo' => 'foo',
      'bar' => 'bar',
    })
    @kt.get_bulk([:foo, 'bar']) # => {'_foo' => 'foo', '_bar' => 'bar', 'num' => '2'}
    @kt.remove_bulk([:foo, :bar])

    # it can store when msgpack using.
    @kt['baz'] = {'a' => 'a', 'b' => 'b}
    @kt['baz'] # => {'a' => 'a', 'b' => 'b}

    # increment
    @kt.increment('bar') # => 1
    @kt.increment('bar') # => 2
    @kt.increment('bar', 10) # => 12
    @kt.increment('bar', -5) # => 7

    # delete keys
    @kt.delete(:foo, :bar, :baz)

    # prefix keys
    @kt.match_prefix('fo') # => all start with 'fo' keys
    @kt.match_regex('^fo') # => save as above
    @kt.match_regex(/^fo/) # => save as above

    # reporting / statistics
    p @kt.report
    p @kt.status
    all_record_count = @kt.status['count']

# Requirements

- msgpack(optional)

# Trap

KyotoTycoon is based on HTTP so all variable types are become String.
It means `(@kt["counter"] ||= 1) < 10` does not work by default.

Using :msgpack serializer for avoid this trap.
