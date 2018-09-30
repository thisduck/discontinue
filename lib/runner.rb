require 'terrapin'

class Runner
  CommandError = Class.new(Exception)

  def run(command)
    line = Terrapin::CommandLine.new(command, "", expected_outcodes: [0, 1])
    result = line.run
    @return_code = $?
    @output = result
    @command = command

    output
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

