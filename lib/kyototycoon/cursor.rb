# -- coding: utf-8

class KyotoTycoon
  class Cursor
    include Enumerable
    attr_reader :cur

    def initialize(kt, cur)
      @kt = kt
      @cur = cur
      at_exit { delete! }
    end

    def each(&block)
      return to_enum(:each) unless block_given?
      jump if current == [nil,nil]
      start_key = key
      begin
        @kt.logger.debug("cursor each start with key=#{start_key}")
        loop do
          tmp = current(1)
          @kt.logger.debug("cursor each key=#{tmp.first}")
          break if tmp == [nil,nil]
          block.call(tmp)
        end
      ensure
        jump(start_key)
      end
    end

    def jump(key=nil)
      request('/rpc/cur_jump',{:key => key})
      self
    end

    def jump_back(key=nil)
      request('/rpc/cur_jump_back',{:key => key})
      self
    end

    def step
      request('/rpc/cur_step')
      self
    end
    alias_method :next, :step

    def step_back
      request('/rpc/cur_step_back')
      self
    end
    alias_method :prev, :step_back

    def value(step=nil)
      request('/rpc/cur_get_value', {"step" => step})["value"]
    end

    def value=(value, xt=nil, step=nil)
      request('/rpc/cur_set_value', {
        "value" => value,
        "xt" => xt,
        "step" => step,
      })
    end

    def key(step=nil)
      request('/rpc/cur_get_key', {"step" => step})["key"]
    end

    def current(step=nil)
      res = request('/rpc/cur_get', {"step" => step})
      [res["key"], res["value"]]
    end

    def seize
      res = request('/rpc/cur_seize')
      [res["key"], res["value"], res["xt"]]
    end

    def remove
      request('/rpc/cur_remove')
    end

    def delete!
      request('/rpc/cur_delete')
    end

    private
    def request(path, params={})
      params.merge!({
        :CUR => @cur,
      })
      res = @kt.request(path, params)
      Tsvrpc.parse(res[:body], res[:colenc])
    end
  end
end
