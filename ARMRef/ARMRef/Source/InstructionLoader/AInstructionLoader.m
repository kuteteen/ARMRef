//
//  AInstructionLoader.m
//
//  Copyright (c) 2020 ARMRef (https://github.com/evilpenguin/ARMRef)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "AInstructionLoader.h"
#import "AInstruction.h"

NSString *const AInstructionLoaderFinishedNotificaton = @"AInstructionLoaderFinishedNotificaton";

@interface AInstructionLoader ()
@property (nonatomic, strong) NSMutableArray<AInstruction *> *allInstructions;

@end

@implementation AInstructionLoader

- (instancetype) init {
    if (self = [super init]) {
        self.armVersion = @"ARMv8.5a";
        
        [self _load];
    }
    
    return self;
}

#pragma mark - Private

- (void) _load {
    weakify(self);
    dispatch_async_global(^ {
        strongify(self);
        
        NSString *jsonFile = [NSBundle.mainBundle pathForResource:self.armVersion ofType:@"json"];
        if (jsonFile.length) {
            NSData *jsonData = [NSData dataWithContentsOfFile:jsonFile];
            if (jsonData.length) {
                NSArray *instructions = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                if (instructions.count) {
                    [self _parsedArrayToInstructiions:instructions];
                    
                    // Notify
                    dispatch_async_main(^{
                        [NSNotificationCenter.defaultCenter postNotificationName:AInstructionLoaderFinishedNotificaton object:nil];
                    });
                }
            }
        }
    });
}

#pragma mark - Getter

- (NSArray<AInstruction *> *) instructions {
    if (self.filerString.length) {
        NSIndexSet *indices = [self.allInstructions indexesOfObjectsPassingTest:^BOOL(AInstruction * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            return [obj.mnemonic rangeOfString:self.filerString options:NSCaseInsensitiveSearch].location != NSNotFound;
        }];
        
        return [self.allInstructions objectsAtIndexes:indices];
    }
    
    return self.allInstructions;
}

#pragma mark - Lazy

- (NSMutableArray<AInstruction *> *) allInstructions {
    if (!_allInstructions) _allInstructions = [NSMutableArray array];
    
    return _allInstructions;
}

#pragma mark - Private

- (void) _parsedArrayToInstructiions:(NSArray<NSDictionary *> *)array {
    // Create
    for (NSDictionary *instructionDict in array) {
        AInstruction *instruction = [[AInstruction alloc] initWithDictionary:instructionDict];
        [self.allInstructions addObject:instruction];
    }
    
    // Sort
    [self.allInstructions sortUsingComparator:^NSComparisonResult(AInstruction *obj1, AInstruction *obj2) {
        return [obj1.mnemonic compare:obj2.mnemonic];
    }];
}

@end
