# Test logger that captures log messages for verification
class TestLogger < Logger
  attr_reader :messages

  def initialize
    @messages = []
    super(StringIO.new)
  end

  def add(severity, message = nil, progname = nil)
    severity ||= UNKNOWN
    return true if @logdev.nil? || (severity < level)

    progname ||= @progname
    if message.nil?
      if block_given?
        message = yield
      else
        message = progname
        progname = @progname
      end
    end

    # Store the log message for verification
    @messages << {
      severity: severity,
      level: SEV_LABEL[severity] || 'ANY',
      message: message,
      progname: progname,
      timestamp: Time.now,
    }

    true
  end

  def clear
    @messages.clear
  end

  def logged?(level, pattern = nil)
    level_num = case level.to_s.upcase
                when 'DEBUG' then DEBUG
                when 'INFO' then INFO
                when 'WARN' then WARN
                when 'ERROR' then ERROR
                when 'FATAL' then FATAL
                else level
                end

    messages.any? do |msg|
      next false if msg[:severity] != level_num
      next true if pattern.nil?

      case pattern
      when Regexp
        msg[:message] =~ pattern
      when String
        msg[:message].include?(pattern)
      else
        msg[:message] == pattern
      end
    end
  end

  def find_message(level, pattern = nil)
    level_num = case level.to_s.upcase
                when 'DEBUG' then DEBUG
                when 'INFO' then INFO
                when 'WARN' then WARN
                when 'ERROR' then ERROR
                when 'FATAL' then FATAL
                else level
                end

    messages.find do |msg|
      next false if msg[:severity] != level_num
      next true if pattern.nil?

      case pattern
      when Regexp
        msg[:message] =~ pattern
      when String
        msg[:message].include?(pattern)
      else
        msg[:message] == pattern
      end
    end
  end
end
