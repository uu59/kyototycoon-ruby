# -- coding: utf-8

class KyotoTycoon
  class Tsvrpc
    class Skinny
      def initialize(host, port)
        @host = host
        @port = port
        @tpl = ""
        @tpl << "POST %s HTTP/1.0\r\n"
        @tpl << "Content-Length: %d\r\n"
        @tpl << "Content-Type: text/tab-separated-values; colenc=%s\r\n"
        @tpl << "\r\n%s"
      end

      def request(path, params, colenc)
        sock ||= ::TCPSocket.new(@host, @port)
        query = KyotoTycoon::Tsvrpc.build_query(params, colenc)
        request = @tpl % [path, query.bytesize, colenc, query]
        sock.write(request)
        status = sock.gets[9, 3]
        bodylen = 0
        body = ""
        loop do
          line = sock.gets
          if line['Content-Length']
            bodylen = line.match(/[0-9]+/)[0].to_i
            next
          end
          if line == "\r\n"
            break
          end
        end
        body = sock.read(bodylen)
        sock.close
        [status.to_i, body]
      end
    end
  end
end
