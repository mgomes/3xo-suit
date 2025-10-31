#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'openssl'

def extract_target_url
  return ARGV[0] unless ARGV.empty?

  line = $stdin.gets
  return nil if line.nil?

  line.split(/\s+/).find { |token| !token.empty? }
end

def build_uri(target_url)
  URI("https://r.jina.ai/#{target_url}")
rescue URI::InvalidURIError => e
  warn "Invalid URL: #{e.message}"
  exit 1
end

def http_client(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.open_timeout = 10
  http.read_timeout = nil
  if http.use_ssl?
    store = OpenSSL::X509::Store.new
    store.set_default_paths
    http.cert_store = store
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  end
  http.start { |client| yield client }
end

def jina_request(http, uri, api_key)
  request = Net::HTTP::Get.new(uri)
  request['Accept'] = 'text/plain'
  request['X-Engine'] = 'readerlm-v2'
  request['Authorization'] = "Bearer #{api_key}" if api_key

  response = http.request(request)
  unless response.is_a?(Net::HTTPSuccess)
    warn "HTTP #{response.code} #{response.message}"
    response.read_body { |chunk| warn chunk }
    exit 1
  end

  body = response.body || ''
  $stdout.write(body)
  $stdout.flush
end

def main
  target_url = extract_target_url
  if target_url.nil? || target_url.empty?
    warn 'Missing URL argument or stdin input'
    exit 1
  end

  api_key = ENV.fetch('JINA_API_KEY', nil)
  api_key = nil if api_key.nil? || api_key.empty?

  uri = build_uri(target_url)

  http_client(uri) do |http|
    jina_request(http, uri, api_key)
  end
rescue StandardError => e
  warn "Request failed: #{e.message}"
  exit 1
end

main
