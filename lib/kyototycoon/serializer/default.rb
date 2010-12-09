# -- coding: utf-8

class KyotoTycoon
  module Serializer
    class Default
      def self.encode(obj)
        obj
      end

      def self.decode(str)
        str
      end
    end
  end
end
