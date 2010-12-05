# -- coding: utf-8


class KyotoTycoon
  class Tsvrpc
    def initialize(host, port)
      @host = host
      @port = port
    end

    def nethttp
      @http ||= ::Net::HTTP.new(@host, @port)
    end

    def request(path, method, params)
      method = method.downcase.to_sym
      res = request_nethttp(path, method, params)
      if !["200", "450"].include?(res.code)
        raise res.body
      end
      res
    end

    def request_nethttp(path, method, params)
      if params
        query = params.inject([]){|r, tmp|
          r << tmp.map{|v| CGI.escape(v.to_s)}.join("=")
        }.join("&")
      end
      case method
        when :get
          if query
            path += query
          end
          req = Net::HTTP::Get.new(path)
        when :post
          req = Net::HTTP::Post.new(path)
          if query
            req.body = query
            req['Content-Length'] = query.size
          end
          req['Content-Type'] = "application/x-www-form-urlencoded"
        when :put
          req = Net::HTTP::Put.new
        when :delete
          req = Net::HTTP::Delete.new
      end
      res = nethttp.request(req)
    end

    def self.parse(body)
      body.split("\n").map{|line|
        line.split("\t", 2).map{|v| CGI.unescape(v)}
      }.inject({}){|r,tmp|
        r[tmp.first] = tmp.last
        r
      }
    end
  end
end
