#!/usr/bin/env ruby
# Inspired by https://coderwall.com/p/x8exja

def cmd(s)
  puts s
  system(s)
end

def cmd!(s)
  cmd(s) || abort("#{s} failed")
end

if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
  ruby = 'rbx'
elsif defined?(JRUBY_VERSION)
  ruby = 'jruby'
else
  ruby = 'mri'
end

BUNDLE_FILE = "bundle-#{RUBY_VERSION}-#{ruby}.tar.gz"

if cmd("wget -O #{BUNDLE_FILE} http://s3.amazonaws.com/minad-moneta/#{BUNDLE_FILE}")
  cmd! 'rm -rf .bundle'
  cmd! "tar -xf #{BUNDLE_FILE}"
  cmd! 'bundle install --path .bundle'
else
  $: << File.expand_path(File.join(__FILE__, '..', '..', 'lib'))

  cmd! 'gem install --no-rdoc --no-ri fog'
  require 'rubygems'
  require 'fog'
  require 'moneta'

  store = Moneta::Adapters::Fog.new(:provider => 'AWS',
                                    :aws_access_key_id => ENV['AWS_KEY_ID'],
                                    :aws_secret_access_key => ENV['AWS_ACCESS_KEY'],
                                    :dir => 'minad-moneta')

  cmd! 'bundle install --path .bundle'
  cmd! "tar -czf #{BUNDLE_FILE} .bundle"
  store.store(BUNDLE_FILE, File.read(BUNDLE_FILE), :public => true)
end
