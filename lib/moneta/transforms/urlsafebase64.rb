module Moneta
  module Transforms
    class UrlsafeBase64 < Base64
      def initialize(**options)
        super(url_safe: true, strict: false, **options)
      end
    end
  end
end
