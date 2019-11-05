import socket
import os
import time
import logging


logger = logging.getLogger(__name__)

def check_vpn(vpntofind):
    try:
        response = os.system("/opt/phion/bin/ktinactrl transport show | grep " + vpntofind)
    except:
        logger.warning("Failed to check for VPN status")
    # and then check the response...
    if response == 0:
        logger.info("VPN transport found for " + vpntofind)
    else:
         logger.warn("No VPN transport found for " + vpntofind)
    
    return response

def main():
    
    #its not really necessary to supply anything other than the servicename and
    #servername
    from optparse import OptionParser
    usage = """usage: %prog [options]

       use of -l is optional as the script already contains the default log location used 
    """
    parser = OptionParser(usage=usage)
    loglevels = ['CRITICAL', 'FATAL', 'ERROR', 'WARNING', 'WARN', 'INFO', 'DEBUG', 'NOTSET']
    parser.add_option("-v", "--verbosity", default="info",
                        help="available loglevels: %s [default: %%default]" % ','.join(l.lower() for l in loglevels))
    parser.add_option("-p", "--primaryip", default='165.225.80.37', help="IP of Primary Zscaler Site")
    parser.add_option("-l", "--logfilepath", default='/phion0/logs/zscaler_failover.log', help="logfile path and name")
    parser.add_option("-s", "--secondaryip", default='165.225.76.37', help="IP of Secondary Zscaler Site")
    parser.add_option("-r", "--rulename", default='LAN-2-INTERNET-PAR', help="name of the rule for secondary traffic to enable/disable")
    parser.add_option("-m", "--mgmtip", default='192.168.200.200', help="Firewall Mgmt IP")
    

    # parse argsbox
    (options, args) = parser.parse_args()

    if options.verbosity.upper() in loglevels:
        options.verbosity = getattr(logging,options.verbosity.upper())
        logger.setLevel(options.verbosity)
    else:
        parser.error("invalid verbosity selected. please check --help")
    
    logging.basicConfig(filename=options.logfilepath,format="%(asctime)s %(levelname)-7s - %(message)s")

    logger.info("variables - MGMT" + options.mgmtip + "rule:" + options.rulename + "pri:" + options.primaryip + "sec:" + options.secondaryip )


    enablecmd = "/opt/phion/bin/transcmd "+ options.mgmtip +" root -l dynrule enable "+ options.rulename + " 0 disable-term"
    disablecmd = "/opt/phion/bin/transcmd "+ options.mgmtip +" root -l dynrule disable  "+ options.rulename + " 0 disable-term"

    logger.debug("EnableCommand: " + enablecmd + "")
    logger.debug("DisableCommand: " + disablecmd + "")

    if check_vpn(options.primaryip) == 256 :
        try:
            os.system(enablecmd)
        except:
            logger.warning("Unabled to enable the rule permitting traffic for the Secondary Site")
        logger.info("Enabling Secondary Zscaler site with IP" + options.secondaryip)
        time.sleep(5)
    else:
        
        try:
            os.system(disablecmd)
        except:
            logger.warning("Unable to disable the rule for the Secondary Site")
        
        time.sleep(5)

    logger.info("Script completed")

if __name__ == "__main__":
    exit(main())