//
//  ShareViewController.m
//  ShareExtension
//
//  Created by Sam Steele on 7/22/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "ShareViewController.h"
#import "BuffersTableView.h"

@interface ShareViewController ()

@end

@implementation ShareViewController

- (void)presentationAnimationDidFinish {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogComplete:)
                                                 name:kIRCCloudBacklogCompletedNotification object:nil];
    if(_conn.state != kIRCCloudStateConnected) {
        [_conn connect];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
    IRCCLOUD_HOST = [d objectForKey:@"host"];
    IRCCLOUD_PATH = [d objectForKey:@"path"];
    _conn = [NetworkConnection sharedInstance];
    _uploader = [[ImageUploader alloc] init];
    _uploader.delegate = self;
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
}

- (void)backlogComplete:(NSNotification *)n {
    if(!_buffer)
        _buffer = [[BuffersDataSource sharedInstance] getBuffer:[[_conn.userInfo objectForKey:@"last_selected_bid"] intValue]];
    [self reloadConfigurationItems];
    [self validateContent];
}

- (BOOL)isContentValid {
    return _buffer != nil;
}

- (void)didSelectPost {
    NSExtensionItem *input = self.extensionContext.inputItems.firstObject;
    NSExtensionItem *output = [input copy];
    output.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];

    if(output.attachments.count) {
        NSItemProvider *i = output.attachments.firstObject;
        if([i hasItemConformingToTypeIdentifier:@"public.url"]) {
            [i loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(NSURL *item, NSError *error) {
                if(self.contentText.length)
                    [_conn say:[NSString stringWithFormat:@"%@ [%@]",self.contentText,item.absoluteString] to:_buffer.name cid:_buffer.cid];
                else
                    [_conn say:item.absoluteString to:_buffer.name cid:_buffer.cid];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.extensionContext completeRequestReturningItems:@[output] completionHandler:nil];
                }];
           }];
        } else if([i hasItemConformingToTypeIdentifier:@"public.image"]) {
            [i loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:^(UIImage *item, NSError *error) {
                NSLog(@"Uploading image");
                _uploader.bid = _buffer.bid;
                _uploader.msg = self.contentText;
                [_uploader upload:item];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.extensionContext completeRequestReturningItems:@[output] completionHandler:nil];
                }];
            }];
        }
    } else {
        [_conn say:self.contentText to:_buffer.name cid:_buffer.cid];
        [self.extensionContext completeRequestReturningItems:@[output] completionHandler:nil];
    }
}

- (NSArray *)configurationItems {
    SLComposeSheetConfigurationItem *bufferConfigItem = [[SLComposeSheetConfigurationItem alloc] init];
    bufferConfigItem.title = @"Conversation";
    if(_buffer)
        bufferConfigItem.value = _buffer.name;
    else
        bufferConfigItem.valuePending = YES;
    
    bufferConfigItem.tapHandler = ^() {
        BuffersTableView *b = [[BuffersTableView alloc] initWithStyle:UITableViewStylePlain];
        b.navigationItem.title = @"Conversations";
        b.delegate = self;
        [self pushConfigurationViewController:b];
    };
    return @[bufferConfigItem];
}

-(void)bufferSelected:(int)bid {
    _buffer = [[BuffersDataSource sharedInstance] getBuffer:bid];
    [self reloadConfigurationItems];
    [self validateContent];
    [self popConfigurationViewController];
}

-(void)bufferLongPressed:(int)bid rect:(CGRect)rect {
    
}

-(void)dismissKeyboard {
    
}

-(void)imageUploadProgress:(float)progress {
    NSLog(@"Progress: %f", progress);
}

-(void)imageUploadDidFail {
    NSLog(@"Image upload failed");
}

-(void)imageUploadNotAuthorized {
    NSLog(@"Image upload not authorized");
}

-(void)imageUploadDidFinish:(NSDictionary *)d bid:(int)bid {
    if([[d objectForKey:@"success"] intValue] == 1) {
        NSLog(@"Image upload successful");
        NSString *link = [[[d objectForKey:@"data"] objectForKey:@"link"] stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
        if(self.contentText.length)
            [_conn say:[NSString stringWithFormat:@"%@ %@", self.contentText, link] to:_buffer.name cid:_buffer.cid];
        else
            [_conn say:link to:_buffer.name cid:_buffer.cid];
    } else {
        NSLog(@"Image upload failed");
    }
    [_conn disconnect];
}

@end
