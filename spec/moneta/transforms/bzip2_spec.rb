RSpec.describe Moneta::Transforms::Bzip2 do
  subject { described_class.new }

  it 'encodes strings to bzip2' do
    property_of { string }.check do |str|
      expect(subject.encode(str)).to start_with 'BZ'
    end
  end

  it 'decodes bzip2-encoded strings' do
    property_of { string }.check do |str|
      expect(subject.decode(subject.encode(str))).to eq str
    end
  end
end
