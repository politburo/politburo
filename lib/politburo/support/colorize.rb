# Based on http://stackoverflow.com/questions/1489183/colorized-ruby-output-colorization
module Politburo

  module Support

    module Colorize

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def allow_colors=(toggle)
          @allow_colors = toggle
        end

        def allow_colors()
          @allow_colors
        end
      end

      def colorize(color_code)
        String.allow_colors ? "\e[#{color_code}m#{self}\e[0m" : self
      end

      def red
        colorize(31)
      end

      def green
        colorize(32)
      end

      def yellow
        colorize(33)
      end

      def blue
        colorize(34)
      end

      def pink
        colorize(35)
      end

      def cyan
        colorize(36)
      end

      def white
        colorize(37)
      end
      
    end
  end
end

String.class_eval do
  include Politburo::Support::Colorize
end

