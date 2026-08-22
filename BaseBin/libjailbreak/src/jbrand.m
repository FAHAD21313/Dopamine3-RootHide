/*
 * roothide jbroot/jbrand layer — ported from roothide/Bootstrap utils.m
 * and Dopamine2-roothide DOBootstrapper.m into libjailbreak.
 *
 * G43: single source of truth — the App and daemons query this via jbclient
 * instead of each carrying its own copy.
 */

#import <Foundation/Foundation.h>
#include <stdlib.h>
#include <string.h>
#include "jbserver.h"
#include "info.h"

uint64_t jbrand_new(void)
{
	uint64_t value = ((uint64_t)arc4random()) | ((uint64_t)arc4random())<<32;
	uint8_t check = value>>8 ^ value>>16 ^ value>>24 ^ value>>32 ^ value>>40 ^ value>>48 ^ value>>56;
	return (value & ~0xFF) | check;
}

int is_jbrand_value(uint64_t value)
{
	uint8_t check = value>>8 ^ value>>16 ^ value>>24 ^ value>>32 ^ value>>40 ^ value>>48 ^ value>>56;
	return check == (uint8_t)value;
}

#define JB_ROOT_PREFIX ".jbroot-"
#define JB_RAND_LENGTH (sizeof(uint64_t)*sizeof(char)*2)

int is_jbroot_name(const char* name)
{
	if(strlen(name) != (sizeof(JB_ROOT_PREFIX)-1+JB_RAND_LENGTH))
		return 0;

	if(strncmp(name, JB_ROOT_PREFIX, sizeof(JB_ROOT_PREFIX)-1) != 0)
		return 0;

	char* endp=NULL;
	uint64_t value = strtoull(name+sizeof(JB_ROOT_PREFIX)-1, &endp, 16);
	if(!endp || *endp!='\0')
		return 0;

	return is_jbrand_value(value);
}

uint64_t resolve_jbrand_value(const char* name)
{
	if(!is_jbroot_name(name))
		return 0;

	char* endp=NULL;
	uint64_t value = strtoull(name+sizeof(JB_ROOT_PREFIX)-1, &endp, 16);
	if(!endp || *endp!='\0')
		return 0;

	return value;
}

NSString* find_jbroot(BOOL force)
{
	static NSString* cached_jbroot = nil;
	if(!force && cached_jbroot) {
		return cached_jbroot;
	}
	@synchronized(@"find_jbroot_lock")
	{
		//jbroot path may change when re-randomized
		NSString* jbroot = nil;
		NSArray *subItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/containers/Bundle/Application/" error:nil];
		for (NSString *subItem in subItems) {
			if (is_jbroot_name(subItem.UTF8String))
			{
				jbroot = [@"/var/containers/Bundle/Application/" stringByAppendingPathComponent:subItem];
				break;
			}
		}
		cached_jbroot = jbroot;
	}
	return cached_jbroot;
}

const char* jbroot(const char* path)
{
	NSString* jbrootPath = find_jbroot(NO);
	assert(jbrootPath != NULL);
	NSString* newpath = [jbrootPath stringByAppendingPathComponent:@(path)];

	@synchronized(@"jbroot_cache_lock")
	{
		static NSMutableSet* cache = nil;
		if(!cache) cache = [NSMutableSet new];

		[cache addObject:newpath];
		newpath = [cache member:newpath];
	}
	return newpath.fileSystemRepresentation;
}

NSString* jbroot_ns(NSString *path)
{
	NSString* jbrootPath = find_jbroot(NO);
	assert(jbrootPath != NULL);
	return [jbrootPath stringByAppendingPathComponent:path];
}

uint64_t jbrand(void)
{
	NSString* jbrootPath = find_jbroot(NO);
	assert(jbrootPath != NULL);
	return resolve_jbrand_value([jbrootPath lastPathComponent].UTF8String);
}

NSString* rootfsPrefix(NSString* path)
{
	// roothide: rootfs paths resolve through the secondary jbroot /private/var
	NSString* jbrootPath = find_jbroot(NO);
	return [[jbrootPath stringByAppendingPathComponent:@"private/var"] stringByAppendingPathComponent:path];
}
