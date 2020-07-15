#!/usr/bin/ruby
# coding: utf-8

require 'sinatra'
require 'sqlite3'
require 'json'

$LOAD_PATH.push(File.join(File.dirname(__FILE__), 'lib'))
require 'heyadas'


# クライアントからのリクエストを待ち受けるアドレスとポート番号
set :bind, '0.0.0.0'
set :port,  5000

heyadas = Heyadas.new

get '/' do
  redirect('/points')
end

get '/points' do
  erb(:points, locals: {points: heyadas.get_points, types: heyadas.types})
end

get '/point/:point_id/:type' do
  point = heyadas.get_point(params[:point_id])
  data = heyadas.get_entry_nhours(params[:point_id], params[:type], 1)
  unless data[:status]
    redirect('/points')
  end
  erb(:point, locals: {point: point, type: params[:type], data: data})
end

# 地点一覧を取得
get '/api/points' do
  return JSON.dump(heyadas.get_points)
end

# 地点IDもしくは地点名から地点情報を取得
get '/api/point' do
  if params[:point_id]
    return JSON.dump(heyadas.get_point(params[:point_id]))
  elsif params[:point_name]
    return JSON.dump(heyadas.get_point_by_name(params[:point_name]))
  else
    403
  end
end

# localtimeで当日
# SELECT datetime(datetime(CURRENT_TIMESTAMP, 'localtime'), 'start of day');

# 任意の地点の直近n時間のデータを取得
# point_id: 地点ID
# type:     データ種別(temperature, humidity, pressure)
# hours:    時間数
get '/api/observe/n_hours' do
  point_id  = params[:point_id]
  type      = params[:type]
  hours     = params[:hours]
  return JSON.dump(heyadas.get_entry_nhours(point_id, type, hours))
end

# 地点情報を追加
post '/api/point' do
  point_name = params[:point_name]
  latitude   = params[:latitude]
  longitude  = params[:longitude]
  altitude   = params[:altitude]
  return JSON.dump(heyadas.add_point(point_name, latitude, longitude, altitude))
end

# 観測データを追加
# point_id: 地点ID
# type:     データ種別(temperature, humidity, pressure)
# value:    観測データ(float)
post '/api/observe' do
  point_id = params[:point_id]
  type     = params[:type]
  value    = params[:value]
  return JSON.dump(heyadas.add_entry(point_id, type, value))
end
