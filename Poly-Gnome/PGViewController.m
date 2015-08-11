//
//  PGViewController.m
//  Poly-Gnome
//
//  Created by Azi Crawford on 5/24/14.
//  Copyright (c) 2014 Azi Crawford. All rights reserved.
//

#import "PGViewController.h"
#import "PGBottomDivisionSlider.h"
#import "PGTopDivisionSlider.h"
#import "PGTempoSlider.h"
#import "PGKonokol.h"
@import AudioToolbox;
@import AVFoundation;

@interface PGViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *konokolDisplay;
@property (weak, nonatomic) IBOutlet UILabel *numericDisplay;
@property (weak, nonatomic) IBOutlet UILabel *plainEnglishDisplay;
@property (weak, nonatomic) IBOutlet UILabel *tempoDisplay;
@property (strong, nonatomic) PGKonokol * topKonokol;
@property (strong, nonatomic) PGKonokol * bottomKonokol;
@property (weak, nonatomic) IBOutlet UIButton *start;
@property (weak, nonatomic) IBOutlet UIButton *stop;
@property (nonatomic,strong) AVAudioPlayer *bottomSound;
@property (nonatomic,strong) AVAudioPlayer *topSound;

@end

@implementation PGViewController

int topDivision = 3;
int bottomDivision = 2;
float tempo = 98.6;
int count = 0;
const int SUBDIVISION_WIDTH = 170;
const int POLYRHYTHM_ROW_HEIGHT = 56;
bool METRONOME_RUNNING = NO;

CALayer * konokolRoll;
CALayer * topSubdivisionRow;
CALayer * konokolRow;
CALayer * bottomSubdivisionRow;
NSArray * englishForNumbers;
NSTimer * metronome;

- (void)viewDidLoad
{
    [self setUpEnglishNumbers];
    [self setUpAudio];
    [super viewDidLoad];

    self.topKonokol = [[PGKonokol alloc] initWithCount:topDivision];
    self.bottomKonokol = [[PGKonokol alloc] initWithCount:bottomDivision];

    [self.konokolDisplay setContentSize:CGSizeMake([self getJointSubDivision] * SUBDIVISION_WIDTH, POLYRHYTHM_ROW_HEIGHT * 3) ];
    
    konokolRoll = [[CALayer alloc] init];
    konokolRoll.frame = CGRectMake(0, 0, SUBDIVISION_WIDTH, POLYRHYTHM_ROW_HEIGHT);
    konokolRoll.backgroundColor = [UIColor clearColor].CGColor;
    
    topSubdivisionRow = [[CALayer alloc] init];
    [topSubdivisionRow setFrame: CGRectMake(0,0, [self getJointSubDivision] * SUBDIVISION_WIDTH, POLYRHYTHM_ROW_HEIGHT)];
    
    konokolRow = [[CALayer alloc] init];
    [konokolRow setFrame: CGRectMake(0,POLYRHYTHM_ROW_HEIGHT, [self getJointSubDivision] * SUBDIVISION_WIDTH, POLYRHYTHM_ROW_HEIGHT)];
    
    bottomSubdivisionRow = [[CALayer alloc] init];
    [bottomSubdivisionRow setFrame: CGRectMake(0, POLYRHYTHM_ROW_HEIGHT * 2, [self getJointSubDivision] * SUBDIVISION_WIDTH, POLYRHYTHM_ROW_HEIGHT)];
    
    
    [konokolRoll addSublayer:topSubdivisionRow];
    [konokolRoll addSublayer:konokolRow];
    [konokolRoll addSublayer:bottomSubdivisionRow];
    
    [self updatePolyrhythmRows];

    [self.konokolDisplay.viewForBaselineLayout.layer addSublayer:konokolRoll];
    self.konokolDisplay.clipsToBounds = YES;
    
    self.start.layer.borderWidth = 1;
    self.start.layer.borderColor = [UIColor colorWithRed:0 green:0.50 blue:0 alpha:1].CGColor;
    self.start.layer.backgroundColor = [UIColor colorWithRed:0 green:0.75 blue:0 alpha:1].CGColor;
    self.start.layer.cornerRadius = self.start.layer.frame.size.width/2;
    
    self.stop.layer.borderWidth = 1;
    self.stop.layer.borderColor = [UIColor blackColor].CGColor;
    self.stop.layer.backgroundColor = [UIColor grayColor].CGColor;
    self.stop.layer.cornerRadius = self.stop.layer.frame.size.width/2;

}

- (void) setUpAudio
{
    NSURL* topMusicFile = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"E-Perc 15" ofType:@"wav"]];
    self.topSound = [[AVAudioPlayer alloc] initWithContentsOfURL: topMusicFile error:nil];
    [self.topSound setVolume:1.0];
    self.topSound.pan = -1.0;
    [self.topSound prepareToPlay];

    
    NSURL * bottomMusicFile = [NSURL fileURLWithPath: [[NSBundle mainBundle]
        pathForResource:@"E-Kick 7" ofType: @"wav"]];
    self.bottomSound = [[AVAudioPlayer alloc] initWithContentsOfURL:bottomMusicFile error:nil];
    [self.bottomSound setVolume:1.0];
    self.bottomSound.pan = 1.0;
    [self.bottomSound prepareToPlay];

}

