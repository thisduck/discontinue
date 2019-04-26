require 'terrapin'

class Runner
  CommandError = Class.new(Exception)

  def run(command)
    puts "-" * 10
    puts command
    puts "-" * 10
    line = Terrapin::CommandLine.new(command, "", expected_outcodes: [0, 1])
    result = line.run
    @return_code = $?
    @output = result
    @command = command

    output
  end

  def ssh(strict: "no", hosts_file: "/dev/null", bash: true, environment: '', options: '', machine:, command:)
    options = "#{options} -n -f "
    options += " -o StrictHostKeyChecking=#{strict} " if strict.present?
    options += " -o UserKnownHostsFile=#{hosts_file} " if hosts_file.present?

    command = %^bash --login -c "#{command.gsub(/"/, '\"')}"^ if bash
    command = %^"#{command.gsub(/"/, '\"')}"^ if !bash

    run %^ssh #{options} #{machine} #{command}^
  end

  def scp(strict: "no", hosts_file: "/dev/null", environment: '', options: '', from:, to:)
    options += " -o StrictHostKeyChecking=#{strict} " if strict.present?
    options += " -o UserKnownHostsFile=#{hosts_file} " if hosts_file.present?

    run %^scp #{options} #{from} #{to}^
  end

  def rsync(command, strict: "no", hosts_file: "/dev/null", options: '')
    extra_options = [
      (" -o StrictHostKeyChecking=#{strict} " if strict.present?),
      (" -o UserKnownHostsFile=#{hosts_file} " if hosts_file.present?)
    ].compact

    options += " -e 'ssh #{extra_options.join(' ')}' " if extra_options.any?
    command = "rsync #{options} #{command}"

    run command
  end

  def command
    @command
  end

  def return_code
    @return_code
  end

  def output
    @output
  end

  def success?
    return_code == 0
  end

  def run!(command)
    run(command).tap do |result|
      raise CommandError.new($?) if $? != 0
    end
  end
end

