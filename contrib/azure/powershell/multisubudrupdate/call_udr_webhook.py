import os
import logging
import re
import ConfigParser
import json
import commands
import time

logger = logging.getLogger(__name__)


#Parsing config files for the NGF network needs to only read the boxnet configuration
def read_boxnet(filename,confsec):
	import StringIO
	boxnet = StringIO.StringIO()

	boxnet.write("["+confsec+"]\n")
	try:
		with open(filename) as infile:
			copy = False
			for line in infile:
				if line.strip() == "["+confsec+"]":
					copy = True
				elif line.strip() == "":
					copy = False
				elif copy:
					boxnet.write(str(line))
	except IOError:
		logging.warning("Unable to open config file" + filename)
		exit()

	boxnet.seek(0, os.SEEK_SET)
	#print boxnet.getvalue()
	return boxnet

def get_boxip(confpath, conffile,section='boxnet'):
    
	boxconf = ConfigParser.ConfigParser()
	boxconf.readfp(read_boxnet(confpath + conffile,section))
	foundip = boxconf.get(section,'IP')
	logger.info("Collecting the box IP from: " + conffile + " from section: " + section + " and IP found is: " + foundip)

	return foundip


def call_webhook(url, subid, id, boxip, haip):
    
	try:
		import requests
	except ImportError:
		requests = None
		import urllib2
		import ssl

	#print url

	payload = '[{"SubscriptionId":"'+ str(subid) + '","id":"' + str(id) + '","properties":{"OldNextHopIP":"'+ str(haip) + '","NewNextHopIP":"'+ str(boxip) + '"}}]'
	logger.debug(payload)
	#print payload

    # POST with JSON 
	if requests:
			r = requests.post(url, data=json.dumps(payload))
	else:
		request = urllib2.Request(url, headers={'User-Agent':'NGFPython'})
		request.add_header('Content-Type', 'application/json')
	try:
		r = urllib2.urlopen(request, json.dumps(payload))
		results = r.read()
		return results

	except urllib2.URLError as e:
		logging.warning("URL Call failed because: " + e.message)
		
	return 'FAILED'

