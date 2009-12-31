require "test_helper"

class CssFileTest < Test::Unit::TestCase
  context "linked assets" do
    should "fetch all url()'s as asset paths" do
      css = Juicer::CssFile.new()

      assert_equals hmm, css.assets
    end
  end
end
