require 'helper'
require 'tmpdir'

class TestCLI < Test::Unit::TestCase
  include TestRightTestingUtils

  def test_fails_with_no_widgets_dir
    assert_raises Test::Right::ConfigurationError do
      cli = Test::Right::CLI.new
      cli.load_widgets
    end
  end

  def test_finds_widgets
    in_new_dir do
      make_widget

      cli = Test::Right::CLI.new
      cli.load_widgets
      
      assert !cli.widgets.empty?, "No widgets loaded"
    end
  end

  def test_avoids_non_widgets
    in_new_dir do
      make_widget("foo.rb.zzz")

      cli = Test::Right::CLI.new
      cli.load_widgets

      assert cli.widgets.empty?, "Loaded something that's not a widget: #{cli.widgets}"
    end
  end

  def test_finds_features
    in_new_dir do
      make_feature

      cli = Test::Right::CLI.new
      cli.load_features
      
      assert !cli.features.empty?, "No features loaded"
    end
  end

  def test_start
    in_new_dir do
      make_widget
      make_feature

      cli = Test::Right::CLI.new
      cli.start([])
      assert true # Start didn't cause any errors
    end
  end

  def test_generate
    in_new_dir do
      cli = Test::Right::CLI.new
      cli.start(["install"])
      assert File.exists? "test/right"
    end
  end

  def test_load_config
    in_new_dir do
      make_config

      cli = Test::Right::CLI.new
      cli.load_config
      assert_equal "http://TESTING", cli.config[:base_url]
    end
  end

  def test_finds_testright
    in_new_dir do
      Dir.mkdir("test")
      Dir.mkdir("test/right")
      Dir.chdir("test/right") do
        make_widget
        make_feature
      end
      cli = Test::Right::CLI.new
      assert_nothing_raised do
        cli.start([])
      end
    end
  end

  def test_setup
    in_new_dir do
      File.open "setup.rb", "wb" do |f|
        f.print <<-EOF
#!/usr/bin/env ruby
File.open "foo.tmp", "wb" do |f|
  f.print "foo"
end
        EOF

        f.chmod(0755)
      end
      make_widget
      make_feature

      cli = Test::Right::CLI.new
      cli.start([])
      assert File.exists?("foo.tmp"), "CLI didn't run setup.rb"
    end
  end

  private

  def make_config
    File.open "config.yml", "wb" do |f|
      f.print <<-CONFIG
        base_url: http://TESTING
      CONFIG
    end
  end

  def make_widget(filename="foo_widget.rb")
    Dir.mkdir("widgets")

    File.open "widgets/#{filename}", 'wb' do |f|
      f.print <<-WIDGET
        class FooWidget < Test::Right::Widget
        end
      WIDGET
    end
  end

  def make_feature
    Dir.mkdir("features")

    File.open "features/login.rb", 'wb' do |f|
      f.print <<-WIDGET
        class LoginFeature < Test::Right::Feature
        end
      WIDGET
    end
  end
end
