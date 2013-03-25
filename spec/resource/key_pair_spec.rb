describe Politburo::Resource::KeyPair do

  let(:parent_resource) { Politburo::Resource::Base.new(name: "Parent resource") }
  let(:key_pair) { Politburo::Resource::KeyPair.new(name: "Key pair resource") }

  before :each do
    parent_resource.add_child(key_pair)
  end

  context "#private_keys_path" do
    it "should inherit from parent" do
      parent_resource.should_receive(:private_keys_path).and_return(:private_keys_path)

      key_pair.private_keys_path.should be :private_keys_path
    end
  end

  context "#private_key_file_name" do
    it "should default to cloud counterpart name with all non word chars replaced by underscore and the .pem extension added" do
      key_pair.should_receive(:cloud_counterpart_name).and_return("An environment:name")

      key_pair.private_key_file_name.should eq "An_environment_name.pem"
    end
  end

  context "#private_key_path" do
    let(:private_keys_path) { double("private_keys_path") }

    it "should default to private keys path with private key file name" do
      key_pair.should_receive(:private_keys_path).and_return(private_keys_path)
      key_pair.should_receive(:private_key_file_name).and_return("An_environment_name.pem")
      private_keys_path.should_receive(:+).and_return(:combined_path)

      key_pair.private_key_path.should be :combined_path
    end
  end

  context "#private_key_content" do
    let(:private_key_path) { double('private key path') }

    it "should default to loading the content by using the key path" do
      key_pair.should_receive(:private_key_path).and_return(private_key_path)
      private_key_path.should_receive(:read).and_return(:private_key_content)

      key_pair.private_key_content.should be :private_key_content
    end
  end

  context "#public_key_file_name" do
    it "should default to cloud counterpart name with all non word chars replaced by underscore and the .pem extension added" do
      key_pair.should_receive(:cloud_counterpart_name).and_return("An environment:name")

      key_pair.public_key_file_name.should eq "An_environment_name.pub"
    end
  end

  context "#public_key_path" do
    let(:private_keys_path) { double("private_keys_path") }

    it "should default to private keys path with public key file name" do
      key_pair.should_receive(:private_keys_path).and_return(private_keys_path)
      key_pair.should_receive(:public_key_file_name).and_return("An_environment_name.pub")
      private_keys_path.should_receive(:+).and_return(:combined_path)

      key_pair.public_key_path.should be :combined_path
    end
  end

end
