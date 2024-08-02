RSpec.describe Moneta::Transforms::Base64 do
  context 'with url_safe: false, strict: false' do
    subject { described_class.new(url_safe: false, strict: false) }

    it 'encodes strings to RFC 2045 base64' do
      expect(subject.encode('x' * 50)).to eq <<~BASE64
        eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4
        eHh4eHg=
      BASE64
    end

    it 'decodes base64 strings with line feeds' do
      expect(subject.decode(<<~BASE64)).to eq('x' * 50)
        eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4
        eHh4eHg=
      BASE64
    end
  end

  context 'with url_safe: false, strict: true' do
    subject { described_class.new(url_safe: false, strict: true) }

    it 'encodes strings to RFC 4648 base64' do
      expect(subject.encode('x' * 50)).to eq <<~BASE64.chomp
        eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHg=
      BASE64
    end

    it 'decodes base64 strings without line feeds' do
      expect(subject.decode(<<~BASE64.chomp)).to eq('x' * 50)
        eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHg=
      BASE64
    end

    it 'raises when decoding base64 strings with line feeds' do
      expect { subject.decode(<<~BASE64) }.to raise_error('invalid base64')
        eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4
        eHh4eHg=
      BASE64
    end
  end

  context 'with url_safe: true, padding: false' do
    subject { described_class.new(url_safe: true, padding: false) }

    it 'encodes URL-safe base64 without padding' do
      expect(subject.encode('¿español?')).to eq 'wr9lc3Bhw7FvbD8'
    end
  end

  context 'with url_safe: true, padding: true' do
    subject { described_class.new(url_safe: true, padding: true) }

    it 'encodes URL-safe base64 with padding' do
      expect(subject.encode('¿español?')).to eq 'wr9lc3Bhw7FvbD8='
    end
  end
end