- (void) setUpEnglishNumbers
{
    englishForNumbers = @[@"Zero",
                          @"One",
                          @"Two",
                          @"Three",
                          @"Four",
                          @"Five",
                          @"Six",
                          @"Seven"];
   
}

- (IBAction)sliderValueChanged:(UISlider *)sender
{
    if (METRONOME_RUNNING)
    {
        [self stopMetronome];
    }
    
    if ([sender isMemberOfClass:[PGTopDivisionSlider class]])
    {
        topDivision = (int) sender.value;
    }
    
    else if ([sender isMemberOfClass:[PGBottomDivisionSlider class]])
    {
        bottomDivision = (int) sender.value;
    }
    else if ([sender isMemberOfClass:[PGTempoSlider class]])
    {
        tempo = sender.value;
    }
    [self.topKonokol setCount:topDivision];
    [self.bottomKonokol setCount:bottomDivision];
    [self updateDisplays];
    if (METRONOME_RUNNING)
    {
        [self startMetronome];
    }
    
}

- (IBAction)startButtonTouched:(UIButton *)sender
{
        [self makeSound]; // just a test
    if (!METRONOME_RUNNING)
    {
        [self startMetronome];
        METRONOME_RUNNING = YES;
        self.start.layer.borderColor = [UIColor blackColor].CGColor;
        self.start.layer.backgroundColor = [UIColor grayColor].CGColor;
        self.stop.layer.borderColor = [UIColor colorWithRed:0.535 green:0.108 blue:0.127 alpha:1].CGColor;
        self.stop.layer.backgroundColor = [UIColor colorWithRed:0.635 green:0.208 blue:0.227 alpha:1].CGColor;
    }
}


- (void) startMetronome
{
    if (!metronome) {
        metronome = [NSTimer scheduledTimerWithTimeInterval:[self getSecondsPerJointSubdivision]
                                                  target:self
                                                selector:@selector(renderTick)
                                                userInfo:nil
                                                 repeats:YES];
    }
}

- (void)processStopMessage
{
    [self.konokolDisplay setContentOffset:CGPointMake(0, self.konokolDisplay.contentOffset.y)];
    count = 0;
    [self stopMetronome];
    if (METRONOME_RUNNING)
    {
        METRONOME_RUNNING = NO;
        self.stop.layer.borderColor = [UIColor blackColor].CGColor;
        self.stop.layer.backgroundColor = [UIColor grayColor].CGColor;
        self.start.layer.borderColor = [UIColor colorWithRed:0.2 green:0.50 blue:0.2 alpha:1].CGColor;
        self.start.layer.backgroundColor = [UIColor colorWithRed:0.337 green:0.694 blue:0.345 alpha:1].CGColor;
    }
}


- (IBAction)stopButtonTouched:(UIButton *)sender
{
    [self processStopMessage];
}

- (void) stopMetronome
{
    [self.bottomSound stop];
    [self.topSound stop];
    
    if ([metronome isValid]) {
        [metronome invalidate];
    }
    metronome = nil;
}

- (void) renderTick
{
    // advance roll
    if (self.konokolDisplay.contentOffset.x >= self.konokolDisplay.contentSize.width - SUBDIVISION_WIDTH)
    {
        [self.konokolDisplay setContentOffset:CGPointMake(0 - SUBDIVISION_WIDTH, self.konokolDisplay.contentOffset.y)];
    }
    
    [self.konokolDisplay setContentOffset:CGPointMake((self.konokolDisplay.contentOffset.x + SUBDIVISION_WIDTH), self.konokolDisplay.contentOffset.y) animated:NO];
    [self updateCount];
    // make appropriate sound

}

- (void) updateDisplays
{
    self.numericDisplay.text = [NSString stringWithFormat:@"%d:%d", topDivision, bottomDivision];
    self.plainEnglishDisplay.text = [NSString stringWithFormat:@"%@", [self.topKonokol getChantString]];
    self.tempoDisplay.text = [NSString stringWithFormat:@"%2.1f bpm", tempo /bottomDivision];
    
    [self.konokolDisplay setContentSize:CGSizeMake([self getJointSubDivision] * SUBDIVISION_WIDTH, 162) ];
    konokolRoll.frame = CGRectMake(0, 0, [self getJointSubDivision] * SUBDIVISION_WIDTH, 162);
    
    [self updatePolyrhythmRows];
    
}

- (float) getSecondsPerJointSubdivision
{
    return 60/tempo;
    
}


- (int) getJointSubDivision
{
    return [self calculateLCMForFirstInteger:topDivision secondInteger:bottomDivision];
}

