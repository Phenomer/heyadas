#!/usr/bin/ruby
# coding: utf-8

require 'faraday'
require 'json'

HELP = <<EOS
# 地点の追加
# (post point 地点名 緯度 経度 標高)
#
% bundle exec ruby client.rb post point 土門拳記念館 38.901865 139.8222047
=> 200
=> {"status"=>true, "data"=>[[3, "土門拳記念館", 38.901865, 139.8222047, nil]]}

# 地点の参照(名前で探す)
# (get point 地点名)
#
% bundle exec ruby client.rb get point 土門拳記念館
=> 200
=> {"status"=>true, "data"=>[[3, "土門拳記念館", 38.901865, 139.8222047, nil]]}

# 地点の参照(IDで探す)
# (get point 地点ID)
#
% bundle exec ruby client.rb get point 3
=> 200
=> {"status"=>true, "data"=>[[3, "土門拳記念館", 38.901865, 139.8222047, nil]]}

# 観測データの追加
# (post 地点ID データタイプ 観測値)
#
% bundle exec ruby client.rb post 3 temperature 29.3
=> 200
=> {"status"=>true, "data"=>[[3, "2020-07-14 09:49:11", 29.3]]}

# 観測データの参照
# (get observe 地点ID データタイプ 時間数)
#
% bundle exec ruby client.rb get observe 3 temperature 1
200
{"status"=>true,
 "data"=>
  [[3, "2020-07-14 09:49:05", 29.3],
   [3, "2020-07-14 09:49:09", 29.3],
   [3, "2020-07-14 09:49:11", 29.3]]}
EOS

BASE_URI = 'http://127.0.0.1:5000'
def get(uri, params)
  res = Faraday.get(BASE_URI + uri, params)
  # pp(res.status)
  pp(JSON.parse(res.body))
end

def post(uri, params)
  res = Faraday.post(BASE_URI + uri, params)
  # pp(res.status)
  pp(JSON.parse(res.body))
end

case ARGV[0]
when 'get'
  case ARGV[1]
  when 'points'
    get('/api/points', {})
  when 'point'
    if ARGV[2].match(/^\d+$/)
      get('/api/point', {point_id: ARGV[2]})
    elsif not ARGV[2].nil?
      get('/api/point', {point_name: ARGV[2]})
    end
  when 'observe', 'obs'
    get('/api/observe/n_hours',
        {point_id: ARGV[2], type: ARGV[3], hours: ARGV[4] || 1})
  else
    STDERR.puts(HELP)
  end
when 'post'
  case ARGV[1]
  when 'point'
    post('/api/point',
         {point_name: ARGV[2], latitude: ARGV[3],
          longitude: ARGV[4], altitude: ARGV[5]})
  when 'observe', 'obs'
    post('/api/observe',
         {point_id: ARGV[2], type: ARGV[3], value: ARGV[4]})
  else
    STDERR.puts(HELP)
  end
else
  STDERR.puts(HELP)
end
