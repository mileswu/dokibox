//
//  Album.m
//  fb2kmac
//
//  Created by Miles Wu on 10/02/2013.
//
//

#import "Album.h"
#import "Artist.h"
#import "Track.h"
#import "CoreDataManager.h"

@implementation Album
@dynamic name;
@dynamic artist;
@dynamic tracks;

-(void)setArtistByName:(NSString *)artistName
{
    NSError *error;
    Artist *artist;
    
    if([self artist]) { //prune old one
        [[self artist] pruneDueToAlbumBeingDeleted:self];
    }
    
    NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"artist"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE %@", artistName];
    [fr setPredicate:predicate];
    
    NSArray *results = [[self managedObjectContext] executeFetchRequest:fr error:&error];
    if(results == nil) {
        NSLog(@"error fetching results");
    }
    else if([results count] == 0) {
        artist = [NSEntityDescription insertNewObjectForEntityForName:@"artist" inManagedObjectContext:[self managedObjectContext]];
        [artist setName:artistName];
    }
    else { //already exists in library
        artist = [results objectAtIndex:0];
    }
    
    [self setArtist:artist];
}

-(void)pruneDueToTrackBeingDeleted:(Track *)track;
{
    if([[self tracks] count] == 1) {
        Track *lastTrack = [[[self tracks] allObjects] objectAtIndex:0];
        if([[lastTrack objectID] isEqual:[track objectID]]) {
            [[self managedObjectContext] deleteObject:self];
        }
    }
}

-(void)prepareForDeletion
{
    [[self artist] pruneDueToAlbumBeingDeleted:self];
}

@end