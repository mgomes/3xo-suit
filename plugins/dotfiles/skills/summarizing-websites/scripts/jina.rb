#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'uri'

def read_url
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
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.open_timeout = 10
    http.read_timeout = nil
    yield http
  end
end

def jina_request(http, uri, api_key)
  request = Net::HTTP::Get.new(uri)
  request['Accept'] = 'text/event-stream'
  request['Authorization'] = "Bearer #{api_key}"
  request['X-Respond-With'] = 'readerlm-v2'

  http.request(request) do |response|
    unless response.is_a?(Net::HTTPSuccess)
      warn "HTTP #{response.code} #{response.message}"
      response.read_body { |chunk| warn chunk }
      exit 1
    end

    response.read_body do |chunk|
      $stdout.write(chunk)
      $stdout.flush
    end
  end
end

def main
  target_url = read_url
  if target_url.nil? || target_url.empty?
    warn 'Missing URL on stdin'
    exit 1
  end

  api_key = ENV.fetch('JINA_API_KEY', nil)
  if api_key.nil? || api_key.empty?
    warn 'Missing JINA_API_KEY environment variable'
    exit 1
  end

  uri = build_uri(target_url)

  http_client(uri) do |http|
    jina_request(http, uri, api_key)
  end
rescue StandardError => e
  warn "Request failed: #{e.message}"
  exit 1
end

main
