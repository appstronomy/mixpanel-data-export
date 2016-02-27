# Mixpanel Ruby Data Export Tool
#
# Copyright (c) 2015+ Appstronomy, LLC.
# See LICENSE.txt for details on use.

module Mixpanel

  require 'rubygems'
  require 'bundler/setup'
  require 'active_support/all' # For mixin conveniences handling time and numbers
  require_relative '../util/connection'

  # Handles creating a secure connection to the Mixpanel API Service and
  # providing responses to predefined Mixpanel APIs.
  #
  # We make use of the Appstronomy::Connection class to handle the connectivity,
  # except that this class does handle the burden of loading and creating a
  # hex digest of Mixpanel API secret and token strings.
  #
  # @example
  #   service = Mixpanel::Service.new
  #   service.export(10,0, events: ["Treatment Drug Selected", "Treatment Plan Started"])
  #   service.event_names
  #   service.request('/events/names', type: 'general')
  #   service.request('/export', from_date: '2015-07-01', to_date: '2015-07-06', event: '["Treatment Plan Started", "Treatment Drug Selected"]')
  #   service.request('/events/properties/values', { event: 'Survey Completed', name: 'Practitioner Type', type: 'general', unit: 'day'})
  #
  #
  # @author Sohail Ahmed, https://github.com/idStar
  class Service

    # Maps symbols to URL path segments used to make requests on Mixpanel's API.
    API_COMMAND_PATH_MAP = {
        :event_names  => '/events/names',
        :export       => '/export'
    }

    # The number of seconds after which re-submitting the API request URI
    # should fail. We keep this low so that anyone who might intercept the URI
    # cannot actually use it to siphon off data themselves.
    #
    # You are strongly advised to keep this at `60` seconds or less. However,
    # you will likely need to increase this during any development/debugging.
    DEFAULT_REQUEST_EXPIRY_SECONDS        = 60

    # The number of seconds maximum, that scaled request expiry can grow to.
    DEFAULT_MAX_REQUEST_EXPIRY_SECONDS    = 180

    # The number of seconds to scale a request expiry, based on the date range.
    DEFAULT_SCALE_REQUEST_SECONDS_PER_DAY = 1

    # The minimum amount of time a request expiry can be set to. Applies when
    # scaling is in effect.
    MIN_REQUEST_EXPIRY_SECONDS            = 30


    BASE_API_PATH            = '/api/2.0'
    ENDPOINT_GENERAL_QUERIES = 'http://mixpanel.com'
    ENDPOINT_DATA_EXPORT     = 'https://data.mixpanel.com'



    # The convenience wrapper around using Net::HTTP that setup with
    # Mixpanel and SSL, and then keep around for subsequent invocations.
    # We'll set this up with the endpoint Mixpanel advises for data export.
    attr_reader :export_connection

    # The convenience wrapper around using Net::HTTP that setup with
    # Mixpanel and general API calls (not data export).
    # We keep this around for subsequent invocations.
    # We'll set this up with the endpoint Mixpanel advises for non-data export queries.
    attr_reader :general_connection

    # Will default to DEFAULT_REQUEST_EXPIRY_SECONDS. You can override this if you'd
    # like a shorter or longer expiry.
    attr_accessor :request_expiry_seconds


    # ---------- Initializing ----------

    # Initializes a new instance with a reusable Appstronomy::Connection
    # for each of the two Mixpanel endpoints.
    def initialize
      configure_logging
      load_configuration
      @general_connection     = Util::Connection.new(ENDPOINT_GENERAL_QUERIES)
      @export_connection      = Util::Connection.new(ENDPOINT_DATA_EXPORT)
      load_credentials
    end


    # ---------- API Operations ----------

    # Invokes an arbitrary Mixpanel API request based on the provided parameters.
    #
    # @param  [String] resource The component of the API path that is unique
    #         to this command; effectively, the web resource.
    #         e.g. '/events/names' or '/export'.
    #
    # @param  [Hash] options The query parameters we'll encode in the GET request.
    #         Generally, these let you limit or qualify the results in some manner.
    #         See the Mixpanel API reference for these options, available at:
    #         https://mixpanel.com/docs/api-documentation/data-export-api.
    #
    # @return [String] Response from Mixpanel, as a String.
    def request(resource, options = {})
      # Determine if we use the HTTPS export connection, or the general HTTP connection:
      if resource == API_COMMAND_PATH_MAP[:export] || resource == :export
        connection = @export_connection
        return_json = false
      else
        connection = @general_connection
        return_json = true
      end

      # Set a default expiry, unless the caller provided one:
      unless options[:expire]
        options[:expire] = request_expiry_timestamp
      end

      params_with_api_key = options.merge(api_key: @api_key)
      signature = digest_signature(params_with_api_key)
      params_with_signing = params_with_api_key.merge(sig: signature)

      @logger.info "Requesting resource '#{resource}' with options: #{options}"
      response = connection.get request_path(resource), params_with_signing, return_json

      # Whether we get a raw HTTP response back, or JSON inside an OpenStruct with a body key,
      # we'll want to retrieve the 'body' component of the returned response to get at the 'meat'
      # of the content.
      @logger.debug "Response: #{response.body}"
      response.body
    end


    # ---------- Conveniences ----------

    # Performs the Mixpanel data export operation. You specify a from-date
    # and to-date relative to today. The Mixpanel API uses whole days and not
    # timestamps, so we'll construct dates that look like '2015-07-09', void
    # of any concept of time.
    #
    # To get one day's worth of the latest data, you'd pass in:
    #  * from_days_ago = 1
    #  * to_days_ago = 0
    #
    # @example
    #   # Use the default of all events, for yesterday:
    #   service.export
    #
    #   # Explicitly ask for just yesterday (again, all events):
    #   service.export(1,0)
    #
    #   # Include the previous week, and just the two events specified in the events array:
    #   service.export(7,0, events: ["Survey Completed", "Navigation Action"])
    #
    #
    # @param  [String] from_days_ago The number of days back we should query for.
    # @param  [String] to_days_ago   The number of days back we should query for.
    #         Passing in zero here means today. This is useful for specifying
    #         that the end of your requested date range includes the latest
    #         data possible. Mixpanel does not return data for the present day.
    # @param  [Hash] options A hash of other query options for a data export.
    #         Notably, you can include a member `:events` that is itself an array of
    #         event names. If you do, we will properly flatten that and repackage
    #         into the query key-value pair that Mixpanel calls 'event'
    #         (even when multiple are present).
    #
    def export(from_days_ago = 1, to_days_ago = 0, options = {})
      # Record how many days a span this request is for:
      @num_days_in_request = from_days_ago - to_days_ago

      from_date_token = from_days_ago.day.ago.strftime('%Y-%m-%d')
      to_date_token = to_days_ago.day.ago.strftime('%Y-%m-%d')

      date_options = {
          from_date:  from_date_token,
          to_date:    to_date_token
      }

      options.merge! date_options

      if options[:events]
        # We need to build a string representation of a JSON array:
        events_as_json_string = options[:events].as_json.to_s

        # Note: The Mixpanel key is 'event', even though it is an array with
        # potentially multiple events present:
        options.merge!(event: events_as_json_string)

        # Now remove the 'events' array from the options, since we won't
        # be sending that to Mixpanel; just the flattened 'event' value
        # that we just created above:
        options.delete :events
      end

      request(:export, options)
    end


    # Queries Mixpanel for the list of all event names that it knows of.
    # Note that Mixpanel API will limit this request to 255 event names.
    # If you have fewer than this number events in your system, then you can
    # rest assured that you will indeed, get all of them.
    #
    # This method doesn't filter on dates; the only parameter we pass to
    # this resource request is 'general', in the hopes we get the full list
    # of event names ever used, regardless of popularity.
    def event_names
      request(:event_names, type: 'general')
    end


    private

    # Sets up our logging instance attribute, with a logger for this class.
    # By default, this class specific logger inherits settings from the root logger.
    # @return [void]
    def configure_logging
      @logger = Logging.logger[self]
    end


    # Retrieves the path to use for the operation specified. We simply pull
    # this path out of a map stored in this class. However, if we don't recognize
    # the option parameter, we'll treat it as a literal resource.
    #
    # @param  [:Symbol, String] operation Either the lookup key in our
    #         API_COMMAND_PATH_MAP of registered Mixpanel resources, or the unique resource
    #         path suffix itself, which we would combine with the BASE_API_PATH to arrive
    #         at a full resource path.
    #
    # @return The full path of a resource, minus the endpoint (protocol, host) itself.
    def request_path(operation)
      if API_COMMAND_PATH_MAP[operation]
        api_request_path = BASE_API_PATH + API_COMMAND_PATH_MAP[operation]
      else
        api_request_path = BASE_API_PATH + operation
      end

      api_request_path
    end


    def request_expiry_seconds
      if @scale_request_expiry
        num_seconds = @scale_request_seconds_per_day * (@num_days_in_request || 0)
        num_seconds = [num_seconds, MIN_REQUEST_EXPIRY_SECONDS].max
        num_seconds = [num_seconds, @max_scaled_request_expiry_seconds].min
      else
        num_seconds = @unscaled_request_expiry_seconds
      end

      @logger.info "Using request expiry of #{num_seconds.round} seconds."
      num_seconds.round
    end


    def request_expiry_timestamp
      Time.now.to_i + request_expiry_seconds
    end


    # Creates a digest signature using the API key and secret this class has already
    # retrieved.
    #
    # @param  [Hash] params The parameters to be sent to Mixpanel.
    #         We'll add the 'api_key' entry.
    # @return A digest signature that can be dropped in as the value for the query string
    #         key 'sig'.
    def digest_signature(params)
      signing_params = params.merge(api_key: @api_key)

      # We use a map function below instead of to_query on the Hash of params, since per Mixpanel,
      # we are not to include ampersands between key-value pairs. As well, we are to provide the
      # resource request arguments in alphabetical (sorted) order.
      Digest::MD5.hexdigest(
          params.map { |key, value| "#{key}=#{value}" }.sort.join + @api_secret
      )
    end


    def load_credentials
      file_path = File.join(__dir__, '../../config/MixpanelCredentials.config.json')

      unless File.exists? file_path
        @logger.fatal "Could not find file 'MixpanelCredentials.config.json' at path '#{file_path}'. \
              We need they API key and API secret for your installation from this file in order \
              to send requests to Mixpanel's API Service."
        exit!
      end

      file = File.read(file_path)
      credentials = JSON.parse(file)

      @api_key = credentials['API Key']
      @api_secret = credentials['API Secret']
    end


    # ---------- Configuration ----------

    # Sets various instance attributes related to events to include/exclude, as well
    # as request expiry timing, by consulting with the {ExporterConfig} class.
    #
    # @return [void]
    def load_configuration
      config = Util::ExporterConfig.new
      @scale_request_expiry = config.scale_request_expiry
      @scale_request_seconds_per_day = config.scale_request_seconds_per_day
      @unscaled_request_expiry_seconds = config.unscaled_request_expiry_seconds || DEFAULT_REQUEST_EXPIRY_SECONDS
      @max_scaled_request_expiry_seconds = config.max_scaled_request_expiry_seconds || DEFAULT_MAX_REQUEST_EXPIRY_SECONDS
    end

  end # class

end # module


# ---------- Development Testing ----------

#service = Mixpanel::Service.new
#service.export(10,0, events: ["Treatment Drug Selected", "Treatment Plan Started"])
#service.event_names
#service.request('/events/names', type: 'general')
#service.request('/export', from_date: '2015-07-01', to_date: '2015-07-06', event: '["Treatment Plan Started", "Treatment Drug Selected"]')
#service.request('/events/properties/values', { event: 'Survey Completed', name: 'Practitioner Type', type: 'general', unit: 'day'})