describe Politburo::Resource::Role do

  let(:role) { Politburo::Resource::Role.new(name: 'role', implies: lambda { self.do_stuff }) }

  it "should require a implies" do
    role.implies = nil
    role.should_not be_valid
  end
end
