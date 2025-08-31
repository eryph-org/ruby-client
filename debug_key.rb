require 'openssl'
require 'tempfile'

temp_key = File.join(Dir.tmpdir, 'debug-test.key')
File.write(temp_key, OpenSSL::PKey::RSA.generate(2048).to_pem)
puts temp_key