# -- coding: utf-8

class KyotoTycoon
  module Serializer
    def self.get(adaptor)
      dir = "#{File.dirname(__FILE__)}/serializer"
      if File.exists?(File.join(dir, "#{adaptor}.rb"))
        require "#{dir}/#{adaptor}.rb"
      end
      const_get(adaptor.capitalize)
    end
  end
end
