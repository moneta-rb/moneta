module Moneta
  module Transforms
    # Encodes strings in URL-safe Base64.  This is a convenience wrapper around {Transforms::Base64}.
    class UrlsafeBase64 < Base64
      # @param padding [Boolean] whether to include padding at the end of the Base64 string
      def initialize(padding: true, **options)
        super(url_safe: true, strict: false, padding: padding, **options)
      end
    end
  end
end
