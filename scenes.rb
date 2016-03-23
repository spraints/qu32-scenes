#/ Usage: ruby scenes.rb SCENE001.DAT

def main(path)
  File.open path, "rb" do |file|
    reader = SceneReader.new(file, ScenePrinter.new)
    reader.read
  end
end

class SceneReader < Struct.new(:file, :delegate)
  def read
    delegate_bytes 12
    delegate_string :scene_name, 32
    delegate_bytes 160
    (1..32).each do |ch|
      delegate_string "ch#{ch}_name", 6
      delegate_bytes 186
    end
    delegate_bytes 192*6
    ([:lr, 1, 2, 3, 4, "5_6", "7_8", "9_10"]).each do |mix|
      delegate_string "mix#{mix}_name", 6
      delegate_bytes 186
    end
    delegate.call :pos, file.pos, file.size
    #10.times { delegate_bytes 40 }
  end

  private

  def delegate_bytes(size)
    delegate.bytes file.read(size)
  end

  def delegate_string(label, size)
    delegate.send(label, file.read(size).split("\0", 2).first)
  end
end

class ScenePrinter
  def bytes(data)
    #p [:bytes, data]
  end

  def method_missing(*msg)
    p msg
  end
end

if ARGV.size == 1 && File.exist?(path = ARGV[0])
  main(path)
else
  system "cat #{__FILE__} | grep ^#/ | cut -c4-"
  exit 1
end
