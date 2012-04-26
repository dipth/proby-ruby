module Proby

  # Represents the status of a Proby task
  class ProbyTaskStatus
    # The description of the task (OK, ERROR, PAUSED)
    attr_reader :description

    # Any details (why the task is in the ERROR state)
    attr_reader :details

    def initialize(attributes={})
      @description = attributes['description']
      @details = attributes['details']
    end
  end

  # Represents a task in Proby
  class ProbyTask < ProbyHttpApi
    # The name of the task
    attr_accessor :name

    # The schedule for the task, specified in crontab format
    attr_accessor :crontab

    # The time zone of the machine executing the task
    attr_accessor :time_zone

    # The name of the machine that is responsible for running this task
    attr_accessor :machine

    # Should finish alarms be sent when the task runs longer than expected?
    attr_accessor :finish_alarms_enabled

    # The maximum amount of time the task is allowed to run before Proby sends
    # a finish alarm. If not specified, Proby will determine when an alarm should
    # be sent based on past run times
    attr_accessor :maximum_run_time

    # The number of minutes to wait for a task to send its start notification after it
    # should have started before sending an alarm
    attr_accessor :start_notification_grace_period

    # The number of consecutive tasks that must fail before an alarm is sent
    attr_accessor :consecutive_alarmed_tasks_required_to_trigger_alarm

    # The API Task ID of the task
    attr_reader :api_id

    # Is the task currently paused?
    attr_reader :paused

    # The number of consecutive times this task has triggered an alarm
    attr_reader :consecutive_alarmed_tasks

    # The date and time this task was created
    attr_reader :created_at

    # The date and time this task was updated
    attr_reader :updated_at

    # The current status of the task, represented as a ProbyTaskStatus
    attr_reader :status

    # <b>Should not be called directly</b>
    def initialize(attributes={})
      @name = attributes['name']
      @api_id = attributes['api_id']
      @crontab = attributes['crontab']
      @paused = attributes['paused']
      @time_zone = attributes['time_zone']
      @machine = attributes['machine']
      @finish_alarms_enabled = attributes['finish_alarms_enabled']
      @maximum_run_time = attributes['maximum_run_time']
      @start_notification_grace_period = attributes['start_notification_grace_period']
      @consecutive_alarmed_tasks = attributes['consecutive_alarmed_tasks']
      @consecutive_alarmed_tasks_required_to_trigger_alarm = attributes['consecutive_alarmed_tasks_required_to_trigger_alarm']
      @created_at = Chronic.parse attributes['created_at']
      @updated_at = Chronic.parse attributes['updated_at']
      @status = ProbyTaskStatus.new(attributes['status']) if attributes['status']
    end

    # Get a single, or all tasks from Proby.
    #
    # @param [Object] param :all if you are fetching all tasks, or the api_id of the Proby task you would like to fetch.
    #
    # @return If requesting all tasks, an [Array<ProbyTask>] will be returned.  If an api_id was provided, the
    #           ProbyTask with that api_id will be returned if it exists, or nil if it could not be found.
    #
    # @example
    #   all_of_my_tasks = ProbyTask.find(:all)
    #   my_task = ProbyTask.find('my_proby_task_api_id')
    def self.find(param)
      ensure_api_key_set
      param == :all ? list : fetch(param)
    end

    # Create a new Proby task.
    #
    # @param [Hash] attributes The attributes for your task.
    # @option attributes [String] :name A name for your task.
    # @option attributes [String] :crontab The schedule of the task, specified in cron format.
    # @option attributes [String] :time_zone <b>(Optional)</b> The time zone of the machine executing the task.
    # @option attributes [String] :machine <b>(Optional)</b> The name of the machine that is responsible for running this task.
    #                               Will default to the default time zone configured in Proby if not specified.
    # @option attributes [Boolean] :finish_alarms_enabled <b>(Optional)</b> true if you would like to receive finish alarms for
    #                                this task, false otherwise (default: true).
    # @option attributes [Fixnum] :maximum_run_time <b>(Optional)</b> The maximum amount of time the task is allowed to run before
    #                               Proby sends a finish alarm. If not specified, Proby will determine when an alarm should be
    #                               sent based on past run times.
    # @option attributes [Fixnum] :start_notification_grace_period <b>(Optional)</b> The number of minutes to wait for a task to
    #                               send its start notification after it should have started before sending an alarm.
    # @option attributes [Fixnum] :consecutive_alarmed_tasks_required_to_trigger_alarm <b>(Optional)</b> The number of consecutive
    #                               tasks that must fail before an alarm is sent.
    #
    # @return [ProbyTask] The task that was created.
    #
    # @example
    #   proby_task = ProbyTask.create(:name => "My new task", :crontab => "* * * * *")
    def self.create(attributes={})
      ensure_api_key_set
      raise InvalidParameterException.new("attributes are required") if attributes.nil? || attributes.empty?
      raise InvalidParameterException.new("name is required") unless !blank?(attributes[:name]) || !blank?(attributes['name'])
      raise InvalidParameterException.new("crontab is required") unless !blank?(attributes[:crontab]) || !blank?(attributes['crontab'])

      Proby.logger.info "Creating task with attributes: #{attributes.inspect}"
      response = post("/api/v1/tasks.json",
                      :format => :json,
                      :body => MultiJson.dump(:task => attributes),
                      :headers => default_headers)

      if response.code == 201 
        new(response.parsed_response['task'])
      else
        handle_api_failure(response)
      end 
    end

    # Saves the task in Proby, updating all attributes to the values stored in the object.  Only the attributes specified in
    # the ProbyTask.create documentation can be updated.
    #
    # @example
    #   proby_task = ProbyTask.get('my_proby_task_api_id')
    #   proby_task.name = "Some other name"
    #   proby_task.crontab = "1 2 3 4 5"
    #   proby_task.save
    def save
      self.class.ensure_api_key_set
      raise InvalidParameterException.new("name is required") if self.class.blank?(@name)
      raise InvalidParameterException.new("crontab is required") if self.class.blank?(@crontab)

      attributes = {
        :name => @name,
        :crontab => @crontab,
        :time_zone => @time_zone,
        :machine => @machine,
        :finish_alarms_enabled => @finish_alarms_enabled,
        :maximum_run_time => @maximum_run_time,
        :start_notification_grace_period => @start_notification_grace_period,
        :consecutive_alarmed_tasks_required_to_trigger_alarm => @consecutive_alarmed_tasks_required_to_trigger_alarm
      }

      Proby.logger.info "Updating task #{@api_id} with attributes: #{attributes.inspect}"
      response = self.class.put("/api/v1/tasks/#{@api_id}.json",
                                :format => :json,
                                :body => MultiJson.dump(:task => attributes),
                                :headers => self.class.default_headers)

      if response.code == 200
        true
      else
        self.class.handle_api_failure(response)
      end 
    end

    # Delete a Proby task.  The object will be frozen after the delete.
    #
    # @example
    #   proby_task = ProbyTask.get('my_proby_task_api_id')
    #   proby_task.delete
    def delete
      self.class.ensure_api_key_set

      Proby.logger.info "Deleting task #{@api_id}"
      response = self.class.delete("/api/v1/tasks/#{@api_id}.json",
                                   :format => :json,
                                   :headers => self.class.default_headers)

      if response.code == 200 
        self.freeze
        true
      else
        self.class.handle_api_failure(response)
      end 
    end

    # Pause a Proby task.
    #
    # @example
    #   proby_task = ProbyTask.get('my_proby_task_api_id')
    #   proby_task.pause
    def pause
      self.class.ensure_api_key_set

      Proby.logger.info "Pausing task #{@api_id}"
      response = self.class.post("/api/v1/tasks/#{@api_id}/pause.json",
                                 :format => :json,
                                 :headers => self.class.default_headers)

      if response.code == 200 
        @paused = true
        true
      else
        self.class.handle_api_failure(response)
      end 
    end

    # Unpause a Proby task.
    #
    # @example
    #   proby_task = ProbyTask.get('my_proby_task_api_id')
    #   proby_task.unpause
    def unpause
      self.class.ensure_api_key_set

      Proby.logger.info "Unpausing task #{@api_id}"
      response = self.class.post("/api/v1/tasks/#{@api_id}/unpause.json",
                                 :format => :json,
                                 :headers => self.class.default_headers)

      if response.code == 200 
        @paused = false
        true
      else
        self.class.handle_api_failure(response)
      end 
    end

    private

    def self.list
      Proby.logger.info "Getting the list of tasks"
      response = get('/api/v1/tasks.json',
                     :format => :json,
                     :headers => default_headers)

      if response.code == 200
        data = response.parsed_response['tasks']
        data.map { |task_data| new(task_data) }
      else
        handle_api_failure(response)
      end
    end

    def self.fetch(api_id)
      raise InvalidParameterException.new("api_id is required") if api_id.nil? || api_id.strip.empty?

      Proby.logger.info "Fetching task from Proby: #{api_id}"
      response = get("/api/v1/tasks/#{api_id}.json",
                     :format => :json,
                     :headers => default_headers)

      if response.code == 200
        new(response.parsed_response['task'])
      elsif response.code == 404
        nil
      else
        handle_api_failure(response)
      end
    end

    def self.ensure_api_key_set
      if Proby.api_key.nil? || Proby.api_key.strip.empty?
        raise InvalidApiKeyException.new("Your Proby API key has not been set.  Set it using Proby.api_key = 'my_api_key'")
      end
    end

    def self.blank?(s)
      s.nil? || s.strip.empty?
    end

  end
end
