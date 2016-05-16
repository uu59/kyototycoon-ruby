# -- coding: utf-8

require "logger"
require "cgi"
require "socket"
require "base64"
require "timeout"
require "kyototycoon/cursor.rb"
require "kyototycoon/serializer.rb"
require "kyototycoon/serializer/default.rb"
require "kyototycoon/serializer/msgpack.rb"
require "kyototycoon/tsvrpc.rb"
require "kyototycoon/tsvrpc/skinny.rb"
require "kyototycoon/stream.rb"

class KyotoTycoon
  VERSION = '0.6.1'

  attr_accessor :colenc, :connect_timeout, :servers
  attr_reader :serializer, :logger, :db

  DEFAULT_HOST = '0.0.0.0'
  DEFAULT_PORT = 1978

  def self.configure(name, host=DEFAULT_HOST, port=DEFAULT_PORT, &block)
    @configure ||= {}
    if @configure[name]
      raise "'#{name}' is registered"
    end
    @configure[name] = lambda{
      kt = KyotoTycoon.new(host, port)
      block.call(kt)
      kt
    }
  end

  def self.configures
    @configure
  end

  def self.configure_reset!
    @configure = {}
  end
  
  def self.create(name)
    if @configure[name].nil?
      raise "undefined configure: '#{name}'"
    end
    @configure[name].call
  end

  def initialize(host=DEFAULT_HOST, port=DEFAULT_PORT)
    @servers = [[host, port]]
    @checked_servers = nil
    @serializer = KyotoTycoon::Serializer::Default
    @logger = Logger.new(nil)
    @colenc = :B
    @connect_timeout = 0.5
    @cursor = 1
  end

  def serializer= (adaptor=:default)
    klass = KyotoTycoon::Serializer.get(adaptor)
    @serializer = klass
  end

  def db= (db)
    @db = db
  end

  def logger= (logger)
    if logger.class != Logger
      logger = Logger.new(logger)
    end
    @logger = logger
  end

  def get(key)
    res = request('/rpc/get', {:key => key})
    @serializer.decode(Tsvrpc.parse(res[:body], res[:colenc])['value'])
  end
  alias_method :[], :get

  def remove(*keys)
    remove_bulk(keys.flatten)
  end
  alias_method :delete, :remove

  def set(key, value, xt=nil)
    res = request('/rpc/set', {:key => key, :value => @serializer.encode(value), :xt => xt})
    Tsvrpc.parse(res[:body], res[:colenc])
  end
  alias_method :[]=, :set

  def add(key, value, xt=nil)
    res = request('/rpc/add', {:key => key, :value => @serializer.encode(value), :xt => xt})
    Tsvrpc.parse(res[:body], res[:colenc])
  end

  def replace(key, value, xt=nil)
    res = request('/rpc/replace', {:key => key, :value => @serializer.encode(value), :xt => xt})
    Tsvrpc.parse(res[:body], res[:colenc])
  end

  def append(key, value, xt=nil)
    request('/rpc/append', {:key => key, :value => @serializer.encode(value), :xt => xt})
  end

  def cas(key, oldval, newval, xt=nil)
    res = request('/rpc/cas', {:key => key, :oval=> @serializer.encode(oldval), :nval => @serializer.encode(newval), :xt => xt})
    case res[:status].to_i
      when 200
        true
      when 450
        false
    end
  end

  def increment(key, num=1, xt=nil)
    res = request('/rpc/increment', {:key => key, :num => num, :xt => xt})
    Tsvrpc.parse(res[:body], res[:colenc])['num'].to_i
  end
  alias_method :incr, :increment

  def decrement(key, num=1, xt=nil)
    increment(key, num * -1, xt)
  end
  alias_method :decr, :decrement

  def increment_double(key, num, xt=nil)
    res = request('/rpc/increment_double', {:key => key, :num => num, :xt => xt})
    Tsvrpc.parse(res[:body], res[:colenc])['num'].to_f
  end

  def set_bulk(records)
    # records={'a' => 'aa', 'b' => 'bb'}
    values = {}
    records.each{|k,v|
      values[k.to_s.match(/^_/) ? k.to_s : "_#{k}"] = @serializer.encode(v)
    }
    res = request('/rpc/set_bulk', values)
    Tsvrpc.parse(res[:body], res[:colenc])
  end

  def get_bulk(keys)
    params = keys.inject({}){|params, k|
      params[k.to_s.match(/^_/) ? k.to_s : "_#{k}"] = ''
      params
    }
    res = request('/rpc/get_bulk', params)
    bulk = Tsvrpc.parse(res[:body], res[:colenc])
    bulk.delete_if{|k,v| k.match(/^[^_]/)}.inject({}){|r, (k,v)|
      r[k[1..-1]] = @serializer.decode(v)
      r
    }
  end

  def remove_bulk(keys)
    params = keys.inject({}){|params, k|
      params[k.to_s.match(/^_/) ? k.to_s : "_#{k}"] = ''
      params
    }
    res = request('/rpc/remove_bulk', params)
    Tsvrpc.parse(res[:body], res[:colenc])
  end

  def cursor(cur_id=nil)
    Cursor.new(self, cur_id || @cursor += 1)
  end

  def clear
    request('/rpc/clear')
  end

  def vacuum
    request('/rpc/vacuum')
  end

  def sync(params={})
    request('/rpc/synchronize', params)
  end
  alias_method :syncronize, :sync

  def echo(value)
    res = request('/rpc/echo', value)
    Tsvrpc.parse(res[:body], res[:colenc])
  end

  def report
    res = request('/rpc/report')
    Tsvrpc.parse(res[:body], res[:colenc])
  end

  def status
    res = request('/rpc/status')
    Tsvrpc.parse(res[:body], res[:colenc])
  end

  def match_prefix(prefix)
    res = request('/rpc/match_prefix', {:prefix => prefix})
    keys = []
    Tsvrpc.parse(res[:body], res[:colenc]).each{|k,v|
      if k != 'num'
        keys << k[1, k.length]
      end
    }
    keys
  end

  def match_regex(re)
    if re.class == Regexp
      re = re.source
    end
    res = request('/rpc/match_regex', {:regex => re})
    keys = []
    Tsvrpc.parse(res[:body], res[:colenc]).each{|k,v|
      if k != 'num'
        keys << k[1, k.length]
      end
    }
    keys
  end

  def keys
    match_prefix("")
  end

  def request(path, params=nil)
    if @db
      params ||= {}
      params[:DB] = @db
    end

    status,body,colenc = client.request(path, params, @colenc)
    if ![200, 450].include?(status.to_i)
      raise body
    end
    res = {:status => status, :body => body, :colenc => colenc}
    @logger.info("#{path}: #{res[:status]} with query parameters #{params.inspect}")
    res
  end

  def client
    host, port = *choice_server
    @client ||= begin
      Tsvrpc::Skinny.new(host, port)
    end
  end

  def start
    client.start
  end

  def finish
    client.finish
  end

  private

  def ping(host, port)
    begin
      rpc = Tsvrpc::Skinny.new(host, port)
      Timeout.timeout(@connect_timeout){
        @logger.debug("connect check #{host}:#{port}")
        res = rpc.request('/rpc/echo', {'0' => '0'}, :U)
        @logger.debug(res)
      }
      true
    rescue Timeout::Error => ex
      # Ruby 1.8.7 compatible
      @logger.warn("connect failed at #{host}:#{port}")
      false
    rescue SystemCallError
      @logger.warn("connect failed at #{host}:#{port}")
      false
    rescue => ex
      @logger.warn("connect failed at #{host}:#{port}")
      false
    ensure
      # for 1.8.7
      rpc.finish
    end
  end

  def choice_server
    if @checked_servers
      return @checked_servers
    end

    @servers.each{|s|
      host,port = *s
      if ping(host, port)
        @checked_servers = [host, port]
        break
      end
    }
    if @checked_servers.nil?
      msg = "alived server not exists"
      @logger.fatal(msg)
      raise msg
    end
    @checked_servers
  end

end
