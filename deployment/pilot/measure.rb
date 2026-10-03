#!/usr/bin/env ruby
# Read-only probe. Results are measurements, not approved school capacity targets.
require 'net/http'
require 'json'
require 'thread'

uri = URI(ARGV.fetch(0))
requests = Integer(ARGV.fetch(1, '20'))
clients = Integer(ARGV.fetch(2, '2'))
abort 'Use HTTP(S), positive request count and positive client count' unless
  %w[http https].include?(uri.scheme) && requests.positive? && clients.positive?
queue = Queue.new
requests.times { queue << true }
samples = Queue.new
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
Array.new(clients) do
  Thread.new do
    loop do
      queue.pop(true)
      before = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                    open_timeout: 5, read_timeout: 10) { |http| http.get(uri.request_uri) }
        samples << [response.code.to_i == 200, (Process.clock_gettime(Process::CLOCK_MONOTONIC) - before) * 1000]
      rescue IOError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
        samples << [false, (Process.clock_gettime(Process::CLOCK_MONOTONIC) - before) * 1000]
      end
    rescue ThreadError
      break
    end
  end
end.each(&:join)
values = requests.times.map { samples.pop }
times = values.map(&:last).sort
puts JSON.pretty_generate(requests: requests, concurrent_clients: clients,
                          failures: values.count { |success, _| !success },
                          elapsed_seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(3),
                          p50_ms: times[(requests * 0.50).ceil - 1].round(2),
                          p95_ms: times[(requests * 0.95).ceil - 1].round(2))
exit(values.all?(&:first) ? 0 : 1)
