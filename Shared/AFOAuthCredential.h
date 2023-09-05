//
//  AFOAuthCredential.h
//  Fetch
//
//  Created by Amanuel Ayele on 4/1/14.
//  Copyright (c) 2016 Fetch, Inc. All rights reserved.
//
#include <UIKit/UIKit.h>

@interface AFOAuthCredential : NSObject <NSCoding>

///------------------------------------------
/// @name Accessing Credential Properties
///------------------------------------------

@property (nonatomic, readonly) NSString *accessToken;
@property (nonatomic, readonly) NSString *refreshToken;
@property (nonatomic, readonly) NSString *accessExpiration;
@property (nonatomic, readonly) NSString *refreshExpiration;
@property (nonatomic, readonly) NSString *userId;
@property (nonatomic, readonly) NSString *authSource;
@property (nonatomic) BOOL createdUserIndicator;

///--------------------------------------------
/// @name Creating and Initializing Credentials
///--------------------------------------------
- (id)initWithAccessToken:(NSString *)accessToken
             refreshToken:(NSString *)refreshToken
         accessExpireDate:(NSString*)accessExpireDate
        refreshExpireDate:(NSString*)refreshExpireDate
                   userId:(NSString*)userId
               authSource:(NSString*)authSource;

- (id)initWithAccessToken:(NSString *)accessToken
             refreshToken:(NSString *)refreshToken
         accessExpireDate:(NSString*)accessExpireDate
        refreshExpireDate:(NSString*)refreshExpireDate
                   userId:(NSString*)userId
               authSource:(NSString*)authSource
     createdUserIndicator:(BOOL)createdUserIndicator;

///-----------------------------------------
/// @name Storing and Retrieving Credentials
///-----------------------------------------

+ (AFOAuthCredential *)retrieveCredentialWithIdentifier:(NSString *)identifier;

+ (BOOL)storeCredential:(AFOAuthCredential *)credential
         withIdentifier:(NSString *)identifier;

+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier;

@end
