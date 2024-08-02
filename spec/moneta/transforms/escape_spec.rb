RSpec.describe Moneta::Transforms::Escape do
  subject { described_class.new }

  describe '#encode' do
    it 'escapes strings' do
      expect(subject.encode('This "string", containing punctuation?')).to eq "This%20%22string%22%2C%20containing%20punctuation%3F"
    end
  end

  describe '#decode' do
    it 'unescapes escaped strings' do
      property_of { string }.check do |str|
        expect(subject.decode(subject.encode(str))).to eq str
      end
    end
  end
end
