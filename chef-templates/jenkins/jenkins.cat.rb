name "Jenkins Master and Slaves"
rs_ca_ver 20161221
short_description "Jenkins Master and Slave cluster"

parameter "param_slave_count" do
  label "Jenkins Slave Count"
  type "string"
  operations [ "operation_set_slave_count", "launch" ]
end

resource "server_1", type: "server" do
  name "jenkins-master"
  cloud "EC2 us-east-1"
  instance_type "t2.large"
  ssh_key_href "/api/clouds/1/ssh_keys/13FIKG64LL5SG"
  subnet_hrefs "/api/clouds/1/subnets/C2II06OI99TMO"
  security_group_hrefs [ "/api/clouds/1/security_groups/ATG27T4SM9AOL" ]
  server_template find("stefhen-jenkins-master")
end

resource "server_array_1", type: "server_array" do
  name "jenkins-slaves"
  cloud "EC2 us-east-1"
  instance_type "t2.large"
  ssh_key_href "/api/clouds/1/ssh_keys/13FIKG64LL5SG"
  subnet_hrefs "/api/clouds/1/subnets/C2II06OI99TMO"
  security_group_hrefs [ "/api/clouds/1/security_groups/ATG27T4SM9AOL" ]
  server_template find("stefhen-jenkins-slave")
  state "enabled"
  array_type "alert"
  elasticity_params do {
    "bounds" => {
      "min_count"            => $param_slave_count,
      "max_count"            => 20
    },
    "pacing" => {
      "resize_calm_time"     => 5,
      "resize_down_by"       => 1,
      "resize_up_by"         => 1
    },
    "alert_specific_params" => {
      "decision_threshold"   => 51,
      "voters_tag_predicate" => "jenkins-slave"
    }
  } end
end

operation "launch" do
  description "Launch the application"
  definition "generated_launch"
  output_mappings do {
    $output_jenkins_master_ip => join(["http://", @server_1.public_ip_address, ":8080/"])
  } end
end

operation "stop" do
  description "Bring the array size to 0"
  definition "disable_and_shrink_array"
end

operation "start" do
  description "Enable array"
  definition "enable_array"
end

operation "operation_set_slave_count" do
  description "Sets the number of slaves to the provided parameter"
  definition "set_slave_count"
end

operation "operation_launch_slave" do
  description "Manually adds one Jenkins slave"
  definition "launch_slave"
end

output "output_jenkins_master_ip" do
  label "Jenkins"
  description "Jenkins Master IP Address"

end

define wait_for_array_to_reach_size(@array, $size) do
  sub task_name: "wait for array to reach size", timeout: 2h do
    sleep_until(size(@array.current_instances()) == $size)
  end
end

parameter "param_vol_size" do
  label "Jenkins Data Volume Size"
  type "string"
  operations "launch"
end

define generated_launch(@server_1, @server_array_1, $param_slave_count, $param_vol_size) return @server_1 do
  $inp = {
    "DESCRIPTION": "text:Jenkins Slaves",
    "MASTER_IP": "env:jenkins-master:PRIVATE_IP",
    "NAME": "text:jenkins-slaves",
    "STOR_BACKUP_LINEAGE": "text:jenkins_backup",
    "DEVICE_VOLUME_SIZE": "text:" + $param_vol_size
  }

  @@deployment.multi_update_inputs(inputs: $inp)

  concurrent do
    provision(@server_1)
    provision(@server_array_1)
  end
end

define disable_and_shrink_array(@server_array_1) return @server_array_1 do
  @server_array_1.update(server_array: { state: "disabled" })
  @server_array_1.multi_terminate()
  call wait_for_array_to_reach_size(@server_array_1, 0)
end

define enable_array(@server_array_1) return @server_array_1 do
  $desired_size = @server_array_1.elasticity_params["bounds"]["min_count"]
  @server_array_1.update(server_array: { state: "enabled" })
  call wait_for_array_to_reach_size(@server_array_1, $desired_size)
end

define set_slave_count(@server_array_1, $param_slave_count) do
  @server_array_1.update(server_array: { elasticity_params: { bounds: { min_count: $param_slave_count } } } )
end

define launch_slave(@server_array_1) do
  @server_array_1.launch()
end
