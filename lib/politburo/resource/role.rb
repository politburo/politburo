module Politburo
  module Resource
    class Role < Base

      attr_accessor :implies
      requires :implies

    end
  end
end
