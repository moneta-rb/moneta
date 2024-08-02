RSpec.describe Moneta::Transforms::BEncode do
  context "with serialize_unless_string: true" do
    subject { described_class.new(serialize_unless_string: true) }

    it_behaves_like "serializer only"

    it "passes through string inputs unchanged" do
      expect(subject.encode("testing")).to eq "testing"
    end

    it "refuses to decode strings" do
      expect { subject.decode("test") }.to raise_error(NotImplementedError)
    end
  end

  context "with serialize_unless_string: false" do
    it_behaves_like "serializer and deserializer"

    it "serializes strings to bencode format" do
      expect(subject.encode("test")).to eq "4:test"
    end
  end
end
