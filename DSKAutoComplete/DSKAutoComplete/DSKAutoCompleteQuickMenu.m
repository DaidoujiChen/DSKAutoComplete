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
	//長度大於零才搜尋
	if ([self currentTextField].text.length > 0) {
		//建立模糊搜尋語法。
		NSPredicate *pred = [NSPredicate predicateWithFormat:[self predicateStr]];

		NSMutableDictionary *cacheDic = [NSMutableDictionary dictionaryWithDictionary:dataSource];
		[cacheDic enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
		    //搜尋 key 底下所有 value，count 等於零表示沒有搜尋到所以將其移除。
		    if ([obj[@"tags"] filteredArrayUsingPredicate:pred].count == 0) {
		        [cacheDic removeObjectForKey:key];
			}
		}];

		//取 dictionary 所有 key，大於零才做排序（按照權重排序）。
		if (cacheDic.allKeys > 0) {
			self.results = [self sortAllKeys:cacheDic];
		}
	}

	dispatch_async(dispatch_get_main_queue(), ^{
        //在最後做確認動作
		if ([self currentTextField].text.length == 0) {
		    self.results = [NSArray array];
		}
		[self.quickMenu reloadData];
	});
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

#pragma mark - refreshDataUsing private method

- (NSArray *)sortAllKeys:(NSMutableDictionary *)cacheDic {
	return [cacheDic keysSortedByValueUsingComparator: ^NSComparisonResult (id obj1, id obj2) {
	    return [obj2[@"weight"] compare:obj1[@"weight"]];
	}];
}

- (NSString *)predicateStr {
	NSString *predicateStr = @"SELF like[cd] '*";
	for (int i = 0; i < self.currentTextField.text.length; i++) {
		predicateStr = [NSString stringWithFormat:@"%@%@*", predicateStr, [[self currentTextField].text substringWithRange:NSMakeRange(i, 1)]];
	}
	predicateStr = [NSString stringWithFormat:@"%@'", predicateStr];
	return predicateStr;
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