- (int) calculateLCMForFirstInteger: (int) firstNum secondInteger: (int) secondNum
{
    return (firstNum * secondNum) / [self gcdFirst:firstNum second:secondNum];
}


- (int) gcdFirst: (int) a
          second: (int) b
{
    for (;;)
    {
        if (a == 0) return b;
        b %= a;
        if (b == 0) return a;
        a %= b;
    }
}

- (void) updatePolyrhythmRows
{
    [self updateTopSubdivisionRow];
    [self updateKonokolRow];
    [self updateBottomSubdivisionRow];
}

- (void) updateTopSubdivisionRow
{
    // remove current subviews
    for (CALayer *subLayer in [topSubdivisionRow.sublayers copy] )
    {
        [subLayer removeFromSuperlayer];
    }
    
    for (int step = 0; step < [self getJointSubDivision]; step++)
    {
        if (step % bottomDivision == 0)
        {
            CALayer * beatLayer = [[CALayer alloc] init];
            [beatLayer setFrame: CGRectMake(step * SUBDIVISION_WIDTH, 0, SUBDIVISION_WIDTH, POLYRHYTHM_ROW_HEIGHT)];
            beatLayer.borderWidth = 5;
            beatLayer.borderColor = [UIColor colorWithRed:0.2 green:0.3 blue:.5 alpha:1].CGColor;
            beatLayer.cornerRadius = POLYRHYTHM_ROW_HEIGHT/2;
            beatLayer.backgroundColor = [UIColor colorWithRed:0.318 green:0.451 blue:.6 alpha:1].CGColor;
            [topSubdivisionRow addSublayer:beatLayer];
        }
    }
}



- (void) updateKonokolRow
{
    // remove current subviews
    for (CALayer *subLayer in [konokolRow.sublayers copy] )
    {
        [subLayer removeFromSuperlayer];
    }
    
    for (int step = 0; step < [self getJointSubDivision]; step++)
    {
        CATextLayer * konokolWord = [[CATextLayer alloc] init];
        [konokolWord setFrame:CGRectMake(step * SUBDIVISION_WIDTH, 0, SUBDIVISION_WIDTH, POLYRHYTHM_ROW_HEIGHT)];
        NSArray * konokolWords = [self.topKonokol getChantWords];
        NSString * word = [konokolWords objectAtIndex: step % topDivision];
        konokolWord.backgroundColor = [UIColor whiteColor].CGColor;
        konokolWord.borderWidth = 2;
        konokolWord.borderColor = [UIColor grayColor].CGColor;
        konokolWord.cornerRadius = 5;
        konokolWord.string = word;
        konokolWord.alignmentMode = kCAAlignmentCenter;
        if (step % [self getJointSubDivision] == 0)
        {
            konokolWord.foregroundColor = [UIColor colorWithRed:0.45 green:0.38 blue:.5 alpha:1].CGColor;
        }
        else if (step % bottomDivision == 0)
        {
            konokolWord.foregroundColor = [UIColor colorWithRed:0.318 green:0.451 blue:.6 alpha:1].CGColor;
        }
        else if (step % topDivision == 0)
        {
            konokolWord.foregroundColor = [UIColor colorWithRed:0.635 green:0.314 blue:0.459 alpha:1].CGColor;
        }
        else
        {
            konokolWord.foregroundColor = [UIColor darkGrayColor].CGColor;
        }
        [konokolRow addSublayer:konokolWord];
    }
}

- (void) updateBottomSubdivisionRow
{
    // remove current subviews
    for (CALayer *subLayer in [bottomSubdivisionRow.sublayers copy])
    {
        [subLayer removeFromSuperlayer];
    }
            
    for (int step = 0; step < [self getJointSubDivision]; step++)
    {
        if (step % topDivision == 0)
        {
            CALayer * beatLayer = [[CALayer alloc] init];
            [beatLayer setFrame: CGRectMake(step * SUBDIVISION_WIDTH, 2 * POLYRHYTHM_ROW_HEIGHT, SUBDIVISION_WIDTH, POLYRHYTHM_ROW_HEIGHT)];
            beatLayer.borderWidth = 5;
            beatLayer.borderColor = [UIColor colorWithRed:0.5 green:0.2 blue:0.3 alpha:1].CGColor;
            beatLayer.cornerRadius = POLYRHYTHM_ROW_HEIGHT/2;
            beatLayer.backgroundColor = [UIColor colorWithRed:0.635 green:0.314 blue:0.459 alpha:1].CGColor;
            [topSubdivisionRow addSublayer:beatLayer];
           
        }
    }
}

- (void) updateCount
{
    count++;
    if (count % [self getJointSubDivision] == 0)
    {
        [self makeSound];
    }
    else if (count % topDivision == 0)
    {
        [self.bottomSound play];
    }
    else if (count % bottomDivision == 0)
    {
        [self.topSound play];
    }
}


- (void) makeSound
{
    [self.bottomSound play];
    [self.topSound play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
