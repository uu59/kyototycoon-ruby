# -- coding: utf-8

=begin
This is experimental
=end

require "rubygems"
require "msgpack"
require "zlib"

class KyotoTycoon
  module Serializer
    class Msgpackgzip
      def self.encode(obj)
        str = obj.to_msgpack
        z = Zlib::Deflate.new(1)
        dst = z.deflate(str, Zlib::FINISH)
        z.close
        dst
      end

      def self.decode(str)
        return nil if !str
        z = Zlib::Inflate.new
        buf = z.inflate(str)
        z.finish
        z.close
        MessagePack.unpack(buf)
      end
    end
  end
end
