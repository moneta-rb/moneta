RSpec.shared_examples "serializer" do
  it "serializes non-string values" do
    property_of { dict { [string, choose(string, integer)] } }.check do |hash|
      expect(subject.encode(hash)).to be_a String
    end
  end

  it "serializes arrays to strings" do
    property_of { array { choose(string, integer) } }.check do |arr|
      expect(subject.encode(arr)).to be_a String
    end
  end

  it "serializes integers to strings" do
    property_of { integer }.check do |i|
      expect(subject.encode(i)).to be_a String
    end
  end
end

RSpec.shared_examples "serializer only" do
  it_behaves_like "serializer"

  it "refuses to decode strings" do
    expect { subject.decode("test") }.to raise_error(NotImplementedError)
  end
end

RSpec.shared_examples "serializer and deserializer" do
  it_behaves_like "serializer"

  it "deserializes serialized hashes" do
    property_of { dict { [string, choose(string, integer)] } }.check do |hash|
      expect(subject.decode(subject.encode(hash))).to eq(hash)
    end
  end

  it "deserializes serialized arrays" do
    property_of { array { choose(string, integer) } }.check do |arr|
      expect(subject.decode(subject.encode(arr))).to eq(arr)
    end
  end
end
