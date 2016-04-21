//
//  GameViewController.m
//  BreakoutCatGame
//
//  Created by Benjamin Soung on 12/15/15.
//  Copyright © 2015 Benjamin Soung. All rights reserved.
//

#import "GameViewController.h"

#define ACCELERATION 18
@interface GameViewController ()


@property (strong, nonatomic) UIImageView *ball;
@property (strong, nonatomic) UIImageView *paddle;
@property (strong, nonatomic) NSMutableArray<UIView*> *blocks;
@property (assign, nonatomic) CGPoint ballAcceleration;

@property (strong, nonatomic) NSDate* startDate;

@property (strong, nonatomic) UICollisionBehavior *collisionBehaviour;

@end

@implementation GameViewController

#pragma mark - Setting up CALayers, Pan gestures, and movement of the ball

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createBall];
    [self createBlocks];
    [self createPaddle];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panOnScreen:)];
    [self.view addGestureRecognizer:pan];
    
    //self.ballAcceleration = CGPointMake(ACCELERATION, ACCELERATION);
    // Do any additional setup after loading the view.
}

#pragma mark - Calling main game loop method

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //[self createGameLoop];
    [self startDynamicAnimator];
}

#pragma mark - Method for specifying pan gesture of the lower platform

- (void)panOnScreen:(UIPanGestureRecognizer *)pan;
{
    //only moves on x axis
    CGPoint position = [pan locationInView:self.view];
    self.paddle.center = CGPointMake(position.x, CGRectGetHeight(self.view.frame) - 50);

    [self.animator updateItemUsingCurrentState:self.paddle];
}

#pragma mark - Methods for creating the various layers

- (void)createBall
{
    UIImage *image = [UIImage imageNamed:@"catball"];
    self.ball = [[UIImageView alloc] initWithImage:image];

    self.ball.bounds = CGRectMake(0, 0, image.size.width / 6, image.size.height / 6);
    self.ball.center = CGPointMake(CGRectGetWidth(self.view.frame) / 2, CGRectGetHeight(self.view.frame) - 250);
    [self.view addSubview:self.ball];


}

- (void)createBlocks
{
    NSUInteger heightOfBlocks = 30;
    NSUInteger widthOfBlocks = CGRectGetWidth(self.view.frame) / 6;
    
    //storing the blocks
    NSMutableArray *blocksArray = [NSMutableArray array];
    for (NSUInteger a = 0; a < 6; a++) { //a is blocks down
        
        for (NSUInteger b = 0; b < 6; b++) { //b is blocks across
            
            //positions for each block
            NSUInteger y = 100 + (a * heightOfBlocks);
            NSUInteger x = (b * widthOfBlocks) + (widthOfBlocks / 2);
            
            UIView *block = [[UIView alloc] init];
            block.bounds = CGRectMake(0, 0, widthOfBlocks, heightOfBlocks);
            block.backgroundColor = [self randomColor];
            block.center = CGPointMake(x, y);
            [self.view addSubview:block];
            [blocksArray addObject:block];
        }
        
        
    }
    
    self.blocks = blocksArray;

}

- (void)createPaddle
{
    UIImage *image = [UIImage imageNamed:@"paddle"];
    self.paddle = [[UIImageView alloc] initWithImage:image];

    self.paddle.bounds = CGRectMake(0, 0, image.size.width / 4, image.size.height / 4);
    self.paddle.center = CGPointMake(CGRectGetWidth(self.view.frame) / 2, CGRectGetHeight(self.view.frame) - 50);
    [self.view addSubview:self.paddle];


}

#pragma mark - Dynamic animator
-(void) startDynamicAnimator
{
    
    UIDynamicAnimator *animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.animator = animator;
    
    // Add dynamic properties
    UIDynamicItemBehavior* ballDynamicProperties = [[UIDynamicItemBehavior alloc] initWithItems:@[self.ball]];
    ballDynamicProperties.allowsRotation = NO;
    ballDynamicProperties.density = 1;
    ballDynamicProperties.elasticity = 1.0;
    ballDynamicProperties.friction = 0.0;
    ballDynamicProperties.resistance = 0.0;
    [self.animator addBehavior:ballDynamicProperties];

    UIDynamicItemBehavior* paddleDynamicProperties = [[UIDynamicItemBehavior alloc] initWithItems:@[self.paddle]];
    paddleDynamicProperties.allowsRotation = NO;
    paddleDynamicProperties.density = 1000;
    [self.animator addBehavior:paddleDynamicProperties];
    
    UIDynamicItemBehavior* blockDynamicProperties = [[UIDynamicItemBehavior alloc] init];
    blockDynamicProperties.allowsRotation = NO;
    blockDynamicProperties.density = 1000;
    
    for(UIView* block in self.blocks) {
        [blockDynamicProperties addItem:block];
    }
    
    [self.animator addBehavior:blockDynamicProperties];
    
    // Add collisions
    UICollisionBehavior *collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.ball, self.paddle]];
    
    for(UIView* block in self.blocks) {
        [collisionBehavior addItem:block];
    }

    collisionBehavior.collisionMode = UICollisionBehaviorModeEverything;
    collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    collisionBehavior.collisionDelegate = self;
    self.collisionBehaviour = collisionBehavior;
    [animator addBehavior:collisionBehavior];
    
    // Push (move) ball
    self.pusher = [[UIPushBehavior alloc] initWithItems:@[self.ball]
                                                   mode:UIPushBehaviorModeInstantaneous];
    self.pusher.pushDirection = CGVectorMake(-0.5, -0.5);
    self.pusher.active = YES;
    [self.animator addBehavior:self.pusher];
}


