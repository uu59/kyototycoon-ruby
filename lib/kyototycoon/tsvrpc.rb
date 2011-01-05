# -- coding: utf-8


class KyotoTycoon
  module Tsvrpc
    def self.parse(body, colenc)
      decoder = case colenc
        when "U"
          lambda{|body| CGI.unescape(body)}
        when "B"
          lambda{|body| Base64.decode64(body)}
        when nil
          lambda{|body| body}
        else
          raise "Unknown colenc(response) '#{colenc}'"
      end
      body.split("\n").inject({}){|r, line|
        k,v = *line.split("\t", 2).map{|v| decoder.call(v)}
        r[k] = v
        r
      }
    end

    def self.build_query(params, colenc='U')
      query = ""
      if params
        encoder = case colenc.to_s.upcase.to_sym
          when :U
            lambda{|body| CGI.escape(body.to_s)}
          when :B
            lambda{|body| [body.to_s].pack('m').gsub("\n","")}
          else
            raise "Unknown colenc '#{colenc}'"
        end
        query = params.inject([]){|r, tmp|
          unless tmp.last.nil?
            r << tmp.map{|v| encoder.call(v)}.join("\t")
          end
          r
        }.join("\r\n")
      end
      query
    end
  end
end
