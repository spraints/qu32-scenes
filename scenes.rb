#/ Usage: ruby scenes.rb SCENE001.DAT

def main(path)
end

if ARGV.size == 1 && File.exist?(path = ARGV[0])
  main(path)
else
  system "cat #{__FILE__} | grep ^#/ | cut -c4-"
  exit 1
end
