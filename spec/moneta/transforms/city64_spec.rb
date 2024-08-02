RSpec.describe Moneta::Transforms::City64 do
  subject { described_class.new }

  it 'hashes strings' do
    property_of { string }.check do |str|
      expect(subject.encode(str)).to match(/^[0-9a-f]{8,16}$/)
    end
  end
end
