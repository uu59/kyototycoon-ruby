# -- coding: utf-8

require "rubygems"

class KyotoTycoon
  class Tsvrpc
    class Nethttp
      def initialize(host, port)
        @host = host
        @port = port
        @http ||= ::Net::HTTP.new(@host, @port)
      end

      def request(path, params)
        query = KyotoTycoon::Tsvrpc.build_query(params)
        req = Net::HTTP::Post.new(path)
        if query.length > 0
          req.body = query
          req['Content-Length'] = query.size
        end
        req['Content-Type'] = "application/x-www-form-urlencoded"
        req['Connection'] = "close"
        res = @http.request(req)
        [res.code.to_i, res.body]
      end
    end
  end
end
