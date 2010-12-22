# -- coding: utf-8

class KyotoTycoon
  module Tsvrpc
    class Skinny
      def initialize(host, port)
        @host = host
        @port = port
        @tpl = ""
        @tpl << "POST %s HTTP/1.1\r\n"
        @tpl << "Content-Length: %d\r\n"
        @tpl << "Content-Type: text/tab-separated-values; colenc=%s\r\n"
        @tpl << "\r\n%s"
      end

      def request(path, params, colenc)
        start 
        query = KyotoTycoon::Tsvrpc.build_query(params, colenc)
        request = @tpl % [path, query.bytesize, colenc, query]
        @sock.write(request)
        first_line = @sock.gets
        status = first_line[9, 3]
        bodylen = 0
        body = ""
        loop do
          line = @sock.gets
          if line['Content-Length']
            bodylen = line.match(/[0-9]+/)[0].to_i
            next
          end
          if line == "\r\n"
            break
          end
        end
        body = @sock.read(bodylen)
        [status.to_i, body]
      end

      def start
        @sock ||= ::TCPSocket.new(@host, @port)
      end

      def finish
        @sock.close if @sock
      end
    end
  end
end
