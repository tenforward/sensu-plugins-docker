#! /usr/bin/env ruby
#
#   check-container
#
# DESCRIPTION:
#   This is a simple check script for Sensu to check that a Docker container is
#   running. You can pass in either a container id or a container name.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#
# USAGE:
#   check-container.rb -H /var/run/docker.sock -N c92d402a5d14
#   CheckDockerContainer OK: c92d402a5d14 is running on /var/run/docker.sock.
#
#   check-container.rb -H https://127.0.0.1:2376 -N circle_burglar
#   CheckDockerContainer CRITICAL: circle_burglar is not running on https://127.0.0.1:2376
#
# NOTES:
#     => State.running == true   -> OK
#     => State.running == false  -> CRITICAL
#     => Not Found               -> CRITICAL
#     => Can't connect to Docker -> WARNING
#     => Other exception         -> WARNING
#
# LICENSE:
#   Copyright 2014 Sonian, Inc. and contributors. <support@sensuapp.org>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'sensu-plugins-docker/client_helpers'

require 'pry'

#
# Check Docker Container
#
class CheckDockerContainerByQuery < Sensu::Plugin::Check::CLI
  option :docker_host,
         short: '-H DOCKER_HOST',
         long: '--docker-host DOCKER_HOST',
         description: 'Docker API URI. https://host, https://host:port, http://host, http://host:port, host:port, unix:///path'

  option :query,
         short: '-q CONTAINER',
         long: '--query-name CONTAINER',
         description: "Regex of container name to query",
         required: true

  option :allowexited,
         short: '-x',
         long: '--allow-exited',
         boolean: true,
         description: 'Do not raise alert if container has exited without error'

  def run
    @client = DockerApi.new(config[:docker_host])
    path = "/containers/json"
    response = @client.call(path, false)

    body = parse_json(response)
    container_names = body.map {|container| container["Names"]}.flatten
    regex_query = Regexp.new(config[:query])
    if container_names.grep(regex_query).any?
      ok "Found a container with query #{config[:query]} running on #{@client.uri}."
    else
      critical "Didn't find a container with query #{config[:query]} running on #{@client.uri}."
    end
  end
end
