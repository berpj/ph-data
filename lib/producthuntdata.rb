require 'producthuntdata/version'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'time'
require 'date'

module Producthuntdata
  API_ENDPOINT = 'https://api.producthunt.com'
  API_TOKEN = 'ba361e9e751aba7e42148327ab16a47a9138fe84cbc40a79b3b933dc3bb72eb2'
  FIRST_DATE = '2013-11-24'

  def self.make_request(route)
    uri = URI.parse(API_ENDPOINT)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(route, {'Authorization' => "Bearer #{API_TOKEN}"})
    request.add_field('Content-Type', 'application/json')
    response = http.request(request)
    return JSON.parse(response.body)
  end

  def self.get_topics()
    return make_request('/v1/topics')
  end

  def self.get_posts_from_date(date)
    return make_request("/v1/posts?day=#{date}")
  end

  def self.start()
    date = Date.strptime(FIRST_DATE, "%Y-%m-%d")

    while date.to_s != Date.today.to_s do
      posts = get_posts_from_date(date.to_s)
      puts posts
      sleep(1)
      date = date + 1
    end
  end
end
