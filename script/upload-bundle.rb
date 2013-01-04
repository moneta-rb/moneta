#!/usr/bin/env ruby
# Inspired by https://coderwall.com/p/x8exja

if file = Dir['bundle-*.tar.gz'].first
  require 'rubygems'
  require 'bundler/setup'
  require 'moneta'

  content = File.read(file)

  store = Moneta::Adapters::Fog.new(:provider => 'AWS',
                            :aws_access_key_id => ENV['AWS_KEY_ID'],
                            :aws_secret_access_key => ENV['AWS_ACCESS_KEY'],
                            :dir => 'minad-moneta')
  store.store(file, content, :public => true) unless store.key?(file)
end
