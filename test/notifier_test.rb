require 'test_helper'

class NotifierTest < Test::Unit::TestCase

  def setup
    ENV['PROBY_TASK_ID'] = nil
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
  end

  def teardown
    FakeWeb.allow_net_connect = true
  end

  should "not send the notification if the api_key is not set" do
    assert_nil Proby.send_start_notification("abc123")
  end

  context "with an api key set" do
    setup do
      Proby.api_key = '1234567890abcdefg'
    end

    should "not send the notification if a task id was not specified" do
      assert_nil Proby.send_start_notification
    end

    should "not send the notification if a task id is blank" do
      assert_nil Proby.send_start_notification("  ")
    end

    should "send a start notification if a task_id is specified in the call" do
      FakeWeb.register_uri(:post, "https://proby.signalhq.com/api/v1/tasks/abc123xyz456/start.json", :status => ["200", "OK"])
      assert_equal 200, Proby.send_start_notification("abc123xyz456")
    end

    should "send a start notification if a task_id is specified in an environment variable" do
      ENV['PROBY_TASK_ID'] = "uuu777sss999"
      FakeWeb.register_uri(:post, "https://proby.signalhq.com/api/v1/tasks/uuu777sss999/start.json", :status => ["200", "OK"])
      assert_equal 200, Proby.send_start_notification
    end

    should "send a finish notification if a task_id is specified in the call" do
      FakeWeb.register_uri(:post, "https://proby.signalhq.com/api/v1/tasks/abc123xyz456/finish.json", :status => ["200", "OK"])
      assert_equal 200, Proby.send_finish_notification("abc123xyz456")
    end

    should "send a finish notification with options if options are specified" do
      FakeWeb.register_uri(:post, "https://proby.signalhq.com/api/v1/tasks/abc123xyz456/finish.json", :status => ["200", "OK"])
      assert_equal 200, Proby.send_finish_notification("abc123xyz456", :failed => true, :error_message => "something bad happened")
    end

    should "send a finish notification if a task_id is specified in an environment variable" do
      ENV['PROBY_TASK_ID'] = "iii999ooo222"
      FakeWeb.register_uri(:post, "https://proby.signalhq.com/api/v1/tasks/iii999ooo222/finish.json", :status => ["200", "OK"])
      assert_equal 200, Proby.send_finish_notification
    end
  end

end
