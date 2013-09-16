//
//  LastFMScrobblerPluginAPICall.m
//  dokibox
//
//  Created by Miles Wu on 16/09/2013.
//
//

#import "LastFMScrobblerPluginAPICall.h"
#import <CommonCrypto/CommonDigest.h>

#define API_KEY @"49b84b69fd527ce2cee337b28b266fe3"
#define API_SECRET @"07442538f74767dfb2526800c8525d3b"

@implementation LastFMScrobblerPluginAPICall

-(id)init
{
    self = [super init];
    if(self) {
        _parameters = [[NSMutableDictionary alloc] init];
        [self setParameter:@"api_key" value:API_KEY];
    }
    return self;
}

-(void)setParameter:(NSString*)name value:(NSString*)value
{
    [_parameters setValue:value forKey:name];
}

-(NSXMLDocument*)performRequest
{
    NSMutableString *urlString = [[NSMutableString alloc] initWithString:@"https://ws.audioscrobbler.com/2.0/?"];
    
    NSMutableString *signatureString = [[NSMutableString alloc] init];
    NSArray *sortedParameterNames = [[_parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for(NSString *name in sortedParameterNames) {
        [urlString appendString:name];
        [urlString appendString:@"="];
        [urlString appendString:[_parameters objectForKey:name]];
        [urlString appendString:@"&"];
        
        [signatureString appendString:name];
        [signatureString appendString:[_parameters objectForKey:name]];
    }
    [signatureString appendString:API_SECRET];
    
    [urlString appendString:@"api_sig="];

    const char *sigstring = [signatureString UTF8String];
    unsigned char digest[16];
    CC_MD5(sigstring, (CC_LONG)strlen(sigstring), digest);
    for(unsigned int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [urlString appendFormat:@"%02x", digest[i]];
   
    NSError *err;
    NSURL *u = [NSURL URLWithString:urlString];
    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithContentsOfURL:u options:0 error:&err];
    return doc;
}

@end
