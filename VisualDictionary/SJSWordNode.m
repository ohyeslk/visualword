//
//  SJSWordNode.m
//  GraphVisualizer
//
//  Created by Kai Lu on 2/13/15.
//  Copyright (c) 2015 Kai Lu. All rights reserved.
//

#import "SJSWordNode.h"
#import "SJSGraphScene.h"

NSInteger maxNodeThreshold = 20;
NSInteger maxDepth = 3;

@implementation SJSWordNode {
    NSString *_meaning;
    NSSet *_neighbourNames;
    SKShapeNode *_nodeFrame;
    BOOL _remove;
    BOOL _highlighted;
    CGFloat _prevZPos;
}

- (id)initWordWithName:(NSString *)name
{
    self = [self initWithName:name withType:WordType];
    return self;
}

- (id)initMeaningWithName:(NSString *)name
{
    if ([name characterAtIndex:0] == 'a') {
        self = [self initWithName:name withType:AdjectiveType];
    } else if ([name characterAtIndex:0] == 'n') {
        self = [self initWithName:name withType:NounType];
    } else if ([name characterAtIndex:0] == 'r') {
        self = [self initWithName:name withType:AdverbType];
    } else if ([name characterAtIndex:0] == 'v') {
        self = [self initWithName:name withType:VerbType];
    } else {
        [NSException raise:@"Invalid meaning node" format:@"Meaning node with name %@ is invalid", name];
    }
    
    return self;
}

- (id)initWithName:(NSString *)name withType:(NodeType)type
{
    self = [super init];
    self.name = name;
    self.type = type;
    
    if (self.type == WordType) {
        self.text = self.name;
    } else {
        self.text = [self getTypeAsAbreviatedString];
    }
    
    self.distance = -1;
    self.verticalAlignmentMode = SKLabelVerticalAlignmentModeCenter;
    
    _neighbourNames = nil;
    _remove = NO;
    _highlighted = NO;
    _meaning = nil;
    _prevZPos = 0;
    
    _nodeFrame = [SKShapeNode new];
    _nodeFrame.zPosition = -0.5;
    [self addChild:_nodeFrame];
    
    CGFloat nodeSize = [SJSGraphScene.theme nodeSize];
    self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:nodeSize];
    self.physicsBody.mass = 1;
    self.physicsBody.dynamic = YES;
    self.physicsBody.linearDamping = 1;
    self.physicsBody.friction = 0;
    self.physicsBody.restitution = 0;
    self.physicsBody.allowsRotation = NO;
    self.physicsBody.collisionBitMask = 1;
    
    [self update];
    return self;
}

- (void)setRemove:(BOOL)remove
{
    _remove = remove;
}

- (void)setFontName:(NSString *)fontName
{
    if (super.fontName != fontName) {
        super.fontName = fontName;
    }
}

- (void)setZPosition:(CGFloat)zPosition
{
    if (_highlighted) {
        _prevZPos = zPosition;
    } else {
        [super setZPosition:zPosition];
    }
}

- (void)highlight
{
    if (_highlighted) {
        return;
    }
    
    _highlighted = YES;
    _prevZPos = self.zPosition;
    super.zPosition = 0;
    [self update];
}

- (void)reset
{
    if (!_highlighted) {
        return;
    }
    
    _highlighted = NO;
    super.zPosition = _prevZPos;
    _prevZPos = 0;
    [self update];
}

- (BOOL)remove
{
    return _remove;
}

