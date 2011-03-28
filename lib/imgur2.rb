require 'net/http'
require 'json'

###
# Stupid simple class for uploading to imgur.
#
#   client = Imgur2.new 'my imgur key'
#   p File.open(ARGV[0], 'rb') { |f|
#     client.upload f
#   }
class Imgur2 < Struct.new(:key)
  VERSION = '1.1.0'

  def self.run argv
    client = Imgur2.new '65aea9a07b4f6110c90248ffa247d41a'
    fh     = get_image argv[0]
    link   = client.upload(fh)['upload']['links']['original']
    client.paste link
    puts link
  ensure
    fh.close if fh
  end

  def self.get_image filename = nil
    return open(filename, 'rb') if filename
    begin
      require 'pasteboard'
      require 'stringio'

      clipboard = Pasteboard.new

      data = clipboard[0, Pasteboard::Type::JPEG]

      return StringIO.new data if data
    rescue LoadError
    end

    $stdin
  end

  def upload io
    url = URI.parse 'http://api.imgur.com/2/upload.json'

    JSON.parse Net::HTTP.start(url.host) { |http|
      post = Net::HTTP::Post.new url.path
      post.set_form_data('key'   => key,
                         'image' => [io.read].pack('m'),
                         'type'  => 'base64')
      http.request(post).body
    }
  end

  ##
  # Tries to find clipboard copy executable and if found puts +link+ in your
  # clipboard.

  def paste link
    require 'pasteboard'

    clipboard = Pasteboard.new

    clipboard.put_url link
  rescue LoadError
    clipboard = %w{
      /usr/bin/pbcopy
      /usr/bin/xclip
    }.find { |path| File.exist? path }

    if clipboard
      IO.popen clipboard, 'w' do |io| io.write link end
    end
  end
end
