#/ Usage: ruby scenes.rb [options] SCENE001.DAT
#/ where options can be
#/   --channel 1
#/   --channel 1,3

def main(path, options)
  File.open path, "rb" do |file|
    reader = SceneReader.new(file, ScenePrinter.new(options))
    reader.read
  end
end

class SceneReader < Struct.new(:file, :delegate)
  def read
    skip_bytes 12
    delegate_string :scene_name, 32
    skip_bytes 160
    (1..32).each do |ch|
      delegate.channel ch
      delegate_string :name, 6
      if ENV["CHANNEL_ALL"]
        skip_bytes 186
      else
        #1
        skip_bytes 16
        #2
        skip_bytes 5
        delegate_bytes :input, 1
        skip_bytes 8
        delegate_bytes :tbd, 2
        #3
        delegate_bytes :tbd, 2
        delegate_bytes :tbd, 2
        skip_bytes 2
        delegate_bytes :tbd, 2
        skip_bytes 8
        #4
        skip_bytes 16
        #5
        skip_bytes 2
        delegate_bytes :tbd, 2
        skip_bytes 3
        delegate_bytes :tbd, 1
        skip_bytes 7
        delegate_bytes :tbd, 1
        #6
        skip_bytes 16
        #7
        skip_bytes 16
        #8
        skip_bytes 16
        #9
        skip_bytes 16
        #10
        skip_bytes 4
        delegate_bytes :tbd, 2
        skip_bytes 6
        delegate_bytes :tbd, 4
        #11
        delegate_bytes :tbd, 2
        skip_bytes 14
        #12 (10 bytes)
        skip_bytes 10
      end
    end
    skip_bytes 192*6
    ([:lr, 1, 2, 3, 4, "5_6", "7_8", "9_10"]).each do |mix|
      delegate.mix mix
      delegate_string :name, 6
      skip_bytes 186
    end
    delegate.call :progress, :pos => file.pos, :size => file.size
    #10.times { delegate_bytes 40 }
  end

  private

  def skip_bytes(size)
    while size > 16
      delegate.skip file.read(16)
      size -= 16
    end
    delegate.skip file.read(size)
  end

  def delegate_bytes(label, size)
    delegate.send(label, file.read(size))
  end

  def delegate_string(label, size)
    delegate.send(label, file.read(size).split("\0", 2).first)
  end
end

class ScenePrinter
  def initialize(_)
  end

  def bytes(data)
    rendered = []
    rendered << data.unpack("H2"*data.bytesize).join(" ")
    case data.bytesize
    when 1
      rendered += data.unpack("C")
    when 2
      rendered += data.unpack("S>")
      rendered += data.unpack("S<")
    when 4
      rendered << data.unpack("S>S>").join(" ")
      rendered << data.unpack("S<S<").join(" ")
      rendered += data.unpack("L>")
      rendered += data.unpack("L<")
    end
    p [:bytes, data.bytesize, *rendered]
  end

  def skip(data)
    bytes(data) if ENV["DEBUG"]
  end

  def channel(n)
    puts "channel #{n}:"
  end

  def mix(n)
    puts "mix #{n}:"
  end

  def method_missing(*msg)
    p msg
  end

  def p(obj)
    puts "  #{obj.inspect}"
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
  when "--channel"
    options[:channels] ||= []
    options[:channels] += ARGV.shift.split(",").map { |c| channel_name(c) }
  when /^--/
    usage
  else
    path = arg
  end
end

path or usage

main path, options
