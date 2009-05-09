$:.unshift(File.dirname(__FILE__) + '/../lib')

require File.dirname(__FILE__) + '/../../../../config/environment'
require 'test/unit'
require 'rubygems'
require 'mocha'

require 'action_controller/test_process'

ActionController::Base.logger = nil
ActionController::Routing::Routes.reload rescue nil

$asset_packages_yml = YAML.load_file("#{RAILS_ROOT}/vendor/plugins/asset_packager/test/asset_packages.yml")
$asset_base_path = "#{RAILS_ROOT}/vendor/plugins/asset_packager/test/assets"

# 
# For this test only we need access to the full path of the packages JS file
#
require 'synthesis/asset_package'
module Synthesis
  class AssetPackage
    attr_reader :full_path
  end
end


class AssetPackageHelperProductionTest < Test::Unit::TestCase
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::AssetTagHelper
  include Synthesis::AssetPackageHelper

  def setup
    Synthesis::AssetPackage.any_instance.stubs(:log)
    self.stubs(:should_merge?).returns(true)

    @controller = Class.new do
      def request
        @request ||= ActionController::TestRequest.new
      end
    end.new

  end

  def build_js_expected_string(*sources)
    sources.map {|s| javascript_include_tag(s) }.join("\n")
  end
    
  def build_css_expected_string(*sources)
    sources.map {|s| stylesheet_link_tag(s) }.join("\n")
  end

  def test_js_compressed
    Synthesis::AssetPackage.build_all
    output = File.open(Synthesis::AssetPackage.find_by_target("javascripts", "compress_test").full_path).read
    assert_equal "function compress_test(){var i=0;return(false);};", output
    Synthesis::AssetPackage.delete_all
  end

  def test_js_uncompressed
    Synthesis::AssetPackage.compress_js_file = false
    Synthesis::AssetPackage.build_all

    output = File.open(Synthesis::AssetPackage.find_by_target("javascripts", "compress_test").full_path).read.strip
    input = File.open("#{$asset_base_path}/javascripts/compress_test.js").read.strip + "\n\n;"
    assert_equal input, output
    Synthesis::AssetPackage.delete_all
  end

  
end
