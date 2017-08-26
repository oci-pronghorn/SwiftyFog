//
//  AirportFlipLabel.h
//  MyAnimations
//
//  Created by Felix Dumit on 3/25/14.
//  Copyright (c) 2014 Felix Dumit. All rights reserved.
//

#import <UIKit/UIKit.h>

IB_DESIGNABLE
@interface FSDAirportFlipLabel : UILabel

/**
 *  Whether to play sound while flipping labels
 */
@property (nonatomic) IBInspectable BOOL useSound;

/**
 *  The font size
 */
@property (nonatomic) IBInspectable NSInteger textSize;

/**
 *  Optional fixed lenght for number of characters in label
 */
@property (nonatomic) IBInspectable NSInteger fixedLength;

/**
 *  The base number of flips a label will animate when changing between characters. Defaults to 10
 */
@property (nonatomic) IBInspectable NSInteger numberOfFlips;

/**
 *  The range used to calculate the random number of flips an animating label will take. The value will be randomly selected between (numberOfFlips, (1 + numberOfFlipsRange) * numberOfFlips ).
 *  Defaults to 1.0 => Default range is (numberOfFlips, 2*numberOfFlips)
 */
@property (nonatomic) IBInspectable CGFloat numberOfFlipsRange;

/**
 *  Base flip velocity for changing labels. Defaults to 0.1
 */
@property (nonatomic) IBInspectable CGFloat flipDuration;

/**
 *  Range of flip duration span. The actual duration will be calculated randomly between (flipDuration, (1 + flipDurationRange) * flipDuration).
 *  Defaults to 1.0 => Default range is (flipDuration, 2*flipDuration)
 */
@property (nonatomic) IBInspectable CGFloat flipDurationRange;

/**
 *  If there are any labels flipping
 */
@property (readonly, nonatomic) BOOL flipping;

/**
 *  Block called when the last label stops flipping
 */
@property (nonatomic, copy) void (^finishedFlippingLabelsBlock)(void);

/**
 *  Block called when the labels start flipping
 */
@property (nonatomic, copy) void (^startedFlippingLabelsBlock)(void);

/**
 *  The flipping label's text color
 */
@property (nonatomic) IBInspectable UIColor *flipTextColor;

/**
 *  The flipping label's background color
 */
@property (nonatomic) IBInspectable UIColor *flipBackGroundColor;


@end
