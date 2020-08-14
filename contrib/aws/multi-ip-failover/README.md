# AWS Multiple IP Failover

## Introduction
This script provides a simple extension of the failover process in AWS that switches the elastic IP address between firewalls. For ease of deployment their are two sub-directories primaryscript and secondaryscript, as each firewall has a unqiue group of private IP addresses the mappings to elastic IP's must be unique.


##  Pre-requisit

1. From the AWS EC2 portal, create the required elastic IP address and take a note of their allocation ID's
![AWS Elastic IP](images/eiplist.png). 
2. In the AWS EC2 portal, assign additional IP addresses to the interface of the Primary Firewall. 
![AWS Elastic IP](images/additionalIP.png)
3. In the AWS EC2 portal, assign additional IP addresses to the interface of the Secondary Firewall. 
4. Make a note of the private IP's of the primary and secondary firewall that you wish to map to the public IP.


<table>
<tr><td> Primary Private IP </td><td> Secondary Private IP </td><td>  EIP association ID </td></tr> 
<tr><td> 192.168.1.10 </td><td> 192.168.2.10 </td><td> eipalloc-08201f6beaafcc669 </td></tr> 
<tr><td> 192.168.1.11 </td><td> 192.168.2.11 </td><td> eipalloc-0eb612a7ea78b5771 </td></tr> 
<tr><td> 192.168.1.12 </td><td> 192.168.2.12 </td><td> eipalloc-0a8e01ac3ba79ab71 </td></tr> 
</table>



5.  prepare the FW rules by pre-creating the dynamic objects, to allow you to create the right type take the project file 'network_object_template.conf' and
copy it into a text editor. For each Elastic IP you wish to associate you must create an object by following the below steps. 
	a.  Search for the string "yourassociationid" in the conf file, replace this text with the association ID
    ![AWS Elastic IP](images/modifiedscriptexample.png).
    <b.  Once edited Select All into your clipboard
	c.  Go to Forwarding Firewall Rules, Network Objects and right click and Paste
    
You should now have new object entry named after the EIP allocation ID  It is critical all these names match exactly. The entry e.g 'sourceFile={external.eipalloc-08201f6beaafcc669.conf}' is the filename that the script will create on the filesystem of the CGF.


## Installation Steps

1. In a suitable editor modify the contents of /primaryscript/failover.sh to associate your elastic IP allocation ID's to each private IP assigned to the network interface of the primary firewall. 
2. Now repeat for the script in /secondaryscript/failover.sh, use the same IP allocation ID's but this time change the private IP's to those assigned to the secondary firewall. 
3. With the scripts modified for each filewall to install then, first enable SSH access.  
4. On each firewall using the following command create a customscripts directory <code>mkdir /customscripts </code>
5. Copy the multiip_object_rewrite.py into the new /customscripts directory
6. Adjust the permissions on the script <code># chmod 755 /customscripts/multiip_object_rewrite.py</code> 

7. On the primary firewall copy the the failover.sh located in the primaryscript directory into the /customscripts directory.
8. Verify and make sure the script is executable: <code># chmod 755 /customscripts/failover.sh</code>
9. On the secondary firewall copy the the failover.sh located in the secondaryscript directory into the /customscripts directory.
10. Verify and make sure the script is executable: <code># chmod 755 /customscripts/failover.sh</code>
11. To trigger the script on failover, go to Configuration Tree > Infrastructure Services > Control <li>
12. Lock the config and enable Configuration Mode - Advanced. 
13. Go into the new Custom Scripts menu item that has appeared and paste into the Start Script box. ![CGF Network configuration Network Architecture](images/customscripts.png) 
        * Replace the value CSC - with the name of your firewall if it is in Control Center
        *  Replace the value of NGFW  - replace with the name of the Firewall Service if you have changed it from default.
     ` ./customscripts/failover.sh -s="CSC" -f="NGFW" `

The scripts should be ready, now create the objects for them to update. 

14. Test your script by triggering a failover, if it's working correctly all the Elastic IP's you have allocate should move between firewalls. You can also see the change in the Firewall > Forwarding Rule view
    ![Example Firewall Rule](images/updated_rule.png)
    
    
</ol>

## Using the IP's for outbound connections. 

To use these for an outbound NAT, create a Connection Object and link it to a single IP, referencing the Network object created  ![Example Firewall Rule](images/connectionobject.png) 

![Example Firewall Rule](images/firewallrule.png)


##### DISCLAIMER: ALL OF THE SOURCE CODE ON THIS REPOSITORY IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL BARRACUDA BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOURCE CODE. #####
