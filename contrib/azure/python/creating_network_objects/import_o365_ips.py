#!/usr/bin/env python2.7
#  -*- coding: utf-8 -*-
import os
import xml.etree.ElementTree as ET
import re
import json
import subprocess
import logging
logger = logging.getLogger(__name__)

try:
    import requests
except ImportError:
    requests = None
    import urllib2
    import ssl

class AzureIPFetcher(object):
    '''
    Download an process current azure IPs: $url = "https://endpoints.office.com/endpoints/worldwide?ClientRequestId=b10c5ed1-bad1-445f-b386-b919946339a7"
    '''
    REX_IPRANGE_QUICK = re.compile(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{2}')
    USER_AGENT = "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
    
    def __init__(self, url="https://endpoints.office.com/endpoints/worldwide?ClientRequestId=b10c5ed1-bad1-445f-b386-b919946339a7", ssl_verify=False):
        self.baseurl = url
        self.ssl_verify = ssl_verify
        self.products = {}
        
    def is_iprange(self, iprange):
        # just make sure we're not adding any non-iprange items to that object
        return self.REX_IPRANGE_QUICK.match(iprange)
    
    def request_url(self, url):
        logger.debug("request: %s"%url)
        if requests:
            return requests.get(url, verify=self.ssl_verify).content
        
        request = urllib2.Request(url, headers={'User-Agent':self.USER_AGENT})
        
        if not self.ssl_verify:
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            return urllib2.urlopen(request, context=ctx).read()
        return urllib2.urlopen(request).read()
      
    
        
    def download(self):
        # find correct download link
            parsed_json = json.loads(self.request_url(self.baseurl))
           
            for entry in parsed_json:
                try:
                    if entry['ips']:
                        product_name = entry['serviceArea']
                        self.products.setdefault(product_name, set([]))
                        logger.debug("processing: %s"%entry['serviceArea'])
                        for iprange in entry['ips']:
                            print iprange
                            if not self.is_iprange(iprange):
                                logger.warning("%r is not an iprange of the form xxx.xxx.xxx.xxx\yy"%iprange)
                                print ("%r is not an iprange of the form xxx.xxx.xxx.xxx\yy"%iprange)
                                continue
                            print("%r Found range xxx.xxx.xxx.xxx\yy"%iprange) 
                            logger.debug("%r Found range xxx.xxx.xxx.xxx\yy"%iprange)
                            self.products[product_name].add(iprange)
                except KeyError:
                    print "NO IPS"
                    logger.debug("No IP Ranges available for %s"%product_name)
                try:
                    if entry['urls']:
                        print "URLS"
                        #print entry['serviceArea']
                        #print entry['id']
                except KeyError:
                    print "No URLS"
            
      
    def export(self, to=""):
        print self.products
        ipranges = (item for sublist in self.products.values() for item in sublist)
        with open(to, 'w') as f:
            f.write(' '.join(ipranges))
            logger.info("all products exported to %r"%(to))
        return [to]
 
def main():
    logging.basicConfig(format="%(asctime)s %(levelname)-7s - %(message)s")
    
    from optparse import OptionParser
    usage = """usage: %prog [options]

       example: %prog --export-all=/tmp --prefix=azureIPs 
    """
    parser = OptionParser(usage=usage)
    loglevels = ['CRITICAL', 'FATAL', 'ERROR', 'WARNING', 'WARN', 'INFO', 'DEBUG', 'NOTSET']
    parser.add_option("-v", "--verbosity", default="info",
                      help="available loglevels: %s [default: %%default]"%','.join(l.lower() for l in loglevels))
    parser.add_option("-e", "--export-all", default="o365.ips", help="export all regions into one file")
    parser.add_option("-p", "--prefix", default="o365.ips.", help="prefix for --export-regions [%default]")
    parser.add_option("-s", "--source", default="https://endpoints.office.com/endpoints/worldwide?ClientRequestId=b10c5ed1-bad1-445f-b386-b919946339a7", help="source url [%default]")
    parser.add_option("-i", "--insecure", default=None, action="store_true", help="disable certificate verification [%default]")

    # parse args
    (options, args) = parser.parse_args()

    if options.verbosity.upper() in loglevels:
        options.verbosity = getattr(logging,options.verbosity.upper())
        logger.setLevel(options.verbosity)
    else:
        parser.error("invalid verbosity selected. please check --help")

    aip = AzureIPFetcher(url=options.source, ssl_verify=not options.insecure)
    aip.download()
    if options.export_all:
        aip.export(to=options.export_all)
    
if __name__=="__main__":
    exit(main())
