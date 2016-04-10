require 'ph_data/version'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'time'
require 'date'

module PhData
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
    newer = 0
    last_request = 42;

    while last_request == 42 || last_request['topics'] != [] do
      last_request = make_request("/v1/topics?newer=#{newer}&per_page=50")
      puts last_request.to_json if last_request['topics'] != []
      sleep(1)
      newer = newer + 50
    end
  end

  def self.get_posts()
    date = Date.strptime(FIRST_DATE, "%Y-%m-%d")

    while date.to_s != Date.today.to_s do
      puts make_request("/v1/posts?day=#{date}").to_json
      sleep(1)
      date = date + 1
    end
  end

  def self.analytics_posts()
    current_date = nil
    date = nil
    date_count = 0
    date_count_votes = 0
    results = []

    File.open('./web/data/posts.json', 'r').each_line do |line|
      # data = JSON.parse(eval)
      data = eval(line)

      if data['posts'][0]
        current_date = Date.parse data['posts'][0]['day']
        current_count = data['posts'].length

        current_count_votes = 0
        data['posts'].each do |post|
          current_count_votes = current_count_votes + post['votes_count']
        end

      else
        current_date = current_date + 1
        current_count = 0
        current_count_votes = 0
      end

      date_count = date_count + current_count
      date_count_votes = date_count_votes + current_count_votes

      if date && current_date.strftime('%m/%Y') != date.strftime('%m/%Y')
        results.push({count: date_count, votes: date_count_votes, date: date.strftime('%m/%Y')})
        date_count = 0
        date_count_votes = 0
      end

      date = current_date
    end

    i = 0
    results.each do |line|
      print ',' if i > 0
      print line[:date]
      i = i +1
    end
    puts ""

    i = 0
    results.each do |line|
      print ',' if i > 0
      print line[:count]
      i = i + 1
    end
    puts ""

    i = 0
    results.each do |line|
      print ',' if i > 0
      print line[:votes]
      i = i + 1
    end
    puts ""
  end

  def self.analytics_posts_day()
    results = {'Monday' => {count: 0, posts: 0, votes: 0}, 'Tuesday' =>  {count: 0, posts: 0, votes: 0}, 'Wednesday' => {count: 0, posts: 0, votes: 0}, 'Thursday' => {count: 0, posts: 0, votes: 0}, 'Friday' => {count: 0, posts: 0, votes: 0}, 'Saturday' => {count: 0, posts: 0, votes: 0}, 'Sunday' => {count: 0, posts: 0, votes: 0}}

    File.open('./web/data/posts.json', 'r').each_line do |line|
      # data = JSON.parse(eval)
      data = eval(line)

      if data['posts'][0]
        date = Date.parse data['posts'][0]['day']
        results[date.strftime('%A')][:count] = results[date.strftime('%A')][:count] + 1
        data['posts'].each do |post|
          results[date.strftime('%A')][:posts] = results[date.strftime('%A')][:posts] + 1
          results[date.strftime('%A')][:votes] = results[date.strftime('%A')][:votes] + post['votes_count']
        end
      end
    end

    i = 0
    results.each do |day, values|
      print ',' if i > 0
      print day
      i = i + 1
    end
    puts ""

    i = 0
    results.each do |day, values|
      print ',' if i > 0
      print values[:posts]
      i = i + 1
    end
    puts ""

    i = 0
    results.each do |day, values|
      print ',' if i > 0
      print values[:votes]
      i = i +1
    end
    puts ""
  end

  def self.analytics_posts_hour()
    results = []
    days = 0

    for i in 0..23 do
      results.push({posts: 0, votes: 0})
    end

    File.open('./web/data/posts.json', 'r').each_line do |line|
      # data = JSON.parse(eval)
      data = eval(line)

      if data['posts'][0]
        days = days + 1
        data['posts'].each do |post|
          date = DateTime.parse post['created_at']
          results[date.strftime('%H').to_i][:posts] = results[date.strftime('%H').to_i][:posts] + 1
          results[date.strftime('%H').to_i][:votes] = results[date.strftime('%H').to_i][:votes] + post['votes_count']
        end
      end
    end

    i = 0
    results.each do |hour, values|
      print ',' if i > 0
      print i
      print 'h'
      i = i + 1
    end
    puts ""

    i = 0
    results.each do |line|
      print ',' if i > 0
      print line[:posts]
      i = i + 1
    end
    puts ""

    i = 0
    results.each do |line|
      print ',' if i > 0
      print line[:votes]
      i = i +1
    end
    puts ""
  end

  def self.analytics_platforms()
    topics = []

    File.open('./web/data/topics.json', 'r').each_line do |line|
      data = JSON.parse(line)

      topics = topics + data['topics']
    end

    topics.sort! { |a,b| b['posts_count'] <=> a['posts_count'] }

    i = 0
    topics.each do |topic|
      if ['Web', 'iPhone', 'Android', 'iPad', 'Mac', 'Windows', 'Linux', 'Apple Watch'].include? topic['name']
        print ',' if i > 0
        print topic['name']
        i = i + 1
      end
    end
    puts ""

    i = 0
    topics.each do |topic|
      if ['Web', 'iPhone', 'Android', 'iPad', 'Mac', 'Windows', 'Linux', 'Apple Watch'].include? topic['name']
        print ',' if i > 0
        print topic['posts_count']
        i = i + 1
      end
    end
    puts ""
  end

  def self.analytics_topics()
    topics = []

    File.open('./web/data/topics.json', 'r').each_line do |line|
      data = JSON.parse(line)

      topics = topics + data['topics']
    end

    topics.sort! { |a,b| b['followers_count'] <=> a['followers_count'] }

    i = 0
    topics.each do |topic|
      print ',' if i > 0
      print topic['name']
      i = i + 1
      break if i == 20
    end
    puts ""

    i = 0
    topics.each do |topic|
      print ',' if i > 0
      print topic['posts_count']
      i = i + 1
      break if i == 20
    end
    puts ""

    i = 0
    topics.each do |topic|
      print ',' if i > 0
      print topic['followers_count']
      i = i + 1
      break if i == 20
    end
    puts ""
  end
end
