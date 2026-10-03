# frozen_string_literal: true

require 'net/http'
require 'socket'
require 'websocket/driver'

module AuthenticationTransport
  class Browser
    attr_reader :cookies

    def initialize(origin)
      @origin = origin
      @cookies = {}
    end

    def request(method, path, body: nil, csrf: nil)
      uri = URI("#{@origin}#{path}")
      request = Net::HTTP.const_get(method.to_s.capitalize).new(uri)
      request['Cookie'] = cookie_header
      request['Origin'] = @origin
      request['Content-Type'] = 'application/json'
      request['X-CSRF-Token'] = csrf if csrf
      request.body = JSON.generate(body) if body
      response = Net::HTTP.start(uri.host, uri.port, nil, open_timeout: 5, read_timeout: 5) do |http|
        http.request(request)
      end
      response.get_fields('Set-Cookie').to_a.each do |header|
        name, value = header.split(';', 2).first.split('=', 2)
        @cookies[name] = value
      end
      response
    end

    def cookie_header
      @cookies.map { |name, value| "#{name}=#{value}" }.join('; ')
    end
  end

  class CableClient
    attr_reader :url, :driver

    def initialize(origin, cookie:, request_origin: origin, path: '/cable')
      uri = URI(origin)
      @url = "ws://#{uri.host}:#{uri.port}#{path}"
      @socket = TCPSocket.new(uri.host, uri.port)
      @messages = []
      @error = nil
      @driver = WebSocket::Driver.client(self, protocols: ['actioncable-v1-json'])
      @driver.set_header('Cookie', cookie)
      @driver.set_header('Origin', request_origin) if request_origin
      @driver.on(:message) { |event| @messages << JSON.parse(event.data) }
      @driver.on(:error) { |event| @error = event }
      @driver.start
    end

    def write(data)
      @socket.write(data)
    end

    def subscribe(channel, **parameters)
      identifier = JSON.generate({ channel: channel }.merge(parameters))
      @driver.text(JSON.generate(command: 'subscribe', identifier: identifier))
      identifier
    end

    def receive
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
      loop do
        return @messages.shift unless @messages.empty?
        raise @error if @error
        remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        raise 'Timed out waiting for Action Cable message' unless remaining.positive? && IO.select([@socket], nil, nil, remaining)

        @driver.parse(@socket.readpartial(16_384))
      end
    end

    def receive_type(type)
      10.times do
        message = receive
        return message if message['type'] == type
      end
      raise "Expected Action Cable #{type} message"
    end

    def close
      @socket.close unless @socket.closed?
    end
  end
end
