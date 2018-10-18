import os
import logging
import re
import ConfigParser
import json
import commands

logger = logging.getLogger(__name__)


#Parsing config files for the NGF network needs to only read the boxnet configuration
def read_boxnet(filename):
    import StringIO
    boxnet = StringIO.StringIO()

    boxnet.write("[boxnet]\n")
    try:
        with open(filename) as infile:
            copy = False
            for line in infile:
                if line.strip() == "[boxnet]":
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

def get_boxip(confpath, conffile):
    
    boxconf = ConfigParser.ConfigParser()
    boxconf.readfp(read_boxnet(confpath + conffile))
    foundip = boxconf.get('boxnet','IP')
    logger.info("Collecting the box IP from: " + conffile)

    return foundip

def call_webhook(url, subid, boxip, haip):
    
    try:
        import requests
    except ImportError:
        requests = None
        import urllib2
        import ssl

    #print url
   
    payload = '[{"SubscriptionId":"'+ str(subid) + '","id":"NGF","properties":{"OldNextHopIP":"'+ str(haip) + '","NewNextHopIP":"'+ str(boxip) + '"}}]'

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
         logging.warning("URL Call failed because: " + e.reason.message)
    # Response, status etc
         exit()

def main():
       
    from optparse import OptionParser
    usage = """usage: %prog [options]

       example: %prog -s storageaccounname -u http://uniquewebhookurl.com/path -s UKNGFW
       use of -l and -c are optional as the script already contains the default locations used by the NGF
    """
    parser = OptionParser(usage=usage)
    loglevels = ['CRITICAL', 'FATAL', 'ERROR', 'WARNING', 'WARN', 'INFO', 'DEBUG', 'NOTSET']
    parser.add_option("-v", "--verbosity", default="info",
                      help="available loglevels: %s [default: %%default]"%','.join(l.lower() for l in loglevels))
    parser.add_option("-u", "--webhookurl", default='', help="URL of automation webhook")
    parser.add_option("-c", "--configpath", default='/opt/phion/config/active/', help="source path of log files to upload")
    parser.add_option("-l", "--logfilepath", default='/phion0/logs/update_UDR.log', help="logfile path and name")
    parser.add_option("-s", "--servicename", default='S1_NGFW', help="name of the NGFW service")

    # parse argsbox
    (options, args) = parser.parse_args()

    if options.verbosity.upper() in loglevels:
        options.verbosity = getattr(logging,options.verbosity.upper())
        logger.setLevel(options.verbosity)
    else:
        parser.error("invalid verbosity selected. please check --help")
        
    logging.basicConfig(filename=options.logfilepath,format="%(asctime)s %(levelname)-7s - %(message)s")
          
    servicename = options.servicename
    #decides if the box is the active unit
    if(commands.getoutput('ps -C '+ servicename).find(servicename) != -1):
        logger.info("This NGF has been detected as active" + str(commands.getoutput('ps -C '+ servicename)))
        confpath = options.configpath
    #Get's the configuration files for HA  
    #The boxip is the IP taken from the local network config file. On failover this should be the IP of the active box.     

        boxip = get_boxip(confpath,'boxnet.conf')

        if len(boxip) < 5:
            logger.warning("Wasn't able to collect boxip from " + confpath)
            exit()
        

    #The boxip is the IP taken from the ha network config file. Clusters reverse this pair of files so this should be the other box.  
    
        haip = get_boxip(confpath,'boxnetha.conf')
    
        if len(haip) < 5:
            logger.warning("Wasn't able to collect HA boxip from " + confpath)
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

        webhook = call_webhook(options.webhookurl, str(subid)[2:-2], boxip, haip)
        logger.info("Calling the Webhook on :" + str(options.webhookurl))

        if (json.loads(webhook)['JobIds']):
            logger.info("Success JobID:" + (str(json.loads(webhook)['JobIds'])[2:-2]))
        else:
            logger.warning("failed to call the webhook error status:" + webhook )
    else:
        logger.warning("This NGF has is not running as the active unit. Not executing script")
            

if __name__=="__main__":
       exit(main())
