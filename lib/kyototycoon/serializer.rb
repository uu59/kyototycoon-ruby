# -- coding: utf-8

class KyotoTycoon
  module Serializer
    def self.get(adaptor)
      const_get(adaptor.to_s.capitalize)
    end
  end
end
