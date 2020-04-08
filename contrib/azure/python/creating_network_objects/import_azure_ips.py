#!/usr/bin/env python2.7
#  -*- coding: utf-8 -*-
import os
import sys
import json
import re
import subprocess
import logging
import time

logger = logging.getLogger(__name__)

try:
    import requests
except ImportError:
    requests = None
    import urllib2
    import ssl

class AzureIPFetcher(object):
    '''
    Download an process current azure IPs: https://www.microsoft.com/EN-US/DOWNLOAD/DETAILS.ASPX?ID=41653
    '''
    REX_IPRANGE_QUICK = re.compile(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{2}')
    USER_AGENT = "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
    
    def __init__(self, url="https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519", ssl_verify=False, api="localhost:8080"):
        self.baseurl = url
        self.ssl_verify = ssl_verify
        self.netobjects = {}
        self.endpoint = "http://"+api+"/rest/firewall/v1/servers/"
        
    def is_iprange(self, iprange):
        # just make sure we're not adding any non-iprange items to that object
        return self.REX_IPRANGE_QUICK.match(iprange)
    
    def request_url(self, url, token=None):
        logger.debug("request: %s"%url)

        if(token):
            if requests:
                 return requests.get(url, verify=self.ssl_verify, headers={'X-API-Token': token}).content

            request = urllib2.Request(url, headers={'X-API-Token': token,'User-Agent':self.USER_AGENT})
        else:
            if requests:
                    return requests.get(url, verify=self.ssl_verify).content

            request = urllib2.Request(url, headers={'User-Agent':self.USER_AGENT})
        
        if not self.ssl_verify:
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            return urllib2.urlopen(request, context=ctx).read()

        try:
            results = urllib2.urlopen(request).read()
        except urllib2.HTTPError as e:
            logger.warn('GET HTTPError: {}'.format(e.code))
            return ('HTTPError: {}'.format(e.code))
        else:
            return results

    def post_url(self, url, data, token, method):
        logger.debug("post: %s"%url)
        if requests:
            return requests.post(url=url, data=data, headers={'X-API-Token': token, 'Content-Type': 'application/json'}).content
        
        if(method=="PUT"):
            request = urllib2.Request(url, headers={'X-API-Token': token, 'Content-Type': 'application/json'}, data=data)
            request.get_method = lambda: 'PUT'
        else:
            request = urllib2.Request(url, headers={'X-API-Token': token, 'Content-Type': 'application/json'}, data=data)

        try:
            results = urllib2.urlopen(request).read()
        except urllib2.HTTPError as e:
            logger.warn(' POST or PUT HTTPError: {}'.format(e.code))
            return ('HTTPError: {}'.format(e.code))
        else:
            return results

    def download(self):
        # find correct download link
            get_links = re.findall('href="(.*json)"',self.request_url(self.baseurl))
            logger.debug("Found link: %s"%get_links[0])
            parsed_json = json.loads(self.request_url(get_links[0]))
           
            for entry in parsed_json['values']:
                try:
                    if entry['properties']['addressPrefixes']:
                        netobj_name = entry['name']
                        netobj_region = entry['properties']['region']
                        self.netobjects.setdefault(netobj_name, set([]))
                        logger.debug("processing: %s"%netobj_name)
                        for iprange in entry['properties']['addressPrefixes']:
                            #print iprange
                            if not self.is_iprange(iprange):
                                logger.warning("%r is not an iprange of the form xxx.xxx.xxx.xxx\yy"%iprange)
                                #print ("%r is not an iprange of the form xxx.xxx.xxx.xxx\yy"%iprange)
                                continue
                         #   print("%r Found range xxx.xxx.xxx.xxx\yy"%iprange) 
                            logger.debug("%r Found range xxx.xxx.xxx.xxx\yy"%iprange)
                            self.netobjects[netobj_name].add(iprange)
                except KeyError:
                    #print "No address prefixes found"
                    logger.debug("No IP Ranges available for %s"%netobj_name)
                 
    def export_api(self, token, server, service):
        logger.debug("Entering API update process")
        endpoint = self.endpoint+server+"/services/"+service+"/objects/networks/"
        jsonrefdict = { "name": "AllAzureIPs", "comment": "added by azure script", "type":"generic", "overrrideSharedObject":'false', "excluded":[], "included": []}
        for region, ranges in self.netobjects.iteritems():
            jsondict = { "name": region, "comment": "added by azure script", "type":"generic", "overrrideSharedObject":'false', "excluded":[], "included": []}
            jsonrefdict["included"].append({"reference":region,"type":"reference"})
            for range in ranges:
                jsondict["included"].append({"ipV4":range,"type":"ipV4"})
            postdata = json.dumps(jsondict)
            if(self.request_url(endpoint+region,token=token) == "HTTPError: 404"):
                post = self.post_url(url=endpoint, data=postdata, token=token, method="POST")
                logger.info("Creating record for" + region)
            else:
                post = self.post_url(url=endpoint+region, data=postdata, token=token, method="PUT")
                logger.info("Updating record for" + region)
            time.sleep(10)
         
        #creats a full Azure reference object based upon 
        postdata = json.dumps(jsonrefdict)
        if(self.request_url(endpoint+"AllAzureIPs",token=token) == "HTTPError: 404"):
                post = self.post_url(url=endpoint, data=postdata, token=token, method="POST")
                logger.info("Creating record for all of Azure")
        else:
                post = self.post_url(url=endpoint+"AllAzureIPs", data=postdata, token=token, method="PUT")
                logger.info("Updating record for all of Azure")

        return post
                

def main():
    
    
    
    from optparse import OptionParser
    usage = """usage: %prog [options]

       example: %prog --token "fhdsjkfhdsjkfs"
    """
    parser = OptionParser(usage=usage)
    loglevels = ['CRITICAL', 'FATAL', 'ERROR', 'WARNING', 'WARN', 'INFO', 'DEBUG', 'NOTSET']
    parser.add_option("-v", "--verbosity", default="info",
                      help="available loglevels: %s [default: %%default]"%','.join(l.lower() for l in loglevels))
    parser.add_option("-s", "--source", default="https://www.microsoft.com/en-us/download/confirmation.aspx?id=56519", help="source url [%default]")
    parser.add_option("-l", "--logfilepath", default='/phion0/logs/box_Azure_azureip_updates.log', help="logfile path and name")
    parser.add_option("-i", "--insecure", default=None, action="store_true", help="disable certificate verification [%default]")
    parser.add_option("-t", "--token", default=None, help="provide api authorisation token")
    parser.add_option("-a", "--api", default="localhost:8080", help="API fqdn or IP if not localhost")
    parser.add_option("-x", "--virtualserver", default="S1", help="name of virtual server if not standard")
    parser.add_option("-f", "--firewallname", default="NGFW", help="name of firewall service if not standard")

    # parse args
    (options, args) = parser.parse_args()
   

    logging.basicConfig(filename=options.logfilepath,format='%(asctime)s %(levelname)-7s [ %(filename)-10s - #%(lineno)-3d ] : %(message)s')
   

    if options.verbosity.upper() in loglevels:
        options.verbosity = getattr(logging,options.verbosity.upper())
        logger.setLevel(options.verbosity)
    else:
        parser.error("invalid verbosity selected. please check --help")

    try:
        aip = AzureIPFetcher(url=options.source, ssl_verify=not options.insecure, api=options.api)
        aip.download()
    except:
        logger.warn("Unable to collect Azure IPs")
    
    try:
        aip.export_api(token=options.token, server=options.virtualserver, service=options.firewallname)
    except:
        logger.warn("Unable to update FW via API")


    logger.info("Completed Azure IP update")
if __name__=="__main__":
    exit(main())
