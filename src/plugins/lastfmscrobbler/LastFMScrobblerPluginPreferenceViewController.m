//
//  LastFMScrobblerPluginPreferenceViewController.m
//  dokibox
//
//  Created by Miles Wu on 15/09/2013.
//
//

#import "LastFMScrobblerPluginPreferenceViewController.h"
#import "LastFMScrobblerPluginAPICall.h"
#import "LastFMScrobblerPlugin.h"

@implementation LastFMScrobblerPluginPreferenceViewController

@synthesize statusString;
@synthesize loginButtonString;

- (id)initWithLastFMScrobblerPlugin:(LastFMScrobblerPlugin*)lastFMScrobblerPlugin;
{
    self = [super initWithNibName:@"LastFMScrobblerPluginPreferenceViewController" bundle:[NSBundle bundleForClass:[self class]]];
    
    if (self) {        
        _lastFMScrobblerPlugin = lastFMScrobblerPlugin;
        [_lastFMScrobblerPlugin addObserver:self forKeyPath:@"lastfmUserName" options:0 context:nil];
        [_lastFMScrobblerPlugin addObserver:self forKeyPath:@"lastfmUserKey" options:0 context:nil];
        [self updateAccountStatus];
    }
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"lastfmUserName"] || [keyPath isEqualToString:@"lastfmUserKey"]) {
        [self updateAccountStatus];
    }
}

-(void)updateAccountStatus
{
    if([_lastFMScrobblerPlugin lastfmUserKey] && [_lastFMScrobblerPlugin lastfmUserName]) {
        [self setStatusString:[NSString stringWithFormat:@"Logged in as %@", [_lastFMScrobblerPlugin lastfmUserName]]];
        [self setLoginButtonString:@"Logout"];
    }
    else {
        [self setStatusString:@"No last.fm account is associated."];
        [self setLoginButtonString:@"Login"];
    }
}

-(IBAction)loginButtonPressed:(id)sender
{
    if([[sender title] isEqualToString:@"Logout"]) { //logout
        [_lastFMScrobblerPlugin setLastfmUserName:nil];
        [_lastFMScrobblerPlugin setLastfmUserKey:nil];
        return;
    }
    
    
    // login
    LastFMScrobblerPluginAPICall *apiCall = [[LastFMScrobblerPluginAPICall alloc] init];
    [apiCall setParameter:@"method" value:@"auth.getToken"];
    NSXMLDocument *doc = [apiCall performGET];
    
    NSXMLNode *n = [doc rootElement];
    NSString *token = nil;
    while((n = [n nextNode])) {
        if([[n name] isEqualToString:@"token"]) {
            token = [n stringValue];
        }
    }
    
    if(token == nil) {
        NSLog(@"Error. No token found");
        return;
    }
    
    // Open user's browsers to do the authentication
    NSString *url = [NSString stringWithFormat:@"https://www.last.fm/api/auth/?api_key=%@&token=%@", [LastFMScrobblerPluginAPICall apiKey], token];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];

    
    NSString *name = nil, *key = nil;
    for(;;) { // Start doing the check
        apiCall = [[LastFMScrobblerPluginAPICall alloc] init];
        [apiCall setParameter:@"method" value:@"auth.getSession"];
        [apiCall setParameter:@"token" value:token];

        doc = [apiCall performGET];
        n = [doc rootElement];
        BOOL wait = NO;
        
        while((n = [n nextNode])) {
            if([[n name] isEqualToString:@"error"] && [n kind] == NSXMLElementKind) {
                NSXMLElement *element = (NSXMLElement *)n;
                NSXMLNode *attr = [element attributeForName:@"code"];
                if(attr && [[attr stringValue] isEqualToString:@"14"]) {
                    wait = YES;
                }
            }
            else if([[n name] isEqualToString:@"name"]) {
                name = [n stringValue];
            }
            else if([[n name] isEqualToString:@"key"]) {
                key = [n stringValue];
            }
        }
        
        if(wait == NO) {
            break;
        }
        else { // Token hasn't been authorized yet. Try again in a bit
            NSLog(@"wait");
            sleep(1);
        }
    }
    
    if(name == nil || key == nil) {
        NSLog(@"Error obtaining session key");
        return;
    }
    
    [_lastFMScrobblerPlugin setLastfmUserName:name];
    [_lastFMScrobblerPlugin setLastfmUserKey:key];
}

@end
