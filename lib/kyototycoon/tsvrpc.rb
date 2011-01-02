# -- coding: utf-8


class KyotoTycoon
  module Tsvrpc
    def self.parse(body, colenc)
      decoder = case colenc
        when "B"
          lambda{|body| Base64.decode64(body)}
        when "U"
          lambda{|body| CGI.unescape(body)}
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
        case colenc.to_s.upcase.to_sym
          when :U
            query = params.inject([]){|r, tmp|
              unless tmp.last.nil?
                r << tmp.map{|v| CGI.escape(v.to_s)}.join("\t")
              end
              r
            }.join("\r\n")
          when :B
            query = params.inject([]){|r, tmp|
              unless tmp.last.nil?
                r << tmp.map{|v| Base64.encode64(v.to_s).rstrip}.join("\t")
              end
              r
            }.join("\r\n")
          else
            raise "Unknown colenc '#{colenc}'"
        end
      end
      query
    end
  end
end