def main():
       
	from optparse import OptionParser
	usage = """usage: %prog [options]

       example: %prog -u http://uniquewebhookurl.com/path -s S1_UKNGFW
       use of -l and -c are optional as the script already contains the default locations used by the CGF
    """
	parser = OptionParser(usage=usage)
	loglevels = ['CRITICAL', 'FATAL', 'ERROR', 'WARNING', 'WARN', 'INFO', 'DEBUG', 'NOTSET']
	parser.add_option("-v", "--verbosity", default="info",
						help="available loglevels: %s [default: %%default]"%','.join(l.lower() for l in loglevels))
	parser.add_option("-u", "--webhookurl", default='', help="URL of automation webhook")
	parser.add_option("-c", "--configpath", default='/opt/phion/config/active/', help="source path of log files to upload")
	parser.add_option("-l", "--logfilepath", default='/phion0/logs/update_UDR.log', help="logfile path and name")
	parser.add_option("-s", "--servicename", default='S1_NGFW', help="name of the NGFW service with server prepended")
	parser.add_option("-i", "--secondip", default='', help="name of second NIC ip address")
	parser.add_option("-n", "--vnetname", default='NGF', help="name of virtual network used for ASM")

	# parse argsbox
	(options, args) = parser.parse_args()

	if options.verbosity.upper() in loglevels:
		options.verbosity = getattr(logging,options.verbosity.upper())
		logger.setLevel(options.verbosity)
	else:
		parser.error("invalid verbosity selected. please check --help")

	logging.basicConfig(filename=options.logfilepath,format="%(asctime)s %(levelname)-7s - %(message)s")
	servicename = options.servicename
	#collects the VNET ID if provided
	vnetname = str(options.vnetname)[1:-1]
	logger.info("VNETName" + str(vnetname))

	loopnum = 1
	#Creates a loop so that if this fails it will repeat the attempt, will stop after 10 attempts
	condition = True
	while condition:

		
		#increases the wait period between loops so 2nd loop runs 30 seconds after the first, 2nd loop is 60 seconds, 3rd is 90 seconds, so last loop is 4 and a half minutes delay over the previous.
		sleeptime = 30 * loopnum
		#pauses between loops , this is at the front to allow some margin on trigger for temporary Azure network losses which are sometimes seen.
		logger.info("Sleeping for " + str(sleeptime))
		time.sleep(sleeptime)

		logger.info("UDR Webhook script triggered, iteration number:" + str(loopnum))
		
		#decides if the box is the active unit
		if(commands.getoutput('phionctrl server show').find('active=1') != -1):
			logger.info("This NGF has been detected as active" + str(commands.getoutput('phionctrl server show')))
			confpath = options.configpath
		#Get's the configuration files for HA  
		#The boxip is the IP taken from the local network config file. On failover this should be the IP of the active box.     

			boxip = get_boxip(confpath,'boxnet.conf')

			if len(boxip) < 5:
				logger.warning("Wasn't able to collect boxip from " + confpath)
				exit()



		#New section to address dual NIC boxes where second IP is needed
			if len(options.secondip) > 1:
				secondboxip = get_boxip(confpath,'boxnet.conf','addnet_'+options.secondip)

			if len(boxip) < 5:
				logger.warning("Wasn't able to collect second boxip from " + confpath )
				exit()

		#The boxip is the IP taken from the ha network config file. Clusters reverse this pair of files so this should be the other box.  

			haip = get_boxip(confpath,'boxnetha.conf')

			if len(haip) < 5:
				logger.warning("Wasn't able to collect HA boxip from " + confpath)
				exit()

			#New section to address dual NIC boxes where second IP is needed
			if len(options.secondip) > 1:
				secondhaip = get_boxip(confpath,'boxnetha.conf','addnet_'+options.secondip)

				if len(boxip) < 5:
					logger.warning("Wasn't able to collect HA second boxip from " + confpath)
					exit()

			cloudconf = ConfigParser.ConfigParser()

			#opens the config file for cloud integration and creates a dummy section
			with open(confpath + 'cloudintegration.conf', 'r') as f:
				config_string = '[dummy_section]\n' + f.read()

			#creates a temp file for conf parser to read that contains the dummy section header.
			with open('/tmp/cloud.conf', 'a') as the_file:
				the_file.write(config_string)

			#ConfigParser reads in from the temp file with the dummy section at the top
			try:
				cloudconf.read('/tmp/cloud.conf')
			except ConfigParser.ParsingError: 
				pass

			#Check that we have the sections before we find the subscription
			if cloudconf.sections() > 0:
				subid = cloudconf.get('azure','SUBSCRIPTIONID')

			#Check that the subscription makes sense.
			if len(str(subid)) < 20:    
				logger.warning("Wasn't able to collect a valid subscription id from " + confpath)   
				exit()
			else:
				logger.info("Collected the Azure subscription ID")

			#cleans up the temp conf file.
			os.remove('/tmp/cloud.conf')

			logger.info("Calling the Webhook on :" + str(options.webhookurl))
			webhook = call_webhook(options.webhookurl, str(subid)[2:-2], vnetname, boxip, haip)
		
			logger.info(webhook)

			if (webhook != 'FAILED'):
				condition = False

				if (json.loads(webhook)['JobIds']):
					logger.info("Success JobID:" + (str(json.loads(webhook)['JobIds'])[2:-2]))
				else:
					logger.warning("failure to get status from webhook:" + webhook )

				if len(options.secondip) > 1:
					logger.info("Second IP address provided and found")
					webhook = call_webhook(options.webhookurl, "secondnic", secondboxip, secondhaip)
					logger.info("Calling the Webhook on :" + str(options.webhookurl))

					if (json.loads(webhook)['JobIds']):
						logger.info("Success JobID:" + (str(json.loads(webhook)['JobIds'])[2:-2]))
					else:
						logger.warning("failure to get status from webhook:" + webhook )
			
			
			#If this is the 10th loop or if the webhook is successful then stops the loop condition being true
			if (loopnum == 10):
				condition = False

			loopnum+=1

		else:
			logger.warning("This NGF has is not running as the active unit. Not executing script")
			condition=False
	#end of loop

if __name__=="__main__":
	exit(main())
