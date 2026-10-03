# frozen_string_literal: true

namespace :ops do
  desc 'Check restored closed rounds and reproduce published tallies; exit nonzero on discrepancies'
  task verify: :environment do
    result = Operations::Verify.call
    puts JSON.pretty_generate(result)
    abort 'Recovery check failed; keep the application stopped.' unless result.fetch(:status) == 'ok'
  end

  desc 'Export the public published report; ELECTION_ID, OUTPUT, optional VERSION'
  task export: :environment do
    election = Election.find(ENV.fetch('ELECTION_ID'))
    path = Operations::ExportReport.call(election: election, path: ENV.fetch('OUTPUT'), version: ENV['VERSION'])
    puts "Report exported: #{path}"
  end

  desc 'Generate the first creator initial credential; SCHOOL_ID, SCHOOL_NAME, TIMEZONE, LOGIN, NAME'
  task provision: :environment do
    require 'io/console'
    abort 'Use an interactive terminal without a session recorder.' unless $stdin.tty?
    result = Operations::ProvisionCreator.call(identifier: ENV.fetch('SCHOOL_ID'), school_name: ENV.fetch('SCHOOL_NAME'),
                                                timezone: ENV.fetch('TIMEZONE'), login: ENV.fetch('LOGIN'),
                                                name: ENV.fetch('NAME'))
    # Send the initial credential directly to the terminal, not to stdout or Rails logs.
    File.open('/dev/tty', 'w') do |terminal|
      terminal.puts "Initial credential: #{result.credential}"
      terminal.puts 'Consume it with ops:activate to choose the permanent password before logging in.'
    end
    puts "Inactive creator provisioned: #{result.user.login}"
  end

  desc 'Consume the first creator initial credential locally; LOGIN'
  task activate: :environment do
    require 'io/console'
    abort 'Use an interactive terminal without a session recorder.' unless $stdin.tty?
    print 'Initial credential: '
    credential = $stdin.noecho(&:gets)&.chomp
    puts
    print 'New permanent password (minimum 12 characters): '
    password = $stdin.noecho(&:gets)&.chomp
    puts
    user = Operations::ProvisionCreator.activate(user: User.find_by!(login: ENV.fetch('LOGIN')),
                                                  credential: credential, password: password)
    puts "Creator activated: #{user.login}"
  end
end
