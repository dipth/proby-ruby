require 'test_helper'

class ProbyTaskTest < Test::Unit::TestCase

  def setup
    Proby.api_key = '1234567890abcdefg'
    FakeWeb.clean_registry
    FakeWeb.allow_net_connect = false
  end

  def teardown
    FakeWeb.allow_net_connect = true
  end

  should "raise an error if the api key has not been set" do
    Proby.api_key = nil
    e = assert_raise(Proby::InvalidApiKeyException) do
      Proby::ProbyTask.find(:all)
    end
    assert_equal "Your Proby API key has not been set.  Set it using Proby.api_key = 'my_api_key'", e.message
  end

  should "be able to get a list of tasks" do
    FakeWeb.register_uri(:get, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks.json', :status => ['200', 'OK'], :body => <<-END)
{
  "tasks": [
    {
      "name": "task 1",
      "api_id": "abc123",
      "crontab": "* * * * *",
      "paused": false,
      "time_zone": "UTC",
      "machine": null,
      "finish_alarms_enabled": true,
      "maximum_run_time": null,
      "start_notification_grace_period": 5,
      "consecutive_alarmed_tasks": 0,
      "consecutive_alarmed_tasks_required_to_trigger_alarm": 1,
      "created_at": "2012-04-25 20:10:20 UTC",
      "updated_at": "2012-04-25 20:10:20 UTC",
      "status": {
        "description": "OK",
        "details": ""
      }
    },
    {
      "name": "task 2",
      "api_id": "abc456",
      "crontab": "* * * * *",
      "paused": false,
      "time_zone": "UTC",
      "machine": "dopey",
      "finish_alarms_enabled": true,
      "maximum_run_time": 90,
      "start_notification_grace_period": 5,
      "consecutive_alarmed_tasks": 3,
      "consecutive_alarmed_tasks_required_to_trigger_alarm": 1,
      "created_at": "2012-04-25 20:10:20 UTC",
      "updated_at": "2012-04-25 20:10:20 UTC",
      "status": {
        "description": "OK",
        "details": "Wonderful"
      }
    },
    {
      "name": "task 3",
      "api_id": "abc789",
      "crontab": "1 2 3 4 5",
      "paused": false,
      "time_zone": "UTC",
      "machine": null,
      "finish_alarms_enabled": true,
      "maximum_run_time": null,
      "start_notification_grace_period": 5,
      "consecutive_alarmed_tasks": 0,
      "consecutive_alarmed_tasks_required_to_trigger_alarm": 1,
      "created_at": "2012-04-25 20:10:20 UTC",
      "updated_at": "2012-04-25 20:10:20 UTC",
      "status": {
        "description": "OK",
        "details": ""
      }
    }
  ]
}
END
    tasks = Proby::ProbyTask.find(:all)
    assert_equal 3, tasks.size

    task = tasks[1]
    assert_equal "task 2", task.name
    assert_equal "abc456", task.api_id
    assert_equal "* * * * *", task.crontab
    assert_equal false, task.paused
    assert_equal "UTC", task.time_zone
    assert_equal "dopey", task.machine
    assert_equal true, task.finish_alarms_enabled
    assert_equal 90, task.maximum_run_time
    assert_equal 5, task.start_notification_grace_period
    assert_equal 3, task.consecutive_alarmed_tasks
    assert_equal 1, task.consecutive_alarmed_tasks_required_to_trigger_alarm
    assert_equal Time.utc(2012, 4, 25, 20, 10, 20), task.created_at
    assert_equal Time.utc(2012, 4, 25, 20, 10, 20), task.updated_at
    assert_equal "OK", task.status.description
    assert_equal "Wonderful", task.status.details
  end

  should "raise an exception if unable to get a list of tasks" do
    FakeWeb.register_uri(:get, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks.json', :status => ['400', 'Bad request'], :body => <<-END)
{
  "request" : "http://www.example.com/api/v1/tasks.json",
  "message" : "Something bad happened"
}
END
    e = assert_raise Proby::ApiException do
      Proby::ProbyTask.find(:all)
    end
    assert e.message.include?("API request failed with a response code of 400")
    assert e.message.include?("Something bad happened")
  end

  should "be able to display a specific task" do
    FakeWeb.register_uri(:get, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks/abc123.json', :status => ['200', 'OK'], :body => <<-END)
{
  "task": {
    "name": "task 1",
    "api_id": "abc123",
    "crontab": "* * * * *",
    "paused": false,
    "time_zone": "UTC",
    "machine": "dopey",
    "finish_alarms_enabled": true,
    "maximum_run_time": 90,
    "start_notification_grace_period": 5,
    "consecutive_alarmed_tasks": 3,
    "consecutive_alarmed_tasks_required_to_trigger_alarm": 1,
    "created_at": "2012-04-25 20:10:20 UTC",
    "updated_at": "2012-04-25 20:10:20 UTC",
    "status": {
      "description": "OK",
      "details": "Wonderful"
    }
  }
}
END

    task = Proby::ProbyTask.find("abc123")
    assert_equal "task 1", task.name
    assert_equal "abc123", task.api_id
    assert_equal "* * * * *", task.crontab
    assert_equal false, task.paused
    assert_equal "UTC", task.time_zone
    assert_equal "dopey", task.machine
    assert_equal true, task.finish_alarms_enabled
    assert_equal 90, task.maximum_run_time
    assert_equal 5, task.start_notification_grace_period
    assert_equal 3, task.consecutive_alarmed_tasks
    assert_equal 1, task.consecutive_alarmed_tasks_required_to_trigger_alarm
    assert_equal Time.utc(2012, 4, 25, 20, 10, 20), task.created_at
    assert_equal Time.utc(2012, 4, 25, 20, 10, 20), task.updated_at
    assert_equal "OK", task.status.description
    assert_equal "Wonderful", task.status.details
  end

  should "return nil if the specific task could not be found" do
    FakeWeb.register_uri(:get, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks/abc123.json', :status => ['404', 'Not Found'])
    assert_nil Proby::ProbyTask.find("abc123")
  end

  should "raise an exception if unable to fetch a specific task" do
    FakeWeb.register_uri(:get, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks/abc123.json', :status => ['400', 'Bad request'], :body => <<-END)
{
  "request" : "http://www.example.com/api/v1/tasks/abc123.json",
  "message" : "Something bad happened"
}
END
    e = assert_raise Proby::ApiException do
      Proby::ProbyTask.find("abc123")
    end
    assert e.message.include?("API request failed with a response code of 400")
    assert e.message.include?("Something bad happened")
  end

  should "raise an error if trying to fetch a task without specifying the api_id" do
    assert_raise(Proby::InvalidParameterException) { Proby::ProbyTask.find(nil) }
    assert_raise(Proby::InvalidParameterException) { Proby::ProbyTask.find(" ") }
  end

  should "be able to create a new task" do
    FakeWeb.register_uri(:post, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks.json', :status => ['201', 'Created'], :body => <<-END)
{
  "task": {
    "name": "task 1",
    "api_id": "abc123",
    "crontab": "* * * * *",
    "paused": false,
    "time_zone": "UTC",
    "machine": "dopey",
    "finish_alarms_enabled": true,
    "maximum_run_time": 90,
    "start_notification_grace_period": 5,
    "consecutive_alarmed_tasks": 3,
    "consecutive_alarmed_tasks_required_to_trigger_alarm": 1,
    "created_at": "2012-04-25 20:10:20 UTC",
    "updated_at": "2012-04-25 20:10:20 UTC",
    "status": {
      "description": "OK",
      "details": "Wonderful"
    }
  }
}
END

    # Not specifying all attributes, for berivity
    task = Proby::ProbyTask.create(:name => "abc123", :crontab => "* * * * *")

    assert_equal "task 1", task.name
    assert_equal "abc123", task.api_id
    assert_equal "* * * * *", task.crontab
    assert_equal false, task.paused
    assert_equal "UTC", task.time_zone
    assert_equal "dopey", task.machine
    assert_equal true, task.finish_alarms_enabled
    assert_equal 90, task.maximum_run_time
    assert_equal 5, task.start_notification_grace_period
    assert_equal 3, task.consecutive_alarmed_tasks
    assert_equal 1, task.consecutive_alarmed_tasks_required_to_trigger_alarm
    assert_equal Time.utc(2012, 4, 25, 20, 10, 20), task.created_at
    assert_equal Time.utc(2012, 4, 25, 20, 10, 20), task.updated_at
    assert_equal "OK", task.status.description
    assert_equal "Wonderful", task.status.details
  end

  should "raise an exception if unable to create a task" do
    FakeWeb.register_uri(:post, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks.json', :status => ['400', 'Bad request'], :body => <<-END)
{
  "request" : "http://www.example.com/api/v1/tasks.json",
  "message" : "Something bad happened"
}
END
    e = assert_raise Proby::ApiException do
      Proby::ProbyTask.create(:name => "foo", :crontab => "invalid")
    end
    assert e.message.include?("API request failed with a response code of 400")
    assert e.message.include?("Something bad happened")
  end

  should "raise an error if trying to create a task without specifying the attributes" do
    assert_raise(Proby::InvalidParameterException) { Proby::ProbyTask.create(nil) }
    assert_raise(Proby::InvalidParameterException) { Proby::ProbyTask.create({}) }
  end

  should "raise an error if trying to create a task without the necessary required attributes" do
    assert_raise(Proby::InvalidParameterException) { Proby::ProbyTask.create(:name => "Foo") }
    assert_raise(Proby::InvalidParameterException) { Proby::ProbyTask.create(:crontab => "* * * * *") }
  end

  should "be able to update a task" do
    FakeWeb.register_uri(:put, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks/abc123.json', :status => ['200', 'OK'])
    proby_task = Proby::ProbyTask.new('api_id' => 'abc123', 'name' => 'Test task', 'crontab' => '* * * * *')
    proby_task.name = "New name"
    proby_task.crontab = "1 2 3 4 5"
    proby_task.time_zone = "UTC"
    proby_task.machine = "sleepy"
    proby_task.finish_alarms_enabled = "false"
    proby_task.maximum_run_time = 60
    proby_task.start_notification_grace_period = 10
    proby_task.consecutive_alarmed_tasks_required_to_trigger_alarm = 4
    assert proby_task.save
  end

  should "raise an exception if unable to update a task" do
    FakeWeb.register_uri(:put, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks/abc123.json', :status => ['400', 'Bad request'], :body => <<-END)
{
  "request" : "http://www.example.com/api/v1/tasks/abc123.json",
  "message" : "Something bad happened"
}
END
    proby_task = Proby::ProbyTask.new('api_id' => 'abc123', 'name' => 'Test task', 'crontab' => '* * * * *')
    proby_task.name = "New name"
    proby_task.crontab = "1 2 3 4 5"
    e = assert_raise Proby::ApiException do
      proby_task.save
    end
    assert e.message.include?("API request failed with a response code of 400")
    assert e.message.include?("Something bad happened")
  end

  should "raise an error if trying to update a task without the necessary required attributes" do
    proby_task = Proby::ProbyTask.new('api_id' => 'abc123', 'name' => 'Test task', 'crontab' => '* * * * *')

    proby_task.name = nil
    assert_raise(Proby::InvalidParameterException) { proby_task.save }

    proby_task.name = "  "
    assert_raise(Proby::InvalidParameterException) { proby_task.save }

    proby_task.crontab = nil
    assert_raise(Proby::InvalidParameterException) { proby_task.save }

    proby_task.crontab = "  "
    assert_raise(Proby::InvalidParameterException) { proby_task.save }
  end

  should "be able to delete a task" do
    FakeWeb.register_uri(:delete, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks/abc123.json', :status => ['200', 'OK'])
    proby_task = Proby::ProbyTask.new('api_id' => 'abc123', 'name' => 'Test task', 'crontab' => '* * * * *')
    assert proby_task.delete
    assert proby_task.frozen?
    e = assert_raise TypeError do
      proby_task.name = "foo"
    end
    assert_equal "can't modify frozen object", e.message
  end

  should "raise an exception if unable to delete a task" do
    FakeWeb.register_uri(:delete, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks/abc123.json', :status => ['400', 'Bad request'], :body => <<-END)
{
  "request" : "http://www.example.com/api/v1/tasks/abc123.json",
  "message" : "Something bad happened"
}
END
    proby_task = Proby::ProbyTask.new('api_id' => 'abc123', 'name' => 'Test task', 'crontab' => '* * * * *')
    e = assert_raise Proby::ApiException do
      proby_task.delete
    end
    assert e.message.include?("API request failed with a response code of 400")
    assert e.message.include?("Something bad happened")
  end

  should "be able to pause a task" do
    FakeWeb.register_uri(:post, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks/abc123/pause.json', :status => ['200', 'OK'])
    proby_task = Proby::ProbyTask.new('api_id' => 'abc123', 'name' => 'Test task', 'crontab' => '* * * * *', 'paused' => 'false')
    assert proby_task.pause
    assert_equal true, proby_task.paused
  end

  should "raise an exception if unable to pause a task" do
    FakeWeb.register_uri(:post, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks/abc123/pause.json', :status => ['400', 'Bad request'], :body => <<-END)
{
  "request" : "http://www.example.com/api/v1/tasks/abc123/pause.json",
  "message" : "Something bad happened"
}
END
    proby_task = Proby::ProbyTask.new('api_id' => 'abc123', 'name' => 'Test task', 'crontab' => '* * * * *')
    e = assert_raise Proby::ApiException do
      proby_task.pause
    end
    assert e.message.include?("API request failed with a response code of 400")
    assert e.message.include?("Something bad happened")
  end

  should "be able to unpause a task" do
    FakeWeb.register_uri(:post, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks/abc123/unpause.json', :status => ['200', 'OK'])
    proby_task = Proby::ProbyTask.new('api_id' => 'abc123', 'name' => 'Test task', 'crontab' => '* * * * *', 'paused' => 'true')
    assert proby_task.unpause
    assert_equal false, proby_task.paused
  end

  should "raise an exception if unable to unpause a task" do
    FakeWeb.register_uri(:post, Proby::ProbyHttpApi.base_uri + '/api/v1/tasks/abc123/unpause.json', :status => ['400', 'Bad request'], :body => <<-END)
{
  "request" : "http://www.example.com/api/v1/tasks/abc123/unpause.json",
  "message" : "Something bad happened"
}
END
    proby_task = Proby::ProbyTask.new('api_id' => 'abc123', 'name' => 'Test task', 'crontab' => '* * * * *')
    e = assert_raise Proby::ApiException do
      proby_task.unpause
    end
    assert e.message.include?("API request failed with a response code of 400")
    assert e.message.include?("Something bad happened")
  end

end
