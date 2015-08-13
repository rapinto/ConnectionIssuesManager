//
//  ConnectionIssuesManager.m
//
//
//  Created by Raphaël Pinto on 07/08/2015.
//
// The MIT License (MIT)
// Copyright (c) 2015 Raphael Pinto.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.



#import "ConnectionIssuesManager.h"
#import "RPRequestOperation.h"



@implementation ConnectionIssuesManager



@synthesize delegate;



#pragma mark -
#pragma mark Singleton Methods



static ConnectionIssuesManager* sharedInstance = nil;



+ (ConnectionIssuesManager*)sharedInstance
{
    if (!sharedInstance)
    {
        sharedInstance = [[ConnectionIssuesManager alloc] init];
    }
    
    return sharedInstance;
}



#pragma mark -
#pragma mark Object Life Cycle Methods



- (id)init
{
    self = [self init];
    
    if (self)
    {
        [self addNotificationsObservers];
    }
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



#pragma mark -
#pragma mark Data Management Methods



- (void)addNotificationsObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetErrorTS)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(resetErrorTS)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
}


- (void)resetErrorTS
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kNoConnectionPopUpAlreadyDisplayed];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kMaintenancePopUpAlreadyDisplayed];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (BOOL)HasNoConnectionAlertViewBeenDisplayed
{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kNoConnectionPopUpAlreadyDisplayed] boolValue];
}


+ (void)setNoConnectionAlertViewDisplayed
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kNoConnectionPopUpAlreadyDisplayed];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (BOOL)needToNotifyForNoConnection
{
    if ([ConnectionIssuesManager HasNoConnectionAlertViewBeenDisplayed])
    {
        [ConnectionIssuesManager setNoConnectionAlertViewDisplayed];
        
        return YES;
    }
    
    return NO;
}


+ (BOOL)HasMaintenanceAlertViewBeenDisplayed
{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kMaintenancePopUpAlreadyDisplayed] boolValue];
}


+ (void)setMaintenanceAlertViewDisplayed
{
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:kMaintenancePopUpAlreadyDisplayed];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (BOOL)needToNotifyForMaintenance
{
    if ([ConnectionIssuesManager HasMaintenanceAlertViewBeenDisplayed])
    {
        [ConnectionIssuesManager setMaintenanceAlertViewDisplayed];
        
        return YES;
    }
    
    return NO;
}



#pragma mark -
#pragma mark Operation Manager Delegate Methods



- (void)operationManager:(RPOperationManager*)operationManager
     didSucceedOperation:(RPRequestOperation*)operation
      withResponseObject:(id)responseObject
{
    [self resetErrorTS];
}


- (void)operationManager:(RPOperationManager*)operationManager
        didFailOperation:(RPRequestOperation*)operation
               withError:(NSError*)error
{long statusCode = operation.response.statusCode;
    
    if (statusCode == 0)
    {
        statusCode = error.code;
    }
    
    switch (statusCode)
    {
            // Timeout fire by server
        case NSURLErrorTimedOut:
        case NSURLErrorNotConnectedToInternet:
        case NSURLErrorNetworkConnectionLost:
        case NSURLErrorCannotFindHost:
        {
            if ([ConnectionIssuesManager needToNotifyForNoConnection])
            {
                [delegate serveurConnectionLost];
            }
            
            break;
        }
        case 503:
        {
            if ([ConnectionIssuesManager needToNotifyForMaintenance])
            {
                [delegate serveurMaintenance];
            }
            
            break;
        }
        default:
        {
            break;
        }
    }
}


@end
