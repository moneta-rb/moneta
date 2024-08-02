RSpec.describe Moneta::Transforms::City32 do
  subject { described_class.new }

  it 'hashes strings' do
    property_of { string }.check do |str|
      expect(subject.encode(str)).to match(/^[0-9a-f]{4,8}$/)
    end
  end
end
