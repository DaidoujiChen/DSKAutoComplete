//
//  DSKAutoCompleteQuickMenu.m
//  DSKAutoComplete
//
//  Created by daisuke on 2015/4/23.
//  Copyright (c) 2015年 guante_lu. All rights reserved.
//

#import "DSKAutoCompleteQuickMenu.h"
#import <objc/runtime.h>

#define DSKQuicklyMenuHeight 90

@interface DSKAutoCompleteQuickMenu ()
@property (nonatomic, strong) NSArray *results;
@end

@implementation DSKAutoCompleteQuickMenu

- (UITextField *)currentTextField {
    return (UITextField *)self.delegate;
}

#pragma mark - instance method

- (void)tableviewWithStyle:(DSKAutoCompleteStyle)style {
	[self.quickMenu removeFromSuperview];
	self.quickMenu = nil;
	self.quickMenu = [UITableView new];
	self.quickMenu.delegate = self;
	self.quickMenu.dataSource = self;
	self.quickMenu.layer.borderWidth = 0.5;
	self.quickMenu.layer.cornerRadius = 5.0;
	self.quickMenu.layer.borderColor = [UIColor grayColor].CGColor;
	self.quickMenu.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.quickMenu registerClass:[UITableViewCell class] forCellReuseIdentifier:@"DSKAutoCompleteQuickMenu"];
}

- (void)hidden {
    NSAssert(0, @"you must override this method");
}

- (void)show {
    NSAssert(0, @"you must override this method");
}

- (void)refreshDataUsing:(NSMutableDictionary *)dataSource {
	if ([self currentTextField].text.length != 0) {
		//用來保存需要的 key。
		NSMutableDictionary *cacheDic = [NSMutableDictionary dictionaryWithDictionary:dataSource];

		__weak typeof(self) weakSelf = self;

		[dataSource keysOfEntriesPassingTest: ^(id key, NSDictionary *info, BOOL *stop) {
		    //建立模糊搜尋語法。
		    NSString *predicateStr = @"SELF like[cd] '*";
		    for (int i = 0; i < weakSelf.currentTextField.text.length; i++) {
		        predicateStr = [NSString stringWithFormat:@"%@%@*", predicateStr, [[weakSelf currentTextField].text substringWithRange:NSMakeRange(i, 1)]];
			}
		    predicateStr = [NSString stringWithFormat:@"%@'", predicateStr];
		    NSPredicate *pred = [NSPredicate predicateWithFormat:predicateStr];

		    //模糊搜尋 array 裡的每個 string，count > 0 表示這個 key 是需要的。
		    if ([info[@"item"] filteredArrayUsingPredicate:pred].count > 0) {
		        return YES;
			}

		    //模糊搜尋找不到，移除這個 key。
		    [cacheDic removeObjectForKey:key];
		    return NO;
		}];

		//將所有 key 按照權重排序。
		if (cacheDic.allKeys > 0) {
			NSArray *sortedKeys = [cacheDic keysSortedByValueUsingComparator: ^NSComparisonResult (id obj1, id obj2) {
			    return [obj2[@"weight"] compare:obj1[@"weight"]];
			}];
			self.results = sortedKeys;
		}
	}
	else {
		self.results = [NSArray array];
	}
	[self.quickMenu reloadData];
}

#pragma mark - private method

- (NSMutableAttributedString *)drawColorString:(NSString *)oStr ruleString:(NSString *)rStr {
	NSMutableAttributedString *dataStr = [[NSMutableAttributedString alloc] initWithString:oStr];

	//將規則字串拆開
	NSMutableArray *array = [NSMutableArray array];
	for (int i = 0; i < rStr.length; i++) {
		[array addObject:[rStr substringWithRange:NSMakeRange(i, 1)]];
	}

	int rStrIndex = 0; //規則字串的單字索引

	for (int i = 0; i < oStr.length; i++) {
		//比較兩個字是否一樣，一樣就上色。
		if ([[oStr substringWithRange:NSMakeRange(i, 1)] caseInsensitiveCompare:array[rStrIndex]] == NSOrderedSame) {
			NSRange range = NSMakeRange(i, 1);
			[dataStr addAttribute:NSForegroundColorAttributeName
			                value:[UIColor redColor]
			                range:NSMakeRange(range.location, range.length)];
			rStrIndex++;
		}

		//規則字串的單字索引等於規則字串就返回
		if (rStrIndex == rStr.length) {
			break;
		}
	}
	return dataStr;
}

#pragma mark - tableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.delegate tableViewDidSelect:self.results[indexPath.row]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *headerView = [UIView new];
	headerView.backgroundColor = [UIColor clearColor];
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 5;
}

#pragma mark - tableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.results.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"DSKAutoCompleteQuickMenu";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
	if ([self currentTextField].text.length != 0) {
		NSAttributedString *colorString = [self drawColorString:self.results[indexPath.row]
		                                             ruleString:[self currentTextField].text];
		cell.textLabel.attributedText = colorString;
	}
	else {
		cell.textLabel.textColor = [UIColor blackColor];
		cell.textLabel.text = self.results[indexPath.row];
	}
	return cell;
}

@end
