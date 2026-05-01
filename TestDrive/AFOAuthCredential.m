//
//  AFOAuthCredential.m
//  Fetch
//
//  Created by Amanuel Ayele on 4/1/14.
//  Copyright (c) 2016 Fetch, Inc. All rights reserved.
//
#include <UIKit/UIKit.h>

#import "AFOAuthCredential.h"

#ifdef _SECURITY_SECITEM_H_

// this constant needs to remain the same throughout app upgrades
NSString * const kFRCredentialStoreIdentifier = @"AFOAuthCredentialService";
NSString * const keychainAccessGroupOBJC = @"UIKitTesting.fetchrewards.fetch";

static NSMutableDictionary * keychainQueryDictionaryWithIdentifier(NSString *identifier) {
    NSMutableDictionary *queryDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            (__bridge id)kSecClassGenericPassword, kSecClass,
//                                            keychainAccessGroupOBJC, kSecAttrAccessGroup,
                                            kFRCredentialStoreIdentifier, kSecAttrService,
                                            nil];
    
    // this tells the difference between environments
    [queryDictionary setValue:identifier forKey:(__bridge id)kSecAttrAccount];

    return queryDictionary;
}

#endif

@interface AFOAuthCredential ()
@property (readwrite, nonatomic) NSString *accessToken;
@property (readwrite, nonatomic) NSString *refreshToken;
@property (readwrite, nonatomic) NSString *accessExpiration;
@property (readwrite, nonatomic) NSString *refreshExpiration;
@property (readwrite, nonatomic) NSString *userId;
@property (readwrite, nonatomic) NSString *authSource;
@end

@implementation AFOAuthCredential


- (id)initWithAccessToken:(NSString *)accessToken
             refreshToken:(NSString *)refreshToken
             accessExpireDate:(NSString*)accessExpireDate
             refreshExpireDate:(NSString*)refreshExpireDate
             userId:(NSString*)userId
             authSource:(NSString*)authSource {
    if (self = [super init]) {
        self.accessToken = accessToken;
        self.refreshToken = refreshToken;
        self.accessExpiration = accessExpireDate;
        self.refreshExpiration = refreshExpireDate;
        self.userId = userId;
        self.authSource = authSource;
    }
    return self;
}

- (id)initWithAccessToken:(NSString *)accessToken
             refreshToken:(NSString *)refreshToken
             accessExpireDate:(NSString*)accessExpireDate
             refreshExpireDate:(NSString*)refreshExpireDate
             userId:(NSString*)userId
             authSource:(NSString*)authSource
     createdUserIndicator:(BOOL)createdUserIndicator{
    if (self = [super init]) {
        self.accessToken = accessToken;
        self.refreshToken = refreshToken;
        self.accessExpiration = accessExpireDate;
        self.refreshExpiration = refreshExpireDate;
        self.userId = userId;
        self.authSource = authSource;
        self.createdUserIndicator = createdUserIndicator;
    }
    return self;
}

+ (BOOL)storeCredential:(AFOAuthCredential *)credential
         withIdentifier:(NSString *)identifier{
    
    NSMutableDictionary *queryDictionary = keychainQueryDictionaryWithIdentifier(identifier);
    
    // setting credential to nil, just delete it and return
    if (!credential) {
        return [self deleteCredentialWithIdentifier:identifier];
    }
    
    NSMutableDictionary *updateDictionary = [NSMutableDictionary dictionary];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:credential requiringSecureCoding:NO error:nil];
    [updateDictionary setObject:data forKey:(__bridge id)kSecValueData];
    updateDictionary[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;

    OSStatus status;
    BOOL exists = ([self retrieveCredentialWithIdentifier:identifier] != nil);
    
    if (exists) {
        status = SecItemUpdate((__bridge CFDictionaryRef)queryDictionary, (__bridge CFDictionaryRef)updateDictionary);
    } else {
        [queryDictionary addEntriesFromDictionary:updateDictionary];
        status = SecItemAdd((__bridge CFDictionaryRef)queryDictionary, NULL);
    }
    
    if (status != errSecSuccess) {
        NSLog(@"Unable to %@ credential with identifier \"%@\" (Error %li)", exists ? @"update" : @"add", identifier, (long int)status);
    } else {
        NSLog(@"Post notification refreshed");
    }
    
    return (status == errSecSuccess);
}

+ (AFOAuthCredential *)retrieveCredentialWithIdentifier:(NSString *)identifier{
    
    NSMutableDictionary *queryDictionary = keychainQueryDictionaryWithIdentifier(identifier);
    [queryDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [queryDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    CFDataRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)queryDictionary, (CFTypeRef *)&result);
    
    if (status != errSecSuccess) {
        if (status != errSecItemNotFound) {
            NSLog(@"Unable to fetch credential with identifier \"%@\" (Error %li)", identifier, (long int)status);
        }
        return nil;
    }
    
    NSData *data = (__bridge_transfer NSData *)result;
    AFOAuthCredential *credential = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSLog(@"Have credential");
    NSLog(@"Have credential, %@", credential.userId);

    
    if (credential.userId==nil) {
        NSLog(@"Credential userID is nil");
        [self deleteCredentialWithIdentifier:identifier];
        NSLog(@"Finished deletion");
        return nil;
     }
    
    NSLog(@"Set UserManager.currentUser.authSource");
    
    return credential;
}

+ (BOOL)deleteCredentialWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *queryDictionary = keychainQueryDictionaryWithIdentifier(identifier);
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)queryDictionary);
    
    if (status != errSecSuccess) {
        if (status != errSecItemNotFound) {
            NSLog(@"Unable to delete credential with identifier \"%@\" (Error %li)", identifier, (long int)status);
        }
    }
    
    return (status == errSecSuccess);
}

- (NSString *)description{
    NSDictionary *dict = @{@"accessToken"  : self.accessToken,
                           @"refreshToken" : self.refreshToken,
                           @"accessExpiration" : self.accessExpiration,
                           @"refreshExpiration" : self.refreshExpiration,
                           @"userId" : self.userId,
                           @"authSource" : self.authSource};

    return dict.description;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    self.accessToken = [decoder decodeObjectForKey:@"accessToken"];
    self.refreshToken = [decoder decodeObjectForKey:@"refreshToken"];
    self.accessExpiration = [decoder decodeObjectForKey:@"accessExpiration"];
    self.refreshExpiration = [decoder decodeObjectForKey:@"refreshExpiration"];
    self.userId = [decoder decodeObjectForKey:@"userId"];
    self.authSource = [decoder decodeObjectForKey:@"authSource"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.accessToken forKey:@"accessToken"];
    [encoder encodeObject:self.refreshToken forKey:@"refreshToken"];
    [encoder encodeObject:self.accessExpiration forKey:@"accessExpiration"];
    [encoder encodeObject:self.refreshExpiration forKey:@"refreshExpiration"];
    [encoder encodeObject:self.userId forKey:@"userId"];
    [encoder encodeObject:self.authSource forKey:@"authSource"];
}

@end

