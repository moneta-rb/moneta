require 'openssl'

describe 'transformer_marshal_hmac', proxy: :Transformer do
  moneta_build do
    Moneta.build do
      use :Transformer, key: :marshal, value: [:marshal, :hmac], secret: 'secret'
      adapter :Memory
    end
  end

  moneta_loader do |value|
    digest = ::OpenSSL::Digest.new('sha256')
    hash = value.byteslice(0, digest.digest_length)
    rest = value.byteslice(digest.digest_length..-1)
    mac = OpenSSL::HMAC.digest(digest, 'secret', rest)
    raise 'hmac failed' unless hash == mac
    ::Marshal.load(rest)
  end

  moneta_specs STANDARD_SPECS.without_persist
end
