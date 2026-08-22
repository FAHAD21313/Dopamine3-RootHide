/*
 * roothide jbroot/jbrand layer — public API
 * Ported from roothide/Bootstrap utils.h (G43: unified in libjailbreak)
 */
#ifndef LJB_JBRAND_H
#define LJB_JBRAND_H

#import <Foundation/Foundation.h>

uint64_t jbrand_new(void);
int is_jbrand_value(uint64_t value);
int is_jbroot_name(const char* name);
uint64_t resolve_jbrand_value(const char* name);
NSString* find_jbroot(BOOL force);
const char* jbroot(const char* path);
NSString* jbroot_ns(NSString *path);
uint64_t jbrand(void);
NSString* rootfsPrefix(NSString* path);

#endif
