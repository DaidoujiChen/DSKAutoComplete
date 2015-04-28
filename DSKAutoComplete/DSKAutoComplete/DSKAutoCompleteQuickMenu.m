//
//  DSKAutoCompleteQuickMenu.m
//  DSKAutoComplete
//
//  Created by daisuke on 2015/4/23.
//  Copyright (c) 2015年 guante_lu. All rights reserved.
//

#import "DSKAutoCompleteQuickMenu.h"
#import <objc/runtime.h>

#define textFieldDic self.tfDictionary[NSValue(self.respondTextField)]

@interface DSKAutoCompleteQuickMenu ()
@property (nonatomic, strong) NSArray *array;
@end

@implementation DSKAutoCompleteQuickMenu

- (id)init {
	self = [super init];
	if (self) {
		self.tfDictionary = [NSMutableDictionary dictionary];
	}
	return self;
}

#pragma mark - instance method

- (void)setTableviewStyleDropDown:(UITextField *)textField delegate:(id <DSKAutoCompleteQuickMenuDelegate> )delegate {
	[self setTableviewWithTextField:textField delegate:delegate isStyleDropDown:YES];
}

- (void)setTableviewStyleKeyboard:(UITextField *)textField delegate:(id <DSKAutoCompleteQuickMenuDelegate> )delegate {
	[self setTableviewWithTextField:textField delegate:delegate isStyleDropDown:NO];
}

- (void)tableViewDropDownAnimateHidden {
	__weak typeof(self) weakSelf = self;

	[UIView animateWithDuration:0.2
	                 animations: ^{
	    CGRect newFrame = weakSelf.tableView.frame;
	    newFrame.size.height = 0;
	    weakSelf.tableView.frame = newFrame;
	}
	                 completion: ^(BOOL finished) {
	}];
}

- (void)upDateReload {
	if (self.respondTextField.text.length != 0) {
		//用來保存需要的 key。
		NSMutableDictionary *cacheDic = [NSMutableDictionary dictionaryWithDictionary:textFieldDic[@"dataSource"]];

		__weak typeof(self) weakSelf = self;

		[textFieldDic[@"dataSource"] keysOfEntriesPassingTest: ^(id key, NSDictionary *info, BOOL *stop) {
		    //建立模糊搜尋語法。
		    NSString *predicateStr = @"SELF like[cd] '*";
		    for (int i = 0; i < weakSelf.respondTextField.text.length; i++) {
		        predicateStr = [NSString stringWithFormat:@"%@%@*", predicateStr, [weakSelf.respondTextField.text substringWithRange:NSMakeRange(i, 1)]];
			}
		    predicateStr = [NSString stringWithFormat:@"%@'", predicateStr];
		    NSPredicate *pred = [NSPredicate predicateWithFormat:predicateStr];

		    //模糊搜尋 array 裡的每個 string，count > 0 表示這個 key 是需要的。
		    if ([[info[@"item"] filteredArrayUsingPredicate:pred] count] > 0) {
		        return YES;
			}

		    //模糊搜尋找不到，移除這個 key。
		    [cacheDic removeObjectForKey:key];
		    return NO;
		}];

		//將所有 key 按照權重排序。
		if ([cacheDic allKeys] > 0) {
			NSArray *sortedKeys = [cacheDic keysSortedByValueUsingComparator: ^NSComparisonResult (id obj1, id obj2) {
			    return [obj2[@"weight"] compare:obj1[@"weight"]];
			}];
			self.array = sortedKeys;
		}
	}
	else {
		self.array = [NSArray array];
	}
	[self.tableView reloadData];
}

#pragma mark - private method

- (void)setTableviewWithTextField:(UITextField *)textField delegate:(id <DSKAutoCompleteQuickMenuDelegate> )delegate isStyleDropDown:(BOOL)isDropDown {
	self.delegate = delegate;

	[self.tableView removeFromSuperview];
	self.tableView = nil;
	self.tableView = [UITableView new];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.layer.borderWidth = 0.5;
	self.tableView.layer.cornerRadius = 5.0;
	self.tableView.layer.borderColor = [UIColor grayColor].CGColor;
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.respondTextField = textField;
	self.respondTextField.returnKeyType = UIReturnKeyDone;
	self.respondTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	self.respondTextField.autocorrectionType = UITextAutocorrectionTypeNo;

	//按照 Style 設置 tableView
	CGRect newFrame = textField.frame;
	if (isDropDown) {
		newFrame.origin.y += textField.frame.size.height - 3;
		newFrame.size.height = 0;
		self.tableView.frame = newFrame;

		[textField.superview addSubview:self.tableView];
		[textField.superview bringSubviewToFront:textField];
		[self tableViewDropDownAnimateShow];
	}
	else {
		newFrame.size.height = DSKQuicklyMenuHeight;
		self.tableView.frame = newFrame;
		self.respondTextField.inputAccessoryView = self.tableView;
	}
	[self upDateReload];
}

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

- (void)tableViewDropDownAnimateShow {
	__weak typeof(self) weakSelf = self;

	[UIView animateWithDuration:0.2
	                 animations: ^{
	    CGRect newFrame = weakSelf.tableView.frame;
	    newFrame.size.height = DSKQuicklyMenuHeight;
	    weakSelf.tableView.frame = newFrame;
	}
	                 completion: ^(BOOL finished) {
	}];
}

#pragma mark - tableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.delegate tableViewDidSelect:self.array[indexPath.row]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 30;
}

#pragma mark - tableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellIdentifier = @"DSKAutoCompleteQuickMenu";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	if (self.respondTextField.text.length != 0) {
		NSAttributedString *colorString = [self drawColorString:self.array[indexPath.row]
		                                             ruleString:self.respondTextField.text];
		[cell.textLabel setAttributedText:colorString];
	}
	else {
		cell.textLabel.textColor = [UIColor blackColor];
		cell.textLabel.text = self.array[indexPath.row];
	}
	return cell;
}

@end