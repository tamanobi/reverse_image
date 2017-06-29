#! /bin/ruby
# encoding: utf-8

require 'redis'
require 'typhoeus'
require 'json'
require './helper.rb'

redis_host = ENV.fetch 'REDIS_HOST', '127.0.0.1'
redis_port = ENV.fetch 'REDIS_PORT', 9379

ngt_host = ENV.fetch 'NGT_HOST', '127.0.0.1'
ngt_port = ENV.fetch 'NGT_PORT', 8000

endpoint_append = "http://#{ngt_host}:#{ngt_port}/append"
endpoint_create = "http://#{ngt_host}:#{ngt_port}/create"

fname = "features.tsv"

# ファイルを生成したあと、データベースを生成する
redis = getRedisConnection redis_host, redis_port
l = redis.llen("features").to_i
redis.quit

File.open(fname, "w") {}
(0..l).each {|i|
    File.open(fname, "a") {|f|
        redis = getRedisConnection redis_host, redis_port
        x = redis.lindex "features", i
        if x.nil?
            break
        end
        d = JSON.parse(x)
        p "#{d['id']}"
        feature = d['feature']
        f.puts feature.join("\t")
        redis.quit
    }

    if i != 0  && i != l - 1 && ((i + 1) % 100) != 0
        next
    end

    p "uploading"
    if i == 0
        ep = endpoint_create
    else
        ep = endpoint_append
    end

    res = Typhoeus.post(
      ep,
      body: {
        uploadfile: File.open(fname, 'r')
      }
    )

    if res.success?
      puts 'success'
      puts res.body
    else
      puts 'failure'
      puts res.body
    end
    File.open(fname, "w") {}
}

