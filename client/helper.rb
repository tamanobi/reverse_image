#! /bin/ruby
# encoding: utf-8

require 'redis'

def getRedisConnection(host, port)
    Redis.new :host => host, :port => port
end
