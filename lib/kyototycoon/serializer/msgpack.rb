# -- coding: utf-8

require "rubygems"
begin
  require "msgpack"
rescue LoadError
end

class KyotoTycoon
  module Serializer
    class Msgpack
      def self.encode(obj)
        obj.to_msgpack
      end

      def self.decode(str)
        MessagePack.unpack(str) if str
      end
    end
  end
end
