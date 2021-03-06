require 'helper'

class TestFeature < Test::Unit::TestCase
  def setup
    eval <<-CLASSDEFS
    class FooWidget < Test::Right::Widget
      def bar
      end
    end
    CLASSDEFS
    @driver = MockDriver.new
  end
  def teardown
    Test::Right::Feature.wipe!
    Test::Right::Widget.wipe!
  end

  def test_with
    eval <<-CLASSDEFS
    class FeatureThatUsesWith < Test::Right::Feature
      def use_with
        with FooWidget do |w|
          w.bar
        end
      end
    end
    CLASSDEFS

    widget = mock()
    widget.expects(:exists?).at_least_once.returns(true)
    widget.expects(:bar)

    FooWidget.expects(:new).at_least_once.returns(widget)
    feature = FeatureThatUsesWith.new(@driver, nil)
    feature.use_with

    FooWidget.expects(:new).returns(widget)
    widget.expects(:exists?).at_least_once.returns(false)

    saved_timeout = Test::Right::Feature::WIDGET_TIMEOUT
    begin
      Test::Right::Feature.send(:const_set, 'WIDGET_TIMEOUT', 0.1)
      assert_raises Test::Right::WidgetNotPresentError do
        feature.use_with
      end
    ensure
      Test::Right::Feature.send(:const_set, 'WIDGET_TIMEOUT', saved_timeout)
    end
  end

  def test_wait_for
    eval <<-CLASSDEFS
    class FeatureThatUsesWaitFor < Test::Right::Feature
      def use_wait_for
        wait_for FooWidget
      end
    end
    CLASSDEFS

    widget = mock()
    widget.expects(:exists?).at_least_once.returns(true)

    FooWidget.expects(:new).at_least_once.returns(widget)
    feature = FeatureThatUsesWaitFor.new(@driver, nil)
    feature.use_wait_for
  end

  def test_data
    $data_value = nil

    eval <<-CLASSDEFS
    class FeatureThatUsesData < Test::Right::Feature
      def use_data
        $data_value = data[:foo]
      end
    end
    CLASSDEFS

    data = {:foo => 'foo'}
    feature = FeatureThatUsesData.new(@driver, data)
    feature.use_data
    assert_equal 'foo', $data_value
  end
end
