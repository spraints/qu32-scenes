#/ Usage: ruby scenes.rb [options] SCENE001.DAT

def main(path, options)
  File.open path, "rb" do |file|
    reader = SceneReader.new(file, ScenePrinter.new(options))
    reader.read
  end
end

class SceneReader < Struct.new(:file, :delegate)
  def read
    read_header
    (1..32).each do |channel|
      read_channel channel
    end
    (1..6).each do |huh|
      skip :something, huh, 192
    end
    %w(LR mix1 mix2 mix3 mix4 mix56 mix78 mix910).each do |mix|
      read_mix mix
    end
    report_remainder
  end

  private

  def read_header
    skip :header, 12
    report :header, :scene_name, read_string(32)
    skip :header, 32
  end

  def read_channel(number)
    skip :channel, number, 8*16
    report :channel, number, :name, read_string(6)
    skip :channel, number, 4*16-6
  end

  def read_mix(name)
    skip :mix, name, 8*16
    report :mix, name, :name, read_string(6)
    skip :mix, name, 4*16-6
  end

  def report_remainder
    report :remaining, :pos, file.pos
    report :remaining, :size, file.size
  end

  def read_string(size)
    file.read(size).split("\0", 2).first
  end

  def read_bytes(size)
    Bytes.new(file.read(size))
  end

  def skip(*context)
    size = context.pop
    while size > 16
      delegate.skip(*context, :skip, file.pos.to_s(8), read_bytes(16))
      size -= 16
    end
    delegate.skip(*context, :skip, file.pos.to_s(8), read_bytes(size))
  end

  def report(*context)
    delegate.report(*context)
  end
end

class Bytes
  def initialize(raw)
    @raw = raw
  end

  def to_s
    @raw.unpack("H2"*@raw.bytesize).join(" ")
  end
end

class ScenePrinter
  def initialize(_)
  end

  def skip(*context)
    report(*context) if ENV["DEBUG"]
  end

  def report(*context)
    value = context.pop
    key = context.pop
    adjust_context context
    report_value key, value
  end

  private

  def report_value(key, value)
    puts "#{indent}#{key}: #{value}"
  end

  def adjust_context(context)
    @context ||= []
    return if @context == context
#    require "byebug"; byebug unless $skip
    different = false
    context.zip(@context).each_with_index do |(new, old), level|
      if different ||= old != new
        puts "#{indent(level)}#{new}:"
      end
    end
    @context = context
  end

  def indent(level = nil)
    level ||= (@context ? @context.size : 0)
    "  "*level
  end

  def puts(*)
    super unless @off
  rescue Errno::EPIPE
    @off = true
  end
end

def usage
  system "cat #{__FILE__} | grep ^#/ | cut -c4-"
  exit 1
end

path = nil
options = {}
while ARGV.any?
  case arg = ARGV.shift
#  when "--channel"
#    options[:channels] ||= []
#    options[:channels] += ARGV.shift.split(",").map { |c| channel_name(c) }
  when /^--/
    usage
  else
    path = arg
  end
end

path or usage

main path, options