- (void)update
{
    if (_highlighted) {
        _nodeFrame.fillColor = [SJSGraphScene.theme currentNodeColor];
        self.fontSize = [SJSGraphScene.theme currentNodeFontSize];
        self.fontName = [SJSGraphScene.theme currentNodeFontNameByNodeType:self.type];
        self.fontColor = [SJSGraphScene.theme currentNodeFontColor];
    } else if (self.distance == 0) {
        _nodeFrame.fillColor = [SJSGraphScene.theme rootNodeColor];
        self.fontSize = [SJSGraphScene.theme rootNodeFontSize];
        self.fontName = [SJSGraphScene.theme rootNodeFontNameByNodeType:self.type];
        self.fontColor = [SJSGraphScene.theme rootNodeFontColor];
    } else {
        _nodeFrame.fillColor = [SJSGraphScene.theme colorByNodeType:self.type];
        self.fontSize = [SJSGraphScene.theme fontSizeByNodeType:self.type];
        self.fontName = [SJSGraphScene.theme fontNameByNodeType:self.type];
        self.fontColor = [SJSGraphScene.theme fontColorByNodeType:self.type];
    }
    
    _nodeFrame.lineWidth = [SJSGraphScene.theme lineWidth];
    
    CGFloat nodeSize = [SJSGraphScene.theme nodeSize];
    if (_highlighted) {
        nodeSize *= 1.2;
    }
    
    if ([SJSGraphScene.theme nodeStyleByNodeType:self.type] == CircleStyle) {
        CGMutablePathRef circlePath = CGPathCreateMutable();
        CGPathAddArc(circlePath, nil, 0, 0, nodeSize, 0, M_PI*2, true);
        _nodeFrame.path = circlePath;
        CGPathRelease(circlePath);
    } else if ([SJSGraphScene.theme nodeStyleByNodeType:self.type] == RoundedRectStyle) {
        CGRect wordFrame = [self frame];
        CGFloat width = wordFrame.size.width + [SJSGraphScene.theme roundedRectMarginX] * 2;
        CGFloat height = wordFrame.size.height + [SJSGraphScene.theme roundedRectMarginY] * 2;
        
        CGRect rect = CGRectMake(-width/2, -height/2, width, height);
        CGFloat radius = [SJSGraphScene.theme roundedRectRadius];
        CGPathRef path = CGPathCreateWithRoundedRect(rect, radius, radius, NULL);
        _nodeFrame.path = path;
        CGPathRelease(path);
    }
    
    if ([self canGrow]) {
        _nodeFrame.strokeColor = [SJSGraphScene.theme canGrowEdgeColor];
    } else if (_highlighted) {
        _nodeFrame.strokeColor = [SJSGraphScene.theme currentNodeEdgeColor];
    } else {
        _nodeFrame.strokeColor = [SJSGraphScene.theme cannotGrowEdgeColor];
    }
}

- (NSSet *)neighbourNames
{
    if (_neighbourNames == nil) {
        if (self.type == WordType) {
            _neighbourNames = [SJSWordNetDB.instance meaningsForWord:self.name];
        } else {
            _neighbourNames = [SJSWordNetDB.instance wordsForMeaning:self.name];
        }
    }
    return _neighbourNames;
}

- (BOOL)isConnectedTo:(SJSWordNode *)node
{
    return [self.neighbourNames containsObject:node.name];
}

- (void)disableDynamic
{
    SKPhysicsBody *physicsBody = self.physicsBody;
    physicsBody.dynamic = NO;
    self.physicsBody = physicsBody;
}

- (void)enableDynamic
{
    SKPhysicsBody *physicsBody = self.physicsBody;
    physicsBody.dynamic = YES;
    self.physicsBody = physicsBody;
}

- (void)promoteToRoot
{
    [self updateDistances];
    
    for (SJSWordNode *node in [self.parent children]) {
        if (node.distance > maxDepth) {
            node.remove = YES;
        }
    }
    
    [self growRecursively];
    [self update];
    
    for (SJSWordNode *node in [self.parent children]) {
        if (node.remove == YES) {
            [node removeFromParent];
        }
    }
}

- (void)updateDistances
{
    for (SJSWordNode *node in [self.parent children]) {
        node.distance = -1;
    }
    
    NSMutableArray *queue = [NSMutableArray new];
    
    self.distance = 0;
    CGFloat zPos = -1;
    self.zPosition = zPos--;
    
    [queue addObject:self];
    
    while (queue.count > 0) {
        SJSWordNode *node = [queue objectAtIndex:0];
        [queue removeObjectAtIndex:0];
        
        for (SJSWordNode *child in [node neighbourNodes]) {
            if (child.distance == -1) {
                child.zPosition = zPos--;
                child.distance = node.distance + 1;
                [queue addObject:child];
            }
        }
    }
}

- (NSArray *)neighbourNodes
{
    if (self.neighbourNames == nil) {
        NSLog(@"neighbourNames returned nil!");
        return nil;
    }
    
    NSMutableArray *neighbourNodes = [NSMutableArray new];
    
    for (NSString *neighbourName in self.neighbourNames) {
        SJSWordNode *neighbourNode = (SJSWordNode *)[self.parent childNodeWithName:neighbourName];
        if (neighbourNode != nil) {
            [neighbourNodes addObject:neighbourNode];
        }
    }
    
    return neighbourNodes;
}

- (BOOL)canGrow
{
    for (NSString *neighbourName in self.neighbourNames) {
        SJSWordNode *neighbour = (SJSWordNode *)[self.parent childNodeWithName:neighbourName];
        
        if (neighbour == nil) {
            return true;
        }
    }
    return false;
}

- (NSInteger)countNodes
{
    NSInteger count = 0;
    
    for (SJSWordNode *node in [self.parent children]) {
        if (node.remove == NO) {
            count++;
        }
    }
    
    return count;
}

