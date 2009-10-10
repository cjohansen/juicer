require File.expand_path(File.join(File.dirname(__FILE__), %w[.. test_helper])) unless defined?(Juicer)

class TestImageEmbed < Test::Unit::TestCase
  def setup
    Juicer::Test::FileSetup.new.create
    @embedder = Juicer::ImageEmbed.new
  end

  def teardown
    Juicer::Test::FileSetup.new.delete
  end

  def test_does_not_modify_regular_path
    path = '/somepath/somefile.png'
    assert_equal( path, @embedder.embed( path ) )
  end

  def test_does_not_modify_path_flagged_as_not_embeddable
    path = '/somepath/somefile.png?embed=false'
    assert_equal( path, @embedder.embed( path ) )
  end

  def test_should_embed_image_when_path_flagged_as_embeddable
    path = '/somepath/somefile.png?embed=true'
    assert_not_equal( path, @embedder.embed( path ) )
  end

  def test_should_embed_png_gif_jpg_jpeg_images
    path = '/somepath/somefile.png?embed=true'
    assert_not_equal( path, @embedder.embed( path ) )

    path = '/somepath/somefile.gif?embed=true'
    assert_not_equal( path, @embedder.embed( path ) )

    path = '/somepath/somefile.jpg?embed=true'
    assert_not_equal( path, @embedder.embed( path ) )

    path = '/somepath/somefile.jpeg?embed=true'
    assert_not_equal( path, @embedder.embed( path ) )
  end

  def test_should_not_embed_unsupported_filetypes
    path = '/somepath/somefile.js?embed=true'
    assert_equal( path, @embedder.embed( path ) )

    path = '/somepath/somefile.swf?embed=true'
    assert_equal( path, @embedder.embed( path ) )

    path = '/somepath/somefile.ico?embed=true'
    assert_equal( path, @embedder.embed( path ) )

    path = '/somepath/somefile.bmp?embed=true'
    assert_equal( path, @embedder.embed( path ) )
  end

  def test_should_set_correct_mimetype
    path = '/somepath/somefile.png?embed=true'
    assert_match(/image\/png/, @embedder.embed( path ) )

    path = '/somepath/somefile.gif?embed=true'
    assert_match(/image\/gif/, @embedder.embed( path ) )

    path = '/somepath/somefile.jpg?embed=true'
    assert_match(/image\/jpg/, @embedder.embed( path ) )

    path = '/somepath/somefile.jpeg?embed=true'
    assert_match(/image\/jpeg/, @embedder.embed( path ) )
  end

end
