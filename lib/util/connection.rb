# Mixpanel Ruby Data Export Tool
#
# Copyright (c) 2015+ Appstronomy, LLC.
# See LICENSE.txt for details on use.

# This module contains supporting utilities for the classes in the Mixpanel module,
# including helper files to assist with loadpath setup and logging.
module Util

  require 'rubygems'
  require 'bundler/setup'
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'ostruct'
  require 'json'
  require 'logging'

  # The Connection class handles the underlying HTTP and HTTPS communication to whichever
  # endpoint and path is requested.
  #
  # Credit
  # Several ideas were derived from http://danknox.github.io/2013/01/27/using-rubys-native-nethttp-library/
  #
  # @author Sohail Ahmed, https://github.com/idStar
  class Connection

    # Constants

    DEFAULT_CA_CERT_PATH = '/usr/local/etc/openssl/certs/cacert.pem'

    VERB_MAP = {
        :get    => Net::HTTP::Get,
        :post   => Net::HTTP::Post,
        :put    => Net::HTTP::Put,
        :delete => Net::HTTP::Delete
    }

    # Instance Variables

    # The endpoint that we represent a connection to.
    # For example, 'https://data.mixpanel.com' or 'http://myserver.com'.
    # @return [String]
    attr_reader :endpoint

    # Our connection object. May actually be HTTPS if the endpoint
    # that we were initialized with used 'https://'.
    # @return [Net::HTTP]
    attr_reader :http

    # The full path (including the actual .pem file) that we use for the
    #   root Certificate Authority with which SSL connections are verified.
    # @return [String]
    attr_reader :ca_cert_path


    # Methods

    # Sets up our Connection with a pre-configured @http object that knows the endpoint
    # and protocol to use -- whether http or https.
    #
    # @param  [String] ca_cert_path Optional. The path to the 'cacert.pem' file.
    #         Not needed if the default is fine, or you are not sending in an SSL endpoint, or if
    #         you have provided a value in the SSL.config.json file to use instead.
    def initialize(endpoint, ca_cert_path = DEFAULT_CA_CERT_PATH)
      configure_logging
      @endpoint = endpoint
      uri = URI.parse(@endpoint) # This will correctly determine port based on protocol scheme
      @http = Net::HTTP.new(uri.host, uri.port)

      # Where we given a secure endpoint?
      if uri.scheme == 'https'
        @ca_cert_path = ca_cert_path
        load_ssl_config if ca_cert_path == DEFAULT_CA_CERT_PATH # If not specified by the caller, load the config file
        configure_with_ssl @ca_cert_path
        @logger.info "Using SSL for endpoint '#{@endpoint}' with CA certificates path: #{@ca_cert_path}."
      end

      @logger.info 'Initialized Connection instance.'
    end


    def get(path, params, return_json = false)
      route_request :get, path, params, return_json
    end


    def post(path, params, return_json = false)
      route_request :post, path, params, return_json
    end


    def put(path, params, return_json = false)
      route_request :put, path, params, return_json
    end


    def delete(path, params, return_json = false)
      route_request :delete, path, params, return_json
    end


    private

    # Sets up our logging instance attribute, with a logger for this class.
    # By default, this class specific logger inherits settings from the root logger.
    # @return [void]
    def configure_logging
      @logger = Logging.logger[self]
    end


    # We'll attempt to load an `SSL.config.json` file, and if we find it, parse it and
    # retrieve a file path for Certificate Authority certs, we'll set that as
    # {#ca_cert_path}.
    def load_ssl_config
      file_path = File.join(__dir__, '../../config/SSL.config.json')

      if File.exists? file_path
        file = File.read(file_path)
        config_info = JSON.parse(file)

        retrieved_path = config_info['certificate_authority']['cert_file_path']
        @ca_cert_path = retrieved_path if retrieved_path
      end
    end


    # Configures our @http object to use SSL with a verified peer, pointing the x509
    # certificate store directly at the provided Certificate Authority path.
    #
    # @param ca_cert_path The explicit full path to the 'cacert.pem' file that contains the root CA
    def configure_with_ssl(ca_cert_path)
      # Ensure the http object uses SSL and does so with a verified peer:
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      # Point the http object to the certificate store explicitly, so
      # we're not at the mercy of it not being found on the host system:
      @http.cert_store = OpenSSL::X509::Store.new
      @http.cert_store.set_default_paths
      @http.cert_store.add_file(ca_cert_path)
    end


    def route_request(method, path, params, return_json)
      request_method = return_json ? 'request_json' : 'request'
      send(request_method, method, path, params)
    end


    def request_json(method, path, params)
      response = request(method, path, params)
      body = JSON.parse(response.body)

      OpenStruct.new(:code => response.code, :body => body)
    rescue JSON::ParserError
      @logger.error "Could not parse response into JSON. Original request info: \
        {method = #{method}, path = #{path}, params = #{params}}"
      response
    end


    def request(method, path, params = {})
      case method
        when :get
          full_path = encode_path_params(path, params)
          @logger.debug "request full path is: #{full_path}"
          request = VERB_MAP[method.to_sym].new(full_path)
        else
          request = VERB_MAP[method.to_sym].new(path)
          request.set_form_data(params)
      end

      @http.request(request)
    end


    def encode_path_params(path, params)
      if params.length > 0
        # Encode parameters suitable for a web query string:
        encoded = URI.encode_www_form(params)
        # Separate the path from the encoded params with a query string operator:
        [path, encoded].join('?')
      else
        path
      end
    end



  end

end


# ---------- Development Testing ----------

# connection = Appstronomy::Connection.new('http://www.yahoo.ca')
# response = connection.get '.', {}
# puts response.body