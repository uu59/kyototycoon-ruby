# -- coding: utf-8

=begin
$ cat foo.rb
require "rubygems"
require "kyototycoon"

KyotoTycoon::Stream.run($stdin) do |line|
  ... do some stuff ..
end

$ ktremotemgr slave -uw | ruby foo.rb
=end

class KyotoTycoon
  module Stream
    def self.run(io=$stdin, &block)
      io.each_line{|line|
        line = Line.new(*line.strip.split("\t", 5))
        block.call(line)
      }
    end

    class Line < Struct.new(:ts, :sid, :db, :cmd, :raw_args)
      def args
        @args ||= begin
          return [] if raw_args.nil?
          k,v = *raw_args.split("\t").map{|v| v.unpack('m').first}
          return [k] unless v
          xt = 0
          v.unpack('C5').each{|num|
            xt = (xt << 8) +  num
          }
          v = v[5, v.length]
          [k, v, xt]
        end
      end

      def key
        @key ||= begin
          args.first || nil
        end
      end

      def value
        @value ||= begin
          args[1] || nil
        end
      end

      def xt
        @xt ||= begin
          args[2] || nil
        end
      end

      def xt_time
        @xt_time ||= begin
          if args[2]
            # if not set xt:
            # Time.at(1099511627775) # => 36812-02-20 09:36:15 +0900
            Time.at(args[2].to_i) 
          else
            Time.at(0)
          end
        end
      end
      
      def time
        @time ||= Time.at(*[ts[0,10], ts[10, ts.length]].map(&:to_i))
      end
    end
  end
end
