//
//  AKProduct.m
//  AudioKit
//
//  Created by Aurelius Prochazka on 6/9/12.
//  Copyright (c) 2012 Aurelius Prochazka. All rights reserved.
//
//  Implementation of Csound's product:
//  http://www.csounds.com/manual/html/product.html
//


#import "AKProduct.h"

@implementation AKProduct

- (instancetype)init {
    return [super initWithString:[self operationName]];
}

- (instancetype)initWithOperands:(AKParameter *)firstOperand,... {
    self = [super initWithString:[self operationName]];
    if (self) {
        NSMutableArray *inputs = [[NSMutableArray alloc] init];
        AKParameter *eachInput;
        va_list argumentList;
        if (firstOperand) // The first argument isn't part of the varargs list,
        {                                   // so we'll handle it separately.
            [inputs addObject: firstOperand];
            va_start(argumentList, firstOperand); // Start scanning for arguments after firstObject.
            while ((eachInput = va_arg(argumentList, id))) // As many times as we can get an argument of type "id"
                [inputs addObject: eachInput]; // that isn't nil, add it to self's contents.
            va_end(argumentList);
        }
        self.inputs = inputs;
    }
    return self; 
}


- (instancetype)initWithFirstOperand:(AKParameter *)firstOperand
                       secondOperand:(AKParameter *)secondOperand;
{
    self = [super initWithString:[self operationName]];
    
    if (self) {
        NSMutableArray *inputs = [[NSMutableArray alloc] init];
        [inputs addObject:firstOperand];
        [inputs addObject:secondOperand];
        self.inputs = inputs;
    }
    return self;
}



- (NSString *)stringForCSD
{
    NSMutableArray *paramterStrings = [NSMutableArray array];

    for (AKParameter *param in self.inputs) {
        [paramterStrings addObject:[NSString stringWithFormat:@"AKAudio(%@)", param.parameterString]];
    }
    NSString *inputsCombined = [paramterStrings componentsJoinedByString:@", "];
    
    return [NSString stringWithFormat:@"%@ product %@",self, inputsCombined];
}

@end
