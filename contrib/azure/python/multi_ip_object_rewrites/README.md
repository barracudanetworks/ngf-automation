This project is intended to provide an example of how you can utilise scripts on the Barracuda CloudGen Firewall F-Series to update dynamic objects and multiple ipconfigs in Azure.

In this project a python script on the 

Within this project you will find included 5 script files. 

1. multiip_object_rewrite.py - gathers the local CGF information and updates the dynamic object files
2. trigger_multiip_rewrite.sh - used to trigger the python on the CGF.
3. network_object_template.conf - sample configuration object for a dynamic IP generated from file. 

# Workflow.

- CGF Failover triggers running of trigger_multiip_rewrite.sh shell script
- Shell script calls multiip_object_rewrite.py 
- multiip_object_rewrite.py gathers information about the additional IP's on the box and updates files supporting dynamic objects

# Installation


1. Firstly prepare the CGF cluster with the necessary IP information. In Box > Network and Box HA > Network configure additional IP Aliases under the Management IP. Do this for each additional ipconfig you have in Azure. 
Ensure the names match on each Networks setting page. 

2. Next prepare the FW rules by pre-creating the dynamic objects, to allow you to create the right type take the project file 'network_object_template.conf' and
copy it into a text editor. For each ip Alias you created you will need to import an object per the below steps. 
	a) Search for the string "youripname" in the conf file, replace this text with the name you gave your network objects. 
	b) Once edited Select All into your clipboard
	c) Go to Forwarding Firewall Rules, Network Objects and right click and Paste

You should now have new object entries named after the additional IP's configured in the box network. It is critical all these names match exactly. 



3. Now we prepare the scripts for failover, temporarily open SSH and on each CGF via SSH run: 
	`
	mkdir /root/azurescript
	`

2. Copy the multiip_object_rewrite.py and trigger_multiip_rewrite.sh onto the CGF firewall into the azurescript folder. Do this for both CGF's!

3. Run the following commands to set the permissions
	`
	chmod 777 /root/azurescript/multiip_object_rewrite.py
	chmod 777 /root/azurescript/trigger_multiip_rewrite.sh
	`
	

4. If you are running your CGF with custom service and server names you can edit trigger_multiip_rewrite.sh to include their details e.g 
(further input options can be collected by running python2.7 multiip_object_rewrite.py --help)
			`	/root/azurescript/multiip_object_rewrite.py.sh -s youservicename -i yourservername `
	
5. On the CGF go into Configuration Tree, Virtual Services, S1, Properties and to the Startup Script add;
	`	/root/azurescript/trigger_multiip_rewrite.sh  `
	

6. Once complete you can test this by failing over, you can view the dynamic objects and their IP's in Firewall > Forwarding Firewall Rules > Networks > Dynamic 

7. Finally to use these for an outbound NAT, create a Connection Object referencing this new Single IP dynamic object and use that in the ruleset.


#Troubleshooting
This script will write logs into /phion0/logs/multi_ip_replace.log