module Moneta
  class Transformer
    # Available key/value transformers
    TRANSFORMER = {
      # Name    => [ Type,       Load,                               Dump,                                Library         ],
      :bencode  => [ :serialize, '::BEncode.load(value)',             '::BEncode.dump(value)',             'bencode'       ],
      :bert     => [ :serialize, '::BERT.decode(value)',              '::BERT.encode(value)',              'bert'          ],
      :bson     => [ :serialize, "::BSON.deserialize(value)['v']",    "::BSON.serialize('v'=>value).to_s", 'bson'          ],
      :json     => [ :serialize, '::MultiJson.load(value).first',     '::MultiJson.dump([value])',         'multi_json'    ],
      :marshal  => [ :serialize, '::Marshal.load(value)',             '::Marshal.dump(value)'                              ],
      :msgpack  => [ :serialize, '::MessagePack.unpack(value)',       '::MessagePack.pack(value)',         'msgpack'       ],
      :ox       => [ :serialize, '::Ox.parse_obj(value)',             '::Ox.dump(value)',                  'ox'            ],
      :tnet     => [ :serialize, '::TNetstring.parse(value).first',   '::TNetstring.dump(value)',          'tnetstring'    ],
      :yaml     => [ :serialize, '::YAML.load(value)',                '::YAML.dump(value)',                'yaml'          ],
      :bzip2    => [ :compress,  '::Bzip2.uncompress(value)',         '::Bzip2.compress(value)',           'bzip2'         ],
      :lzma     => [ :compress,  '::LZMA.decompress(value)',          '::LZMA.compress(value)',            'lzma'          ],
      :lzo      => [ :compress,  '::LZO.decompress(value)',           '::LZO.compress(value)',             'lzoruby'       ],
      :snappy   => [ :compress,  '::Snappy.inflate(value)',           '::Snappy.deflate(value)',           'snappy'        ],
      :quicklz  => [ :compress,  '::QuickLZ.decompress(value)',       '::QuickLZ.compress(value)',         'qlzruby'       ],
      :zlib     => [ :compress,  '::Zlib::Inflate.inflate(value)',    '::Zlib::Deflate.deflate(value)',    'zlib'          ],
      :base64   => [ :encode,    "value.unpack('m').first",           "[value].pack('m').strip"                            ],
      :uuencode => [ :encode,    "value.unpack('u').first",           "[value].pack('u').strip"                            ],
      :escape   => [ :encode,    'Helper.unescape(value)',            'Helper.escape(value)'                               ],
      :hmac     => [ :hmac,      'Helper.hmacverify(value, @secret)', 'Helper.hmacsign(value, @secret)',   'openssl'       ],
      :truncate => [ :truncate,  nil,                                 'Helper.truncate(value, @maxlen)',   'digest/md5'    ],
      :md5      => [ :digest,    nil,                                 '::Digest::MD5.hexdigest(value)',    'digest/md5'    ],
      :rmd160   => [ :digest,    nil,                                 '::Digest::RMD160.hexdigest(value)', 'digest/rmd160' ],
      :sha1     => [ :digest,    nil,                                 '::Digest::SHA1.hexdigest(value)',   'digest/sha1'   ],
      :sha256   => [ :digest,    nil,                                 '::Digest::SHA256.hexdigest(value)', 'digest/sha2'   ],
      :sha384   => [ :digest,    nil,                                 '::Digest::SHA384.hexdigest(value)', 'digest/sha2'   ],
      :sha512   => [ :digest,    nil,                                 '::Digest::SHA512.hexdigest(value)', 'digest/sha2'   ],
      :prefix   => [ :prefix,    nil,                                 '(options[:prefix]||@prefix)+value'                  ],
      :spread   => [ :spread,    nil,                                 'Helper.spread(value)'                               ],
    }

    # Allowed value transformers (Read it like a regular expression!)
    VALUE_TRANSFORMER = compile_validator('serialize? compress? hmac? encode?')

    # Allowed key transformers (Read it like a regular expression!)
    KEY_TRANSFORMER = compile_validator('serialize? prefix? ((encode? truncate?) | (digest spread?))?')
  end
end
