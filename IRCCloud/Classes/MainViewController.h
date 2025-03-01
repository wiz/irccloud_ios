//
//  MainViewController.h
//
//  Copyright (C) 2013 IRCCloud, Ltd.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "BuffersTableView.h"
#import "UsersTableView.h"
#import "EventsTableView.h"
#import "UIExpandingTextView.h"
#import "NickCompletionView.h"
#import "ImageUploader.h"

@interface MainViewController : UIViewController<NickCompletionViewDelegate,BuffersTableViewDelegate,UIExpandingTextViewDelegate,UIActionSheetDelegate,UIAlertViewDelegate,EventsTableViewDelegate,UsersTableViewDelegate,UITextFieldDelegate,UIImagePickerControllerDelegate,UINavigationBarDelegate,ImageUploaderDelegate,UIPopoverControllerDelegate> {
    IBOutlet BuffersTableView *_buffersView;
    IBOutlet UsersTableView *_usersView;
    IBOutlet EventsTableView *_eventsView;
    UIExpandingTextView *_message;
    IBOutlet UIView *_connectingView;
    IBOutlet UIProgressView *_connectingProgress;
    IBOutlet UILabel *_connectingStatus;
    IBOutlet UIActivityIndicatorView *_connectingActivity;
    IBOutlet UIImageView *_bottomBar;
    IBOutlet UILabel *_serverStatus;
    IBOutlet UIView *_serverStatusBar;
    IBOutlet UIActivityIndicatorView *_eventActivity;
    IBOutlet UIView *_titleView;
    IBOutlet UILabel *_titleLabel;
    IBOutlet UILabel *_topicLabel;
    IBOutlet UIImageView *_lock;
    IBOutlet UIView *_borders;
    IBOutlet UIView *_swipeTip;
    IBOutlet UIView *_mentionTip;
    IBOutlet UIView *_globalMsgContainer;
    IBOutlet TTTAttributedLabel *_globalMsg;
    UIButton *_menuBtn, *_sendBtn, *_settingsBtn, *_cameraBtn;
    UIBarButtonItem *_usersButtonItem;
    Buffer *_buffer;
    User *_selectedUser;
    Event *_selectedEvent;
    CGRect _selectedRect;
    Buffer *_selectedBuffer;
    NSString *_selectedURL;
    int _cidToOpen;
    NSString *_bufferToOpen;
    NSURL *_urlToOpen;
    NSTimer *_doubleTapTimer;
    NSMutableArray *_pendingEvents;
    int _bidToOpen;
    NSTimeInterval _eidToOpen;
    UIAlertView *_alertView;
    IRCCloudJSONObject *_alertObject;
    SystemSoundID alertSound;
    UIView *_landscapeView;
    CGSize _kbSize;
    NickCompletionView *_nickCompletionView;
    NSTimer *_nickCompletionTimer;
    NSArray *_sortedUsers;
    NSArray *_sortedChannels;
    UIPopoverController *_popover;
    UIVisualEffectView *_blur;
    NSTimeInterval _lastNotificationTime;
}
@property (nonatomic) int bidToOpen;
@property (nonatomic) NSTimeInterval eidToOpen;
-(void)bufferSelected:(int)bid;
-(void)sendButtonPressed:(id)sender;
-(void)usersButtonPressed:(id)sender;
-(void)listButtonPressed:(id)sender;
-(IBAction)serverStatusBarPressed:(id)sender;
-(IBAction)titleAreaPressed:(id)sender;
-(IBAction)globalMsgPressed:(id)sender;
-(void)launchURL:(NSURL *)url;
-(void)refresh;
@end
