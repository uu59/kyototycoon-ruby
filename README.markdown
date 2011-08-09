KyotoTycoon client for Ruby.

# Feature / Fixture

* cursor object supported(v0.6.0+)
* Usable console as `$ bin/kyototycoon-console -h localhost -p 1991` like a Sequel(v0.5.4+)
* Always Keep-Alive connect (v0.5.0+)
* You can choise key/value encoding from URI or Base64
* You can use MessagePack tranparency
* Benchmark scripts appended(they are connect to localhost:19999)
* Both Ruby versions supported 1.8.7 / 1.9.2

# Install

    $ gem install kyototycoon

# Example

## Simple case

    @kt = KyotoTycoon.new('localhost', 1978)

    # traditional style
    @kt.set('foo', 123)
    p @kt.get('foo') # => "123".  carefully, it is String, not Integer, by default

    # Ruby's hash style
    @kt['bar'] = 42
    p @kt['bar'] # => "42".
    @kt[:baz] = :aaa # => key/value are automatically #to_s

    @kt.delete(:foo)


## Complex case
    # KT#configure for instance setting store.

    KyotoTycoon.configure(:generic) do |kt|
      kt.db = '*' # on memory
    end

    # connect any host, any port
    KyotoTycoon.configure(:favicon, 'remotehost', 12345) do |kt|
      kt.db = 'favicons.kch' # DB file as KT known
    end

    @kt = KyotoTycoon.create(:generic) # got KT instance by KT#configure(:generic) rules

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

    # standby server
    @kt.connect_timeout = 0.5 # => wait 0.5 sec for connection open
    @kt.servers << ['server2', 1978] # standby server that will use when primary server (a.k.a. KT#new(host, port)) is dead.
    @kt.servers << ['server3', 1978] # same as above

    # key/value encoding from :U or :B(default). default as base64 because it seems better than URL encode for me.
    @kt.colenc = :U

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
    @kt['baz'] = {'a' => 'a', 'b' => 'b'}
    @kt['baz'] # => {'a' => 'a', 'b' => 'b}

    # increment
    @kt.increment('bar') # => 1
    @kt.increment('bar') # => 2
    @kt.increment('bar', 10) # => 12
    @kt.increment('bar', -5) # => 7

    # shorthand
    @kt.incr('foo') # => 1
    @kt.decr('foo') # => 0

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

# Cursor samples

For B+Tree type database only.
http://fallabs.com/kyotocabinet/spex.html#tutorial_dbchart

    @kt.clear
    100.times{|n|
      @kt.set("%02d" % n, n) # 00, 01, 02 .. 99
    }
    cur = @kt.cursor
    cur.jump("90")
    cur.each{|k,v| puts v} # => 90, 91, 92 .. 99

    cur.jump("05")
    cur.find_all{|k,v| k.to_i < 10} # => 05, 06, 07, 08, 09. Because it started with 05

# Requirements

- msgpack(optional)

# Other case for `ktremotemgr slave | ...`

    $ cat foo.rb
    require "rubygems"
    require "kyototycoon"

    KyotoTycoon::Stream.run($stdin) do |line|
      case line.cmd
        when 'clear'
          puts "all record cleared!"
        when 'set'
          puts "#{line.key} get #{line.value} value"
        when 'remove'
          puts "#{line.key} is removed at #{line.time.strftime('%Y-%m-%d %H:%M:%S')}"
      end
    end

    $ ktremotemgr slave -uw | ruby foo.rb

# Trap

KyotoTycoon is based on HTTP so all variable types are become String.
It means `(@kt["counter"] ||= 1) < 10` does not work by default.

Using :msgpack serializer for avoid this trap.
