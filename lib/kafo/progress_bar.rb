# encoding: UTF-8
require 'powerbar'
require 'ansi/code'
require 'set'

module Kafo
# Progress bar base class
#
# To define new progress bar you can inherit from this class and implement
# #finite_template and #infinite_template methods. Also you may find useful to
# change more methods like #done_message or #print_error
  class ProgressBar
    MONITOR_RESOURCE = %r{\w*MONITOR_RESOURCE (?<resource>[^\]]+\])}
    EVALTRACE_START = %r{/(?<resource>.+\]): Starting to evaluate the resource( \((?<count>\d+) of (?<total>\d+)\))?}
    EVALTRACE_END = %r{/(?<resource>.+\]): Evaluated in [\d\.]+ seconds}
    PREFETCH = %r{Prefetching .* resources for}

    def initialize
      @lines                                    = 0
      @all_lines                                = 0
      @total                                    = :unknown
      @resources                                = Set.new
      @term_width                               = HighLine::SystemExtensions.terminal_size[0] || 0
      @bar                                      = PowerBar.new
      @bar.settings.tty.infinite.template.main  = infinite_template
      @bar.settings.tty.finite.template.main    = finite_template
      @bar.settings.tty.finite.template.padchar = ' '
      @bar.settings.tty.finite.template.barchar = '.'
      @bar.settings.tty.finite.output           = Proc.new { |s| $stderr.print s }
    end

    def update(line)
      @all_lines += 1

      # we print every 20th line during installation preparing otherwise only update at EVALTRACE_START
      update_bar = (@total == :unknown && @all_lines % 20 == 0)
      force_update = false

      if (line_monitor = MONITOR_RESOURCE.match(line))
        @resources << line_monitor[:resource]
        @total = (@total == :unknown ? 1 : @total + 1)
      end

      if (line_start = EVALTRACE_START.match(line))
        if line_start[:total]
          # Puppet 6.6 introduced progress in evaltrace
          # Puppet counts 1-based where we count 0-based here
          new_lines = line_start[:count].to_i - 1
          new_total = line_start[:total].to_i
          if new_lines != @lines || @total != new_total
            @lines = new_lines
            @total = new_total
            update_bar = true
            force_update = true
          end
        end

        if (known_resource = find_resource(line_start[:resource]))
          line = known_resource
          update_bar = true
          force_update = true
        end
      end

      if (line_end = EVALTRACE_END.match(line)) && @total != :unknown && @lines < @total
        if (known_resource = find_resource(line_end[:resource]))
          @resources.delete(known_resource)  # ensure it's only counted once
          @lines += 1
        end
      end

      if PREFETCH =~ line
        update_bar = true
        force_update = true
      end

      if update_bar
        @bar.show({ :msg   => format(line),
                    :done  => @lines,
                    :total => @total }, force_update)
      end
    end

    def close
      @bar.show({ :msg   => done_message,
                  :done  => @total == :unknown ? @bar.done + 1 : @total,
                  :total => @total }, true)
      @bar.close
    end

    def print(line)
      @bar.print line
    end

    def print_error(line)
      print line
    end

    private

    def done_message
      text = 'Done'
      text + (' ' * (50 - text.length))
    end

    def format(line)
      (line.tr("\r\n", '') + (' ' * 50))[0..49]
    end

    def finite_template
      'Installing... [${<percent>%}]'
    end

    def infinite_template
      'Installing...'
    end

    def find_resource(resource)
      found = resource.match(%r{Stage.*\/(?<resource>.*\[.*\])$})
      found.nil? ? nil : found[:resource]
    end

  end
end

require 'kafo/progress_bars/colored'
require 'kafo/progress_bars/black_white'
