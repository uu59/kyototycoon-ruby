# -- coding: utf-8

require "logger"
require "cgi"
require "net/http"
require "kyoto_tycoon/serializer.rb"
require "kyoto_tycoon/serializer/default.rb"
require "kyoto_tycoon/tsvrpc.rb"
require "kyoto_tycoon/tsvrpc/skinny.rb"
require "kyoto_tycoon/tsvrpc/nethttp.rb"

class KyotoTycoon
  attr_reader :tsvrpc

  def initialize(host='0.0.0.0', port=1978)
    @host = host
    @port = port
    @serializer = KyotoTycoon::Serializer::Default
    @tsvrpc = Tsvrpc.new(@host, @port)
    @logger = Logger.new(nil)
    @agent = :nethttp
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

  def agent=(agent)
    @agent = agent
  end

  def get(key)
    res = request('/rpc/get', {:key => key})
    @serializer.decode(Tsvrpc.parse(res[:body])['value'])
  end
  alias_method :[], :get

  def remove(key)
    request('/rpc/remove', {:key => key})
  end
  alias_method :delete, :remove

  def set(key, value, xt=nil)
    res = request('/rpc/set', {:key => key, :value => @serializer.encode(value), :xt => xt})
    Tsvrpc.parse(res[:body])
  end
  def []= (key, xt=nil, value)
    set(key, value, xt)
  end

  def add(key, value, xt=nil)
    res = request('/rpc/add', {:key => key, :value => @serializer.encode(value), :xt => xt})
    Tsvrpc.parse(res[:body])
  end

  def replace(key, value, xt=nil)
    res = request('/rpc/replace', {:key => key, :value => @serializer.encode(value), :xt => xt})
    Tsvrpc.parse(res[:body])
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
    Tsvrpc.parse(res[:body])['num'].to_i
  end

  def increment_double(key, num, xt=nil)
    res = request('/rpc/increment_double', {:key => key, :num => num, :xt => xt})
    Tsvrpc.parse(res[:body])['num'].to_f
  end

  def set_bulk(records)
    # records={'a' => 'aa', 'b' => 'bb'}
    values = {}
    records.each{|k,v|
      values["_#{k}"] = @serializer.encode(v)
    }
    res = request('/rpc/set_bulk', values)
    Tsvrpc.parse(res[:body])
  end

  def get_bulk(keys)
    params = keys.inject({}){|params, k|
      params[k.to_s.match(/^_/) ? k.to_s : "_#{k}"] = ''
      params
    }
    res = request('/rpc/get_bulk', params)
    ret = {}
    Tsvrpc.parse(res[:body]).each{|k,v|
      ret[k] = k.match(/^_/) ? @serializer.decode(v) : v
    }
    ret
  end

  def remove_bulk(keys)
    params = keys.inject({}){|params, k|
      params[k.to_s.match(/^_/) ? k.to_s : "_#{k}"] = ''
      params
    }
    res = request('/rpc/remove_bulk', params)
    Tsvrpc.parse(res[:body])
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
    Tsvrpc.parse(res[:body])
  end

  def report
    res = request('/rpc/report')
    Tsvrpc.parse(res[:body])
  end

  def status
    res = request('/rpc/status')
    Tsvrpc.parse(res[:body])
  end

  def match_prefix(prefix)
    res = request('/rpc/match_prefix', {:prefix => prefix})
    Tsvrpc.parse(res[:body])
  end

  def match_regex(re)
    if re.class == Regexp
      re = re.source
    end
    res = request('/rpc/match_regex', {:regex => re})
    Tsvrpc.parse(res[:body])
  end

  def request(path, params=nil)
    if @db
      params ||= {}
      params[:DB] = @db
    end
    res = @tsvrpc.request(path, :post, params, @agent)
    @logger.info("#{path}: #{res[:code]} with query parameters #{params.inspect}")
    res
  end
end
