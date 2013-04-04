//
// RETableViewManager.m
// RETableViewManager
//
// Copyright (c) 2013 Roman Efimov (https://github.com/romaonthego)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "RETableViewManager.h"

@implementation RETableViewManager

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    
    _sections = [[NSMutableArray alloc] init];
    _mapping = [[NSMutableDictionary alloc] init];
    _style = [[RETableViewCellStyle alloc] init];
    
    [self setDefaultMapping];
    
    return self;
}

- (id)initWithDelegate:(id<RETableViewManagerDelegate>)delegate
{
    self = [self init];
    if (!self)
        return nil;
    
    self.delegate = delegate;
    
    return self;
}

- (void)setDefaultMapping
{
    [self mapObjectClass:@"__NSCFConstantString" toTableViewCellClass:@"RETableViewStringCell"];
    [self mapObjectClass:@"__NSCFString" toTableViewCellClass:@"RETableViewStringCell"];
    [self mapObjectClass:@"NSString" toTableViewCellClass:@"RETableViewStringCell"];
    [self mapObjectClass:@"RETableViewItem" toTableViewCellClass:@"RETableViewStringCell"];
    [self mapObjectClass:@"RERadioItem" toTableViewCellClass:@"RETableViewStringCell"];
    [self mapObjectClass:@"REBoolItem" toTableViewCellClass:@"RETableViewBoolCell"];
    [self mapObjectClass:@"RETextItem" toTableViewCellClass:@"RETableViewTextCell"];
    [self mapObjectClass:@"RENumberItem" toTableViewCellClass:@"RETableViewNumberCell"];
    [self mapObjectClass:@"RECreditCardItem" toTableViewCellClass:@"RETableViewCreditCardCell"];
}

- (void)mapObjectClass:(NSString *)objectClass toTableViewCellClass:(NSString *)cellViewClass
{
    [_mapping setObject:cellViewClass forKey:objectClass];
}

