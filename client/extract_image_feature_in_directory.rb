#! /bin/ruby
# encoding: utf-8

require 'redis'
require 'typhoeus'
require 'json'
require './helper.rb'

i2v_host = ENV.fetch 'I2V_HOST', '127.0.0.1'
i2v_port = ENV.fetch 'I2V_PORT', 5000
dir = ARGV[0]
if dir == ''
    raise 'directory is not found.'
end

endpoint = "http://#{i2v_host}:#{i2v_port}/feature2"

flist = Dir.glob(dir + '*.{jpg,jpeg,png}')
# flist を探索して、ファイル名を使って、redisに問い合わせる
# もし見つかったなら、追加しない。スキップ
# 見つからないなら、redisのリストに追加する
# idは、redisのリストの連番が割り当てる
redis = getRedisConnection redis_host, redis_port
i = 0
flist.each_with_index {|x|
  key = File.basename(x)
  key = key.gsub /[0-9]{8}_[0-9]+_/, ''
  illust_id = key.gsub /_.*$/, ''

  if redis.exists "file#{illust_id}"
    p "skipped"
    next
  end
  res = Typhoeus.post(
    endpoint,
    body: {
      the_file: File.open(x, 'r')
    }
  )
  if res.success?
    result = JSON.parse res.body
    s = result['feature']
    if s.nil?
        puts "#{x} was skipped"
        next
    end
    puts x

    info = {:id => i, :file => x, :feature => s}
    redis.multi {
      redis.set "file#{illust_id}", "#{i}"
      redis.rpush "features", info.to_json
    }
    l = redis.llen "features"
    p "#{i}, #{l}"
    i += 1
  end
}
redis.quit
