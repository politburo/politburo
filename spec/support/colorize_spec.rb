describe Politburo::Support::Colorize do 
  
  before :each do
    String.allow_colors = true
  end

  context "#colorize" do

    it "should wrap the string in a ANSI escape code specified" do
      "red".colorize(31).should == "\e[31mred\e[0m"
    end

  end

  context "Coloring string methods" do
    colors = { red: 31,
      green: 32,
      yellow: 33,
      blue: 34,
      pink: 35,
      cyan: 36,
      white: 37, }

    colors.each_pair do | color, code |
      it "##{color} should wrap the text in the correct color code" do
        "text".send(color.to_sym).should == "\e[#{code}mtext\e[0m"
      end
    end

  end
end