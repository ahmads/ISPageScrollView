//
//  ISPageScrollView.m
//
//  Copyright (c) 2013 Zhang Zonghui
//  Edited by Jos Kuijpers
//  Edited by Ahmad Salman
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

#import "ISPageScrollView.h"

@interface ISPageScrollView () <UIScrollViewDelegate>

- (void)setupScrollViewForDisplayingPage:(NSInteger)pageIndex
								animated:(BOOL)animated;
@end

@implementation ISPageScrollView {
    NSInteger _minReusablePageIndex;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.delegate = self;
        [self setPagingEnabled:YES];
        [self setBounces:NO];
        [self setShowsHorizontalScrollIndicator:NO];
        
        _scrollViewAvailablePages = [@{} mutableCopy];
        _numberOfReusableControllers = 0;
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.delegate = self;
    [self setPagingEnabled:YES];
    [self setBounces:NO];
    [self setShowsHorizontalScrollIndicator:NO];
    
    _scrollViewAvailablePages = [@{} mutableCopy];
    _numberOfReusableControllers = 0;    
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger currentPage = scrollView.contentOffset.x / scrollView.frame.size.width + _minReusablePageIndex;
    
    [self setupScrollViewForDisplayingPage:currentPage animated:NO];
}


#pragma mark - Private methods

- (void)displayPage:(NSInteger)pageIndex
{
    [self setupScrollViewForDisplayingPage:pageIndex animated:YES];
}

- (void)setupScrollViewForDisplayingPage:(NSInteger)pageIndex
								animated:(BOOL)animated
{
	NSInteger numberOfPages = [_dataSource numberOfPagesForPageScrollView:self];
	if(numberOfPages < self.numberOfReusableControllers)
		self.numberOfReusableControllers = numberOfPages;

    NSInteger minPageIndex = MAX(0, pageIndex - (_numberOfReusableControllers - 1) / 2.0);
    NSInteger maxPageIndex = MIN(numberOfPages, pageIndex + (_numberOfReusableControllers - 1) / 2.0);
    
    // remove unused controllers
    for ( NSNumber *pageIndex in _scrollViewAvailablePages.allKeys )
    {
        if ( pageIndex.integerValue < minPageIndex || pageIndex.integerValue > maxPageIndex )
        {
			if([_pageDelegate respondsToSelector:@selector(pageScrollView:willRemoveController:atPage:)])
				[_pageDelegate pageScrollView:self
							   willRemoveController:_scrollViewAvailablePages[pageIndex]
									   atPage:pageIndex.integerValue];
									   
			UIViewController *controllerToRemove = _scrollViewAvailablePages[pageIndex];
			[controllerToRemove.view removeFromSuperview];
			[controllerToRemove removeFromParentViewController];
			
			[_scrollViewAvailablePages removeObjectForKey:pageIndex];
						
			if([_pageDelegate respondsToSelector:@selector(pageScrollView:didRemoveControllerAtPage:)])
				[_pageDelegate pageScrollView:self
						  didRemoveControllerAtPage:pageIndex.integerValue];
        }
    }
    
    // add in new controllers
	for ( NSInteger i = minPageIndex; i <= maxPageIndex; i++ )
    {
    	UIViewController *controllerForPage = _scrollViewAvailablePages[@(i)];
    	if ( controllerForPage == nil )
    	{
    		controllerForPage = [self.dataSource controllerForScrollView:self page:i];
    		[self addSubview:controllerForPage.view];
    		[((UIViewController *)self.dataSource) addChildViewController: controllerForPage];
    		[_scrollViewAvailablePages setObject:controllerForPage forKey:@(i)];
    	}
    	
    	controllerForPage.view.frame = CGRectMake((i - minPageIndex) * self.frame.size.width, 0, controllerForPage.view.frame.size.width, controllerForPage.view.frame.size.height);
    }
    
    self.contentOffset = CGPointMake(self.frame.size.width * (pageIndex - minPageIndex), 0);
    self.contentSize = CGSizeMake(self.frame.size.width * (maxPageIndex - minPageIndex + 1), self.frame.size.height);
    _minReusablePageIndex = minPageIndex;
	
	if([_pageDelegate respondsToSelector:@selector(pageScrollView:didShowPage:)])
		[_pageDelegate pageScrollView:self didShowPage:pageIndex];
    _currentPageIndex = pageIndex;
}


@end