-  (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item1 withItem:(id<UIDynamicItem>)item2 atPoint:(CGPoint)p
{
    //creating new array out of existing blocks array, because you cannot iterate and remove objects
    //from an array at the same time. So we create the new array to iterate through
    //and old to remove blocks from.
    NSArray *blocksArray = [NSArray arrayWithArray:self.blocks];
    
    id<UIDynamicItem> collisionItem = nil;
    
    if(item1 == self.ball) {
        collisionItem = item2;
    } else if(item2 == self.ball) {
        collisionItem = item1;
    }
    
    if(collisionItem) {
        for (UIView *block in blocksArray) {
            if(collisionItem == block) {
                // TODO: Implement add to score
                
                [self.collisionBehaviour removeItem:block];
                [self.blocks removeObject:block];
                [block removeFromSuperview];
            }
        }
    }
    
    if ([self.blocks count] < 1) {
        [self.winGameAlert setHidden:NO];
        [self.animator removeAllBehaviors];
    }
}

- (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p
{
    if(item == self.ball) {
        if (CGRectGetMaxY(self.ball.frame) > self.view.frame.size.height - 20) {
            [self.endGameAlert setHidden:NO];
            [self.animator removeAllBehaviors];
        }
    }
}


#pragma mark - Old code not using UIDynamicAnimator
/*
- (void)createGameLoop
{
//    //check if there's a timer already running.
//    if (self.timer) {
//        [self.timer invalidate];
//        self.timer = nil;
//    }
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.0001 target:self selector:@selector(gameLoop:) userInfo:nil repeats:YES];
    
    self.startDate = [[NSDate alloc] init];
    
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(gameLoop:)];
    displayLink.frameInterval = 2;
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.displayLink = displayLink;
}

#pragma mark - Checking object collisions

- (void)checkBallToPaddleCollisions
{
    CGRect ballFrame = self.ball.frame;
    if (CGRectIntersectsRect(ballFrame, self.paddle.frame)) {
        self.ballAcceleration = CGPointMake(self.ballAcceleration.x, self.ballAcceleration.y * -1.);

    }


}

- (void)CheckBallToBlockCollisions
{
    CGRect ballFrame = self.ball.frame;
    
    //creating new array out of existing blocks array, because you cannot iterate and remove objects
    //from an array at the same time. So we create the new array to iterate through
    //and old to remove blocks from.
    NSArray *blocksArray = [NSArray arrayWithArray:self.blocks];
    
    for (CALayer *block in blocksArray){
        CGRect blockFrame = block.frame;
        if (CGRectIntersectsRect(ballFrame, blockFrame)) {
            self.ballAcceleration = CGPointMake(self.ballAcceleration.x, self.ballAcceleration.y * -1.);
            [self.blocks removeObject:block];
            [block removeFromSuperlayer];
        
        }
    }


}

- (void)gameLoop:(id)sender
{
    static NSTimeInterval oldElapsed = 0;
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:self.startDate];
    
    static CGFloat oldX = 0;
    //NSTimeInterval elapsedDiff = elapsed-oldElapsed;
    
    CGFloat accelX = self.ballAcceleration.x; //* (elapsedDiff * 40.3333);
    CGFloat accelY = self.ballAcceleration.y; //* (elapsedDiff * 40.3333);
    CGFloat newX = self.ball.position.x + accelX;
    CGFloat newY = self.ball.position.y + accelY;
    
    //NSLog(@"timeDiff = %f  diff= %f", elapsedDiff, newX-oldX);
    
    oldX = newX;
    oldElapsed = elapsed;
    
    [CATransaction begin];
    
    [CATransaction setAnimationDuration:0.0];
    self.ball.position = CGPointMake(newX, newY);
    [CATransaction commit];
  
    //check x axis
    if (CGRectGetMinX(self.ball.frame) < 0 || CGRectGetMaxX(self.ball.frame) > self.view.frame.size.width) {
        self.ballAcceleration = CGPointMake(self.ballAcceleration.x * -1., self.ballAcceleration.y);
        
    }
    
    //check y axis
    if (CGRectGetMaxY(self.ball.frame) > self.view.frame.size.height) {
        [self.endGameAlert setHidden:NO];
        [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        //-1 goes in the opposite direction
    
        
    }
    
    if (CGRectGetMinY(self.ball.frame) < 0) {
        self.ballAcceleration = CGPointMake(self.ballAcceleration.x, self.ballAcceleration.y * -1.);
    }
    
    [self checkBallToPaddleCollisions];
    [self CheckBallToBlockCollisions];
    
    if ([self.blocks count] < 1) {
        [self.winGameAlert setHidden:NO];
        [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
}
*/

#pragma mark - Randomizing the color of the blocks

- (UIColor *)randomColor
{
    return [UIColor colorWithRed:(rand()%255) / 255.0 green:(rand()%255) / 255.0 blue:(rand()%255) / 255.0 alpha:1.0];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Win/Loss game states

- (IBAction)returnHome:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)returnHomeWin:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
