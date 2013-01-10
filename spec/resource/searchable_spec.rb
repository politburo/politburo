require 'politburo'
require 'ostruct'

describe Politburo::Resource::Searchable do

	context "#matches?" do
		let(:obj) { double("object to compare to", field_a: 'field a value', field_b: 'field b value') }

		it "should match exact strings" do
			Politburo::Resource::Searchable.should be_matches(obj, field_a: 'field a value')
			Politburo::Resource::Searchable.should be_matches(obj, field_b: 'field b value')
			Politburo::Resource::Searchable.should be_matches(obj, field_a: 'field a value', field_b: 'field b value')
		end

		it "should not match unmatching strings" do
			Politburo::Resource::Searchable.should_not be_matches(obj, field_a: 'field x value')
			Politburo::Resource::Searchable.should_not be_matches(obj, field_b: 'field x value')
			Politburo::Resource::Searchable.should_not be_matches(obj, field_a: 'field x value', field_b: 'field b value')
		end

		it "should match with lambdas" do
			Politburo::Resource::Searchable.should be_matches(obj, field_a: lambda do | object, name, value | 
				object.should be obj
				name.should eq :field_a

				value == 'field a value'
			end)

			Politburo::Resource::Searchable.should_not be_matches(obj, field_b: lambda { | object, name, value | value != 'field b value' } )
		end

		it "should match regular expressions" do
			Politburo::Resource::Searchable.should be_matches(obj, field_a: /field . value/)
			Politburo::Resource::Searchable.should_not be_matches(obj, field_a: /field [^a] value/)
		end

	end

	context "finder methods" do

		class SearchableTestObj < OpenStruct
			include Politburo::Resource::Searchable

			attr_reader :children

			def initialize(children = nil, attrs = {})
				super(attrs)
				@children = children
			end

			def contained_searchables
				children
			end

		end	

		let(:leaf_1) { SearchableTestObj.new(nil, { name: 'leaf 1', index: 1, type: 'leaf', special: true }) }
		let(:leaf_2) { SearchableTestObj.new(nil, { name: 'leaf 2', index: 2, type: 'leaf' }) }
		let(:leaf_3) { SearchableTestObj.new(nil, { name: 'leaf 3', index: 3, type: 'leaf', special: true}) }
		let(:leaf_4) { SearchableTestObj.new(nil, { name: 'leaf 4', index: 4, type: 'leaf' }) }
		let(:leaf_5) { SearchableTestObj.new(nil, { name: 'leaf 5', index: 5, type: 'leaf', special: true }) }
		let(:leaf_6) { SearchableTestObj.new(nil, { name: 'leaf 6', index: 6, type: 'leaf', special: true }) }
		let(:leaf_7) { OpenStruct.new({ children: nil, name: 'non searchable leaf', index: 7, type: 'leaf' }) }

		let(:midlevel_1) { SearchableTestObj.new( [ leaf_3, leaf_4 ], { index: 1, type: 'midlevel', special: nil }) }
		let(:midlevel_2) { SearchableTestObj.new( [ leaf_5, leaf_6, leaf_7 ], { index: 2, type: 'midlevel', special: true }) }

		let(:root) { SearchableTestObj.new( [ midlevel_1, leaf_1, midlevel_2, leaf_2 ]) }

		context "#find_direct_children_by_attributes" do

			it "should find only matching direct children" do
				root.find_direct_children_by_attributes(special: true).should eq Set.new([leaf_1, midlevel_2])
			end

			it "if no children, should return an empty set" do
				root.should_receive(:contained_searchables).and_return(nil)
				root.find_direct_children_by_attributes(special: true).should eq Set.new()
			end

		end

		context "#find_all_by_attributes" do

			it "should recursively find the correct resource by single attributes" do
				found = root.find_all_by_attributes(name: 'leaf 4')
				found.should_not be_empty
				found.length.should == 1

				found_leaf_4 = found.first
				found_leaf_4.name.should eql('leaf 4')
				found_leaf_4.should == leaf_4
			end

			it "should recursively find the correct resource by multiple attributes" do
				found = root.find_all_by_attributes(type: 'midlevel', index: 1)
				found.should_not be_empty
				found.length.should == 1

				found_midlevel_1 = found.first

				found_midlevel_1.index.should eql(1)
				found_midlevel_1.type.should eql('midlevel')

				found_midlevel_1.should == midlevel_1
			end

			it "should recursively find the correct resource with matcher lambdas" do
				found = root.find_all_by_attributes(anything_goes: lambda { | obj, attr_name, value | obj.type.eql?('midlevel') && obj.special.nil? })
				found.should_not be_empty
				found.length.should == 1

				found_midlevel_1 = found.first

				found_midlevel_1.index.should eql(1)
				found_midlevel_1.type.should eql('midlevel')

				found_midlevel_1.should == midlevel_1
			end

			it "should recursively not find by multiple attributes if resource doesn't exist" do
				found = root.find_all_by_attributes(type: 'midlevel', index: 3)
				found.should be_empty
			end

			it "should recursively find multiple leaf resources" do
				found = root.find_all_by_attributes(type: 'leaf')
				found.should_not be_empty
				found.length.should == 7
				found.should include leaf_1
				found.should include leaf_2
				found.should include leaf_3
				found.should include leaf_4
				found.should include leaf_5
				found.should include leaf_6
				found.should include leaf_7
			end

		end	
	end

end