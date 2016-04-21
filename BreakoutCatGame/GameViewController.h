//
//  GameViewController.h
//  BreakoutCatGame
//
//  Created by Benjamin Soung on 12/15/15.
//  Copyright © 2015 Benjamin Soung. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GameViewController : UIViewController<UICollisionBehaviorDelegate>
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) CADisplayLink *displayLink;
@property (strong, nonatomic) UIPushBehavior *pusher;
@property (strong, nonatomic) UIDynamicAnimator *animator;

@property (weak, nonatomic) IBOutlet UIView *endGameAlert;
@property (weak, nonatomic) IBOutlet UIView *winGameAlert;

- (IBAction)returnHome:(id)sender;
- (IBAction)returnHomeWin:(id)sender;

@end
