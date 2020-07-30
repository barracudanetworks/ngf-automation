import os
import logging
import re
import ConfigParser
import json
import commands


logger = logging.getLogger(__name__)

#replacement array function
def replace_words(base_text, device_values):
	for key, val in device_values.items():
		base_text = base_text.replace(key, val)
		logger.info("Replacing, Key:" + key + " with value:" + val)
	return base_text




def main():
    
	#its not really necessary to supply anything other than the servicename and
	#servername
	from optparse import OptionParser
	usage = """usage: %prog [options]

       
       use of -l and -c are optional as the script already contains the default locations used by the NGF
    """
	parser = OptionParser(usage=usage)
	loglevels = ['CRITICAL', 'FATAL', 'ERROR', 'WARNING', 'WARN', 'INFO', 'DEBUG', 'NOTSET']
	parser.add_option("-v", "--verbosity", default="info",
						help="available loglevels: %s [default: %%default]" % ','.join(l.lower() for l in loglevels))
	parser.add_option("-c", "--configpath", default='/opt/phion/config/active/', help="source path of log files to upload")
	parser.add_option("-l", "--logfilepath", default='/phion0/logs/multi_ip_replace.log', help="logfile path and name")
	parser.add_option("-s", "--servicename", default='NGFW', help="name of the NGFW service")
	parser.add_option("-i", "--servername", default='CSC', help="name of second ip address")
	
	# parse argsbox
	(options, args) = parser.parse_args()

	if options.verbosity.upper() in loglevels:
		options.verbosity = getattr(logging,options.verbosity.upper())
		logger.setLevel(options.verbosity)
	else:
		parser.error("invalid verbosity selected. please check --help")
	
	logging.basicConfig(filename=options.logfilepath,format="%(asctime)s %(levelname)-7s - %(message)s")

	servicename = options.servicename
	servername = options.servername

	logger.info("Checking if unit is active, looking  for service " + servername + '_' + servicename)
	#decides if the box is the active unit
	if(commands.getoutput('ps -C ' + servername + '_' + servicename).find(servername) != -1):
		logger.info("This CGF has been detected as active" + str(commands.getoutput('ps -C ' + servername + '_' + servicename)))
		#Build Config Path
		confpath = options.configpath
		#Get's a list of box IP's, will create files to match the names in the config.
		with open('/tmp/ipalloc_output') as json_file:
			data = json.load(json_file)
			#for each ipconfig read, creates a file containing the local IP. 
			for ip in data['Addresses']:
				logger.info('Updating Alloc: ' + "ip['AllocationId']" + 'for instance' + ip['InstanceId'])

				filepath = '' + confpath + 'external.' + ip['AllocationId']  + '.conf'
				logger.info('Updating ' + filepath + ' with value: '+ ip['PrivateIpAddress'] )
				try:
					with open(filepath, 'w+') as f:
						f.write('IP=' + ip['PrivateIpAddress'])
				
				except IOError:
					logger.warning("Unable to create file")

	else:
		logger.warning("This CGF is not running as the active unit. Not executing script")


if __name__ == "__main__":
	exit(main())

