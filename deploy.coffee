control = require 'control'
task    = control.task

task 'myserver', 'config got my server', ->
  config = user: 'root'
  addresses = ['178.79.179.71']
  return control.hosts(config, addresses)
  
task 'deploy', 'deploy the latest version of the app', (host) ->
  host.ssh 'cd socketstream_dashboard_example/ && git pull origin master', ->
    host.ssh 'sudo sh /etc/init.d/dashboard restart'

control.begin()