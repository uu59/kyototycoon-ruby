# -- coding: utf-8

=begin
This serializer is buggy. example:
@kt['string']='a'
@kt['string'] # => unexpected token at '"a"'

It causes by json library.
JSON.parse('a'.to_json') # => same error
=end

require "rubygems"
require "json"

class KyotoTycoon
  module Serializer
    class Json
      def self.encode(obj)
        obj.to_json if obj
      end

      def self.decode(str)
        JSON.parse(str) if str
      end
    end
  end
end
