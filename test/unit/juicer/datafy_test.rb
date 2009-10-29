require 'test/unit'
require "test_helper"

class TC_Datafy < Test::Unit::TestCase

  def test_make_data_uri_text_plain
    assert_equal(SHORT_TEXT_PLAIN_URI, Datafy::make_data_uri(SHORT_STRING, TEXT_PLAIN))
    assert_equal(LONG_TEXT_PLAIN_URI, Datafy::make_data_uri(LONG_STRING, TEXT_PLAIN))
  end

  def test_make_data_uri_octet_stream
    assert_equal(SHORT_APPLICATION_OCTET_STREAM_URI, Datafy::make_data_uri(SHORT_STRING, APPLICATION_OCTET_STREAM))
    assert_equal(LONG_APPLICATION_OCTET_STREAM_URI, Datafy::make_data_uri(LONG_STRING, APPLICATION_OCTET_STREAM))
  end

  # mime types
  TEXT_PLAIN = 'text/plain'
  APPLICATION_OCTET_STREAM = 'application/octet-stream'

  # string versions
  SHORT_STRING = 'this is some text'
  SHORT_BASE64 = 'dGhpcyBpcyBzb21lIHRleHQ='
  SHORT_URLENCODED = 'this+is+some+text'

  LONG_STRING = 'this is a really long string. this is a really long string. this is a really long string. this is a really long string. this is a really long string. this is a really long string. this is a really long string. this is a really long string.'
  LONG_BASE64 = 'dGhpcyBpcyBhIHJlYWxseSBsb25nIHN0cmluZy4gdGhpcyBpcyBhIHJlYWxseSBsb25nIHN0cmluZy4gdGhpcyBpcyBhIHJlYWxseSBsb25nIHN0cmluZy4gdGhpcyBpcyBhIHJlYWxseSBsb25nIHN0cmluZy4gdGhpcyBpcyBhIHJlYWxseSBsb25nIHN0cmluZy4gdGhpcyBpcyBhIHJlYWxseSBsb25nIHN0cmluZy4gdGhpcyBpcyBhIHJlYWxseSBsb25nIHN0cmluZy4gdGhpcyBpcyBhIHJlYWxseSBsb25nIHN0cmluZy4='
  LONG_URLENCODED = 'this+is+a+really+long+string.+this+is+a+really+long+string.+this+is+a+really+long+string.+this+is+a+really+long+string.+this+is+a+really+long+string.+this+is+a+really+long+string.+this+is+a+really+long+string.+this+is+a+really+long+string.'

  # data: uris
  SHORT_APPLICATION_OCTET_STREAM_URI = "data:#{APPLICATION_OCTET_STREAM};base64,#{SHORT_BASE64}"
  SHORT_TEXT_PLAIN_URI = "data:#{TEXT_PLAIN},#{SHORT_URLENCODED}"

  LONG_APPLICATION_OCTET_STREAM_URI = "data:#{APPLICATION_OCTET_STREAM};base64,#{LONG_BASE64}"
  LONG_TEXT_PLAIN_URI = "data:#{TEXT_PLAIN},#{LONG_URLENCODED}"


end