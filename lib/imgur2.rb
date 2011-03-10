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
  VERSION = '1.0.0'

  def self.run argv
    client = Imgur2.new '65aea9a07b4f6110c90248ffa247d41a'
    fh     = argv[0] ? File.open(argv[0], 'rb') : $stdin
    link   = client.upload(fh)['upload']['links']['original']
    client.paste link
    puts link
  ensure
    fh.close
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
    clipboard = %w{
      /usr/bin/pbcopy
      /usr/bin/xclip
    }.find { |path| File.exist? path }

    if clipboard
      IO.popen clipboard, 'w' do |io| io.write link end
    end
  end
end