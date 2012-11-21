# Based on http://stackoverflow.com/questions/1489183/colorized-ruby-output
String.class_eval do
  # colorization

  def self.allow_colors=(toggle)
    @allow_colors = toggle
  end

  def self.allow_colors()
    @allow_colors
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

  def pink
    colorize(35)
  end
end