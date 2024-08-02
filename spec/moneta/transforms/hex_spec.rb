RSpec.describe Moneta::Transforms::Hex do
  subject { described_class.new }

  describe '#encode' do
    it 'converts strings to hexadecimal' do
      expect(subject.encode('testing 1 2 3')).to eq('74657374696e67203120322033')
    end
  end

  describe '#decode' do
    it 'converts hexadecimal to strings' do
      property_of { string }.check do |str|
        expect(subject.decode(subject.encode(str))).to eq str
      end
    end
  end
end
