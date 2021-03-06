//
//  SJSBarButton.h
//  VisualDictionary
//
//  Created by Kai Lu on 3/9/15.
//  Copyright (c) 2015 Kai Lu. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "SJSTheme.h"
#import "SJSEnums.h"

@interface SJSIconButton : SKShapeNode

- (SJSIconButton *)init;
- (void)update;
- (void)setFrame:(CGRect)frame;
- (void)setText:(NSString *)text;

- (void)setIcon:(NSString *)iconFile;
- (void)setDisabledIcon:(NSString *)iconFile;

- (void)setWidth:(CGFloat)width;
- (void)setHeight:(CGFloat)height;

- (void)enable;
- (void)disable;

@end
