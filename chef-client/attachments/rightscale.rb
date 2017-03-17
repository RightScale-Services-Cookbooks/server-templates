begin
  require 'rubygems'
  require 'ohai'
  require 'json'
  require 'mixlib/shellout'
rescue LoadError => e
  Ohai::Log.warn("Cannot load gem: #{e}.")
end

Ohai.plugin(:Rightscale) do
  provides 'rightscale'
  collect_data do
    rightscale Mash.new
    Ohai::Log.info(rightscale)
    rsc_hash = JSON.parse(Mixlib::ShellOut.new('/usr/local/bin/rsc --rl10 cm15 index_instance_session  /api/sessions/instance').run_command.stdout)
    file_hash = Hash.new
    # for backward compatability
    file_hash['instance_uuid'] = rsc_hash['monitoring_id']
    file_hash['instance_id'] = rsc_hash['resource_uid']
    %w(/var/run/rightlink/secret /var/lib/rightscale-identity).each do |file|
      File.read(file).each_line do |line|
        k, v = line.strip.split('=')
        file_hash[k] = v.tr("\'","")
      end
    end
    rightscale_hint = hint?('rightscale')
    rightscale_hint.each do |k,v|
      file_hash[k] = v
    end
    file_hash['api_url'] = "https://#{file_hash['api_hostname']}"
    rightscale.merge! rsc_hash
    rightscale.merge! file_hash
  end
end