- (void)grow
{
    for (NSString *neighbourName in self.neighbourNames) {
        SJSWordNode *neighbour = (SJSWordNode *)[self.parent childNodeWithName:neighbourName];
        
        if (neighbour == nil) {
            if (self.type == WordType) {
                neighbour = [[SJSWordNode alloc] initMeaningWithName:neighbourName];
            } else {
                neighbour = [[SJSWordNode alloc] initWordWithName:neighbourName];
            }
            
            CGFloat count = self.parent.children.count;
            CGFloat x_off = sinf(M_PI * 2 * count / maxNodeThreshold) * 60;
            CGFloat y_off = cosf(M_PI * 2 * count / maxNodeThreshold) * 60;
            neighbour.position = CGPointMake(x_off + self.position.x, y_off + self.position.y);

            [self.parent addChild:neighbour];
        } else {
            neighbour.remove = NO;
        }
    }
}

- (void)growRecursively
{
    for (SJSWordNode *node in [self.parent children]) {
        node.distance = -1;
    }
    
    CGFloat zPos = -1;
    self.zPosition = zPos--;
    
    NSMutableArray *queue = [NSMutableArray new];
    self.distance = 0;
    [queue addObject:self];
    
    while (queue.count > 0 && [self countNodes] < maxNodeThreshold) {
        SJSWordNode *node = [queue objectAtIndex:0];
        [queue removeObjectAtIndex:0];
        
        [node grow];
        for (SJSWordNode *child in [node neighbourNodes]) {
            child.zPosition = zPos--;
            
            if (child.distance == -1) {
                child.distance = node.distance + 1;
                [queue addObject:child];
            }
        }
    }
}

- (NSString *)getTypeAsString
{
    if (self.type == WordType) {
        return @"word";
    } else if (self.type == AdverbType) {
        return @"adverb";
    } else if (self.type == AdjectiveType) {
        return @"adjective";
    } else if (self.type == NounType) {
        return @"noun";
    } else if (self.type == VerbType) {
        return @"verb";
    } else {
        return nil;
    }
}

- (NSString *)getTypeAsAbreviatedString
{
    if (self.type == WordType) {
        return @"w";
    } else if (self.type == AdverbType) {
        return @"adv";
    } else if (self.type == AdjectiveType) {
        return @"adj";
    } else if (self.type == NounType) {
        return @"n";
    } else if (self.type == VerbType) {
        return @"v";
    } else {
        return nil;
    }
}

- (NSString *)meaning
{
    if (_meaning == nil) {
        _meaning = [SJSWordNetDB.instance definitionOfMeaning:self.name];
    }
    
    return _meaning;
}

- (NSMutableAttributedString *)getDefinition
{
    if (self.type != WordType) {
        NSString *typeString = [self getTypeAsString];
        NSString *definitionString = self.meaning;
        
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@", typeString, definitionString]];
        NSRange typeRange = NSMakeRange(0, typeString.length + 2);
        NSRange definitionRange = NSMakeRange(typeString.length + 2, definitionString.length);
        
        UIFont *typeFont = [UIFont fontWithName:[SJSGraphScene.theme typeFontName]
                                           size:[SJSGraphScene.theme typeFontSize]];
        [result addAttribute:NSFontAttributeName value:typeFont range:typeRange];
        [result addAttribute:NSForegroundColorAttributeName value:[SJSGraphScene.theme typeFontColor] range:typeRange];
        
        UIFont *definitionFont = [UIFont fontWithName:[SJSGraphScene.theme definitionFontName]
                                                 size:[SJSGraphScene.theme definitionFontSize]];
        [result addAttribute:NSFontAttributeName value:definitionFont range:definitionRange];
        [result addAttribute:NSForegroundColorAttributeName value:[SJSGraphScene.theme definitionFontColor] range:definitionRange];
        
        return result;
    }
    
    if (self.type == WordType) {
        NSArray *neighbours = [self neighbourNodes];
        
        NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:self.text];
        NSRange wordRange = NSMakeRange(0, result.length);
        UIFont *wordDefFont = [UIFont fontWithName:[SJSGraphScene.theme wordDefFontName]
                                              size:[SJSGraphScene.theme wordDefFontSize]];
        [result addAttribute:NSFontAttributeName value:wordDefFont range:wordRange];
        [result addAttribute:NSForegroundColorAttributeName value:[SJSGraphScene.theme wordDefFontColor] range:wordRange];
        
        for (int i = 0; i < neighbours.count; i++) {
            NSMutableAttributedString *next = [[neighbours objectAtIndex:i] getDefinition];
            if (next != nil) {
                [result appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"\n"]];
                [result appendAttributedString:next];
            }
        }
        
        return result;
    }
    
    return nil;
}

- (void)removeFromParent
{
    [_nodeFrame removeFromParent];
    _nodeFrame = nil;
    
    [super removeFromParent];
}

@end
