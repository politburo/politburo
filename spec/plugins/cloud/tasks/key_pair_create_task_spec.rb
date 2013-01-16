describe Politburo::Plugins::Cloud::Tasks::KeyPairCreateTask do

  let(:provider) { double("cloud provider", compute_instance: compute_instance) }
  let(:compute_instance) { double("connection compute instance", key_pairs: cloud_key_pairs) }
  let(:cloud_key_pairs) { double("key pairs collection") }
  let(:key_pair) { Politburo::Plugins::Cloud::KeyPair.new(name: "Key pair", private_key_path: private_key_path, public_key_path: public_key_path, cloud_counterpart_name: 'kp-online') }
  let(:cloud_key_pair) { double("cloud key_pair", display_name: 'ssh!') }
  let(:private_key_path) { double("private key path", to_s: '/path/to/key/file.pem') }
  let(:public_key_path) { double("public key path", to_s: '/path/to/key/file.pub') }

  let(:state) { key_pair.context.define { state(:started) {} }.state(:started) }
  let(:task) { Politburo::Plugins::Cloud::Tasks::KeyPairCreateTask.new(name: 'Create key pair') }

  before :each do
    key_pair.stub(:cloud_provider).and_return(provider)
    state.add_child(task)
  end

  context "#met?" do
    context "when the key pair has not been created yet" do
      it "should return false" do
        key_pair.should_receive(:cloud_key_pair).and_return(nil)

        task.should_not be_met
      end
    end

    context "when the key pair has been created" do

      before :each do
        key_pair.should_receive(:cloud_key_pair).and_return(cloud_key_pair)
      end

      context "when the private key file exists" do

        it "should return true" do
          private_key_path.should_receive(:exist?).and_return(true)
          task.should be_met
        end
      end

      context "when the private key file doesn't exist" do

        it "should raise an error" do
          private_key_path.should_receive(:exist?).and_return(false)

          lambda { task.met? }.should raise_error "Key pair 'kp-online' exists in the cloud but a matching private key file can't be found at: '/path/to/key/file.pem'. Manually delete the cloud key pair if you want it to be re-generated (be careful!) or provide the private key file - perhaps someone didn't check it in?"
        end
      end

    end
    
  end

  context "#verify_met?" do
    it "should delegate to met" do
      task.should_receive(:met?).with(true)

      task.verify_met?
    end
  end

  context "#meet" do

      context "when the private key file exists" do

        before :each do
          private_key_path.should_receive(:exist?).and_return(true)
        end

        context "when a matching public key file doesn't exist" do
          before :each do
            public_key_path.should_receive(:exist?).and_return(false)
          end

          it "should raise an error" do
            lambda { task.meet }.should raise_error "Found existing private key file at: '/path/to/key/file.pem' with no matching key pair in the cloud."
          end
        end

        context "when the matching public key file exists" do
          before :each do
            public_key_path.should_receive(:exist?).and_return(true)
          end

          it "should import it into the cloud" do
            public_key_path.should_receive(:read).and_return(:public_key_content)
            cloud_key_pairs.should_receive(:create).with(name: 'kp-online', public_key: :public_key_content).and_return(cloud_key_pair)
            cloud_key_pair.should_not_receive(:write)

            task.meet.should be cloud_key_pair
          end          
        end
      end

      context "when the private key file doesn't exist" do

        it "should create the key pair" do
          private_key_path.should_receive(:exist?).and_return(false)

          cloud_key_pairs.should_receive(:create).with(name: 'kp-online').and_return(cloud_key_pair)
          cloud_key_pair.should_receive(:write).with('/path/to/key/file.pem')

          task.meet.should eq cloud_key_pair
        end

      end
      

  end
end
