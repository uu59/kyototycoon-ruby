# -- coding: utf-8


class KyotoTycoon
  class Tsvrpc
    def initialize(host, port)
      @host = host
      @port = port
    end

    def http(agent)
      case agent
        when :skinny
          Skinny.new(@host, @port)
        else
          Nethttp.new(@host, @port)
      end
    end

    def request(path, params, agent)
      status,body = *http(agent).request(path, params)
      if ![200, 450].include?(status)
        raise body
      end
      {:status => status, :body => body}
    end

    def self.parse(body)
      body.split("\n").inject({}){|r, line|
        k,v = *line.split("\t", 2).map{|v| CGI.unescape(v)}
        r[k] = v
        r
      }
    end

    def self.build_query(params)
      query = ""
      if params
        query = params.inject([]){|r, tmp|
          r << tmp.map{|v| CGI.escape(v.to_s)}.join("=")
        }.join("&")
      end
      query
    end
  end
end