- (Class)classForCellAtIndexPath:(NSIndexPath *)indexPath
{
    RETableViewSection *section = [_sections objectAtIndex:indexPath.section];
    NSObject *item = [section.items objectAtIndex:indexPath.row];
    Class cellClass;
    for (NSString *className in _mapping) {
        NSString *itemClass = NSStringFromClass([item class]);
        if ([itemClass isEqualToString:className]) {
            cellClass = NSClassFromString([_mapping objectForKey:className]);
            break;
        }
    }
    return cellClass;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    RETableViewSection *section = [_sections objectAtIndex:sectionIndex];
    return section.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RETableViewSection *section = [_sections objectAtIndex:indexPath.section];
    RETableViewItem *item = [section.items objectAtIndex:indexPath.row];
    
    UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
    if ([item isKindOfClass:[RETableViewItem class]])
        cellStyle = ((RETableViewItem *)item).cellStyle;
    
    NSString *cellIdentifier = [NSString stringWithFormat:@"RETableViewManager_%@_%i", [item class], cellStyle];
  
    Class cellClass = [self classForCellAtIndexPath:indexPath];
    
    RETableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[cellClass alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier tableViewManager:self];
    }
    
    cell.row = indexPath.row;
    cell.sectionIndex = indexPath.section;
    cell.parentTableView = tableView;
    cell.section = section;
    cell.item = item;
    cell.detailTextLabel.text = nil;
    
    if ([item isKindOfClass:[RETableViewItem class]])
        cell.detailTextLabel.text = ((RETableViewItem *)item).detailLabelText;
    [cell prepare];
    
    if ([_delegate respondsToSelector:@selector(tableView:styleCell:atIndexPath:)])
        [_delegate tableView:tableView styleCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    RETableViewSection *section = [_sections objectAtIndex:indexPath.section];
    id item = [section.items objectAtIndex:indexPath.row];
    return [[self classForCellAtIndexPath:indexPath] heightWithItem:item tableViewManager:self];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex
{
    RETableViewSection *section = [_sections objectAtIndex:sectionIndex];
    return section.headerTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)sectionIndex
{
    RETableViewSection *section = [_sections objectAtIndex:sectionIndex];
    return section.footerTitle;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)sectionIndex
{
    RETableViewSection *section = [_sections objectAtIndex:sectionIndex];
    return section.headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)sectionIndex
{
    RETableViewSection *section = [_sections objectAtIndex:sectionIndex];
    return section.footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)sectionIndex
{
    RETableViewSection *section = [_sections objectAtIndex:sectionIndex];
    if (section.headerView)
        return section.headerView.frame.size.height;
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)sectionIndex
{
    RETableViewSection *section = [_sections objectAtIndex:sectionIndex];
    if (section.footerView)
        return section.footerView.frame.size.height;
    return UITableViewAutomaticDimension;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RETableViewSection *section = [_sections objectAtIndex:indexPath.section];
    id item = [section.items objectAtIndex:indexPath.row];
    if ([item respondsToSelector:@selector(setActionBlock:)]) {
        RETableViewItem *actionItem = (RETableViewItem *)item;
        if (actionItem.actionBlock && actionItem.performActionOnSelection)
            actionItem.actionBlock(item);
    }
    
    if ([_delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
        [_delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    if ([_delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:item:)])
        [_delegate tableView:tableView didSelectRowAtIndexPath:indexPath item:item];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    RETableViewSection *section = [_sections objectAtIndex:indexPath.section];
    id item = [section.items objectAtIndex:indexPath.row];
    if ([item respondsToSelector:@selector(setActionBlock:)]) {
        RETableViewItem *actionItem = (RETableViewItem *)item;
        if (actionItem.accessoryButtonActionBlock)
            actionItem.accessoryButtonActionBlock(item);
    }
    
    if ([_delegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)])
        [_delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    
    if ([_delegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:item:)])
        [_delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath item:item];
}

#pragma mark -
#pragma mark Managing sections

- (void)addSection:(RETableViewSection *)section
{
    section.tableViewManager = self;
    [_sections addObject:section];
}

- (void)addSectionsFromArray:(NSArray *)array
{
    for (RETableViewSection *section in array)
        section.tableViewManager = self;
    [_sections addObjectsFromArray:array];
}

- (void)insertSection:(RETableViewSection *)section atIndex:(NSUInteger)index
{
    section.tableViewManager = self;
    [_sections insertObject:section atIndex:index];
}

- (void)insertSections:(NSArray *)sections atIndexes:(NSIndexSet *)indexes
{
    for (RETableViewSection *section in sections)
        section.tableViewManager = self;
    [_sections insertObjects:sections atIndexes:indexes];
}

- (void)removeSection:(RETableViewSection *)section
{
    [_sections removeObject:section];
}

- (void)removeAllSections
{
    [_sections removeAllObjects];
}

- (void)removeSectionIdenticalTo:(RETableViewSection *)section inRange:(NSRange)range
{
    [_sections removeObjectIdenticalTo:section inRange:range];
}

- (void)removeSectionIdenticalTo:(RETableViewSection *)section
{
    [_sections removeObjectIdenticalTo:section];
}

- (void)removeSectionsInArray:(NSArray *)otherArray
{
    [_sections removeObjectsInArray:otherArray];
}

- (void)removeSectionsInRange:(NSRange)range
{
    [_sections removeObjectsInRange:range];
}

- (void)removeSection:(RETableViewSection *)section inRange:(NSRange)range
{
    [_sections removeObject:section inRange:range];
}

- (void)removeLastSection
{
    [_sections removeLastObject];
}

- (void)removeSectionAtIndex:(NSUInteger)index
{
    [_sections removeObjectAtIndex:index];
}

- (void)removeSectionsAtIndexes:(NSIndexSet *)indexes
{
    [_sections removeObjectsAtIndexes:indexes];
}

- (void)replaceSectionAtIndex:(NSUInteger)index withSection:(RETableViewSection *)section
{
    section.tableViewManager = self;
    [_sections replaceObjectAtIndex:index withObject:section];
}

- (void)replaceSectionsAtIndexes:(NSIndexSet *)indexes withSections:(NSArray *)sections
{
    for (RETableViewSection *section in sections)
        section.tableViewManager = self;
    [_sections replaceObjectsAtIndexes:indexes withObjects:sections];
}

- (void)replaceSectionsInRange:(NSRange)range withSectionsFromArray:(NSArray *)otherArray range:(NSRange)otherRange
{
    for (RETableViewSection *section in otherArray)
        section.tableViewManager = self;
    [_sections replaceObjectsInRange:range withObjectsFromArray:otherArray range:otherRange];
}

- (void)replaceSectionsInRange:(NSRange)range withObjectsFromArray:(NSArray *)otherArray
{
    [_sections replaceObjectsInRange:range withObjectsFromArray:otherArray];
}

- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2
{
    [_sections exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
}

- (void)sortSectionsUsingFunction:(NSInteger (*)(id, id, void *))compare context:(void *)context
{
    [_sections sortUsingFunction:compare context:context];
}

- (void)sortSectionsUsingSelector:(SEL)comparator
{
    [_sections sortUsingSelector:comparator];
}

@end
