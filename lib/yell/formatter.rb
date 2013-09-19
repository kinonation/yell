# encoding: utf-8
require 'time'

module Yell #:nodoc:

  # No format on the log message
  #
  # @example
  #   logger = Yell.new STDOUT, :format => false
  #   logger.info "Hello World!"
  #   #=> "Hello World!"
  NoFormat = "%m"

  # Default Format
  #
  # @example
  #   logger = Yell.new STDOUT, :format => Yell::DefaultFormat
  #   logger.info "Hello World!"
  #   #=> "2012-02-29T09:30:00+01:00 [ INFO] 65784 : Hello World!"
  #   #    ^                         ^       ^       ^
  #   #    ISO8601 Timestamp         Level   Pid     Message
  DefaultFormat = "%d [%5L] %p : %m"

  # Basic Format
  #
  # @example
  #   logger = Yell.new STDOUT, :format => Yell::BasicFormat
  #   logger.info "Hello World!"
  #   #=> "I, 2012-02-29T09:30:00+01:00 : Hello World!"
  #   #    ^  ^                          ^
  #   #    ^  ISO8601 Timestamp          Message
  #   #    Level (short)
  BasicFormat = "%l, %d : %m"

  # Extended Format
  #
  # @example
  #   logger = Yell.new STDOUT, :format => Yell::ExtendedFormat
  #   logger.info "Hello World!"
  #   #=> "2012-02-29T09:30:00+01:00 [ INFO] 65784 localhost : Hello World!"
  #   #    ^                          ^      ^     ^           ^
  #   #    ISO8601 Timestamp          Level  Pid   Hostname    Message
  ExtendedFormat  = "%d [%5L] %p %h : %m"


  # The +Formatter+ provides a handle to configure your log message style.
  class Formatter

    Table = {
      "m" => "message(*event.messages)",   # Message
      "l" => "level(event.level)[0,1]",    # Level (short), e.g.'I', 'W'
      "L" => "level(event.level)",         # Level, e.g. 'INFO', 'WARN'
      "d" => "date(event.time)",           # ISO8601 Timestamp
      "h" => "event.hostname",             # Hostname
      "p" => "event.pid",                  # PID
      "P" => "event.progname",             # Progname
      "t" => "event.thread_id",            # Thread ID
      "F" => "event.file",                 # Path with filename where the logger was called
      "f" => "File.basename(event.file)",  # Filename where the loger was called
      "M" => "event.method",               # Method name where the logger was called
      "n" => "event.line",                 # Line where the logger was called
      "N" => "event.name"                  # Name of the logger
    }

    Matcher = /([^%]*)(%\d*)?(#{Table.keys.join('|')})?(.*)/


    # Initializes a new +Yell::Formatter+.
    #
    # Upon initialization it defines a format method. `format` takes 
    # a {Yell::Event} instance as agument in order to apply for desired log 
    # message formatting.
    def initialize( pattern = nil, date_pattern = nil )
      @pattern      = pattern || Yell::DefaultFormat
      @date_pattern = date_pattern || :iso8601

      define_date_method!
      define_format_method!
    end

    # Get a pretty string
    def inspect
      "#<#{self.class.name} pattern: #{@pattern.inspect}, date_pattern: #{@date_pattern.inspect}>"
    end


    private

    def define_date_method!
      buf = case @date_pattern
      when String then "t.strftime(@date_pattern)"
      when Symbol then respond_to?(@date_pattern, true) ? "#{@date_pattern}(t)" : "t.#{@date_pattern}"
      else "iso8601(t)"
      end

      instance_eval %-
        def date( t )
          #{buf}
        end
      -
    end

    def define_format_method!
      buff, args, _pattern = "", [], @pattern.dup

      while true
        match = Matcher.match(_pattern)

        buff << match[1] unless match[1].empty?
        break if match[2].nil?

        buff << match[2] + 's'
        args << Table[ match[3] ]

        _pattern = match[4]
      end

      instance_eval <<-EOS, __FILE__, __LINE__
        def format( event )
          sprintf("#{buff}", #{args.join(',')})
        end
      EOS
    end

    # The iso8601 implementation of the standard Time library is more than
    # twice as slow compared to using strftime. So, we just implement
    # it ourselves --R
    def iso8601( t )
      zone = if t.utc?
        "-00:00"
      else
        offset = t.utc_offset
        sign = offset < 0 ? '-' : '+'
        sprintf('%s%02d:%02d', sign, *(offset.abs/60).divmod(60))
      end

      t.strftime("%Y-%m-%dT%H:%M:%S#{zone}")
    end

    def level( l )
      Yell::Severities[ l ]
    end

    def message( *messages )
      messages.map { |m| to_message(m) }.join(" ")
    end

    def to_message( m )
      case m
      when Hash
        m.map { |k,v| v.respond_to?('match') && v.match(/\s/) ? "#{k}=\"#{v}\"" : "#{k}=#{v}" }.join( ", " )
      when Exception
        backtrace = m.backtrace ? "\n\t#{m.backtrace.join("\n\t")}" : ""
        sprintf("%s: %s%s", m.class, m.message, backtrace)
      else
        m
      end
    end

  end
end

