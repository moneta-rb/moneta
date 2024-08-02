RSpec.describe Moneta::Transforms::City128 do
  subject { described_class.new }

  it 'hashes strings' do
    property_of { string }.check do |str|
      expect(subject.encode(str)).to match(/^[0-9a-f]{16,33}$/)
    end
  end
end
