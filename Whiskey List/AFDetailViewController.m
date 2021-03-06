//
//  AFDetailViewController.m
//  Whiskey List
//
//  Created by Ash Furrow on 2013-01-21.
//  Copyright (c) 2013 Ash Furrow. All rights reserved.
//

// Controllers
#import "AFDetailViewController.h"
#import "AFZoomedPhotoViewController.h"

// Models
#import "AFRegion.h"
#import "AFWhiskey.h"

// Views
#import "AFPhotoButton.h"
#import "AFNameSectionCell.h"
#import "AFDetailSectionCell.h"

enum {
    AFDetailViewControllerNameSection = 0,
    AFDetailViewControllerDetailsAgeSection,
    AFDetailViewControllerDetailsNoseSection,
    AFDetailViewControllerDetailsTasteSection,
    AFDetailViewControllerDetailsNotesSection,
    AFDetailViewControllerDetailsDeleteSection, //Fake section
    AFDetailViewControllerNumberOfSections
};

enum {
    AFDetailViewControllerNameSectionNameRow = 0,
    AFDetailViewControllerNameSectionRegionRow,
    AFDetailViewControllerNameSectionNumberOfRows
};

NSString * const AFModelRelationWasUpdatedNotification = @"AFModelRelationWasUpdatedNotification";

static NSString *NameRowCellIdentifier = @"NameRowCell";
static NSString *RegionRowCellIdentifier = @"RegionRowCellIdentifier";
static NSString *AgeRowCellIdentifier = @"AgeRowCellIdentifier";
static NSString *DetailRowCellIdentifier = @"DetailRowCellIdentifier";

@interface AFDetailViewController ()

@property (nonatomic, strong) NSString *savedName;
@property (nonatomic, strong) UIImage *savedImage;
@property (nonatomic, strong) AFRegion *savedRegion;
@property (nonatomic, strong) NSString *savedNose;
@property (nonatomic, strong) NSString *savedTaste;
@property (nonatomic, strong) NSString *savedNotes;
@property (nonatomic, assign) NSInteger savedAge;

@end

@implementation AFDetailViewController
{
    UIActionSheet *imageActionSheet;
    UIActionSheet *deletionActionSheet;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
//    [self.tableView registerClass:[AFNameSectionCell class] forCellReuseIdentifier:NameRowCellIdentifier];
//    [self.tableView registerClass:[AFNameSectionCell class] forCellReuseIdentifier:RegionRowCellIdentifier];
//    [self.tableView registerClass:[AFDetailSectionCell class] forCellReuseIdentifier:DetailRowCellIdentifier];
//    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:AgeRowCellIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextFieldChange:) name:UITextFieldTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextViewChange:) name:UITextViewTextDidChangeNotification object:nil];
    
    // Will be replaced later, if we have a detail item. 
    self.savedAge = 12;
    
    [self.tableView reloadData];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Show the keyboard while animating up the modal display
    if (self.creatingNewEntity)
    {
        [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] becomeFirstResponder];
    }
}

#pragma mark - Table View Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    
    return AFDetailViewControllerNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    if (section == AFDetailViewControllerNameSection)
    {
        return AFDetailViewControllerNameSectionNumberOfRows;
    }
    else if (section == AFDetailViewControllerDetailsNoseSection ||
             section == AFDetailViewControllerDetailsNotesSection ||
             section == AFDetailViewControllerDetailsTasteSection)
    {
        return 1;
    }
    else if (section == AFDetailViewControllerDetailsAgeSection)
    {
        return 1;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == AFDetailViewControllerDetailsNoseSection ||
        indexPath.section == AFDetailViewControllerDetailsNotesSection ||
        indexPath.section == AFDetailViewControllerDetailsTasteSection)
    {
        AFDetailSectionCell *cell = (AFDetailSectionCell *)[tableView dequeueReusableCellWithIdentifier:DetailRowCellIdentifier];
        
        if (!cell) cell = [[AFDetailSectionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AgeRowCellIdentifier];
        
        [self configureDetailCell:cell forIndexPath:indexPath];
        
        return cell;
    }
    else if (indexPath.section == AFDetailViewControllerDetailsAgeSection)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:AgeRowCellIdentifier];
        
        if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AgeRowCellIdentifier];
        
        [self configureAgeCell:cell forIndexPath:indexPath];
        
        return cell;
    }
    else if (indexPath.row == AFDetailViewControllerNameSectionNameRow)
    {
        AFNameSectionCell *cell = (AFNameSectionCell *)[tableView dequeueReusableCellWithIdentifier:NameRowCellIdentifier];
        
        if (!cell) cell = [[AFNameSectionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AgeRowCellIdentifier];
        
        [self configureNameSectionCell:cell forIndexPath:indexPath];
        
        return cell;
    }
    else if (indexPath.row == AFDetailViewControllerNameSectionRegionRow)
    {
        AFNameSectionCell *cell = (AFNameSectionCell *)[tableView dequeueReusableCellWithIdentifier:RegionRowCellIdentifier];
        
        if (!cell) cell = [[AFNameSectionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:AgeRowCellIdentifier];
        
        [self configureRegionCell:cell forIndexPath:indexPath];
        
        return cell;
    }
    
    NSAssert(NO, @"Table view data source did not return cell.");
    
    return nil;
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section != [tableView numberOfSections] - 1) return 0.0f;
    if (!self.editing || self.creatingNewEntity) return 0.0f;
    
    return 55.0f;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section != [tableView numberOfSections] - 1) return nil;
    if (!self.editing || self.creatingNewEntity) return nil;
    
    UIButton *delete = [UIButton buttonWithType:UIButtonTypeCustom];
    [delete addTarget:self action:@selector(confirmDeleteWhiskey:) forControlEvents:UIControlEventTouchUpInside];
    [delete setTitleShadowColor:[UIColor colorWithWhite:0.0f alpha:0.5f] forState:UIControlStateNormal];
    [delete.titleLabel setShadowOffset:CGSizeMake(0, -1)];
    [delete.titleLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [delete setBackgroundImage:[[UIImage imageNamed:@"delete"] resizableImageWithCapInsets:UIEdgeInsetsMake(10, 18, 0, 18)] forState:UIControlStateNormal];
    delete.titleEdgeInsets = UIEdgeInsetsMake(10, 0, 0, 0);
    delete.frame = CGRectMake(0, 0, 300, 55);
    
    delete.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [delete setTitle:NSLocalizedString(@"Delete Whiskey", @"") forState:UIControlStateNormal];
    
    return delete;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing) return YES;
    
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == AFDetailViewControllerDetailsNoseSection)
    {
        return NSLocalizedString(@"Nose", @"Nose section header text");
    }
    else if (section == AFDetailViewControllerDetailsNotesSection)
    {
        return NSLocalizedString(@"Notes", @"Notes section header text");
    }
    else if (section == AFDetailViewControllerDetailsTasteSection)
    {
        return NSLocalizedString(@"Taste", @"Taste section header text");
    }
    else if (section == AFDetailViewControllerDetailsAgeSection)
    {
        return NSLocalizedString(@"Age", @"Age section header text");
    }
    
    return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editing)
    {
        if (indexPath.row == AFDetailViewControllerNameSectionRegionRow && indexPath.section == AFDetailViewControllerNameSection)
        {
            AFRegionSelectViewController *viewController = [[AFRegionSelectViewController alloc] initWithStyle:UITableViewStylePlain];
            viewController.delegate = self;
            viewController.region = self.savedRegion;
            viewController.managedObjectContext = self.managedObjectContext;
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == AFDetailViewControllerDetailsNoseSection ||
        indexPath.section == AFDetailViewControllerDetailsNotesSection ||
        indexPath.section == AFDetailViewControllerDetailsTasteSection)
    {
        NSString *text;
        
        switch (indexPath.section) {
            case AFDetailViewControllerDetailsNoseSection:
                text = self.whiskey.nose;
                break;
            case AFDetailViewControllerDetailsNotesSection:
                text = self.whiskey.notes;
                break;
            case AFDetailViewControllerDetailsTasteSection:
                text = self.whiskey.taste;
                break;
        }
        
        CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:17] constrainedToSize:CGSizeMake(300, 1000) lineBreakMode:NSLineBreakByWordWrapping];
        
        return MAX(size.height + 20, 66.0f);
    }
    
    return 44.0f;
}

#pragma mark Copy Support

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == AFDetailViewControllerNameSectionRegionRow && indexPath.section == AFDetailViewControllerNameSection)
    {
        return self.whiskey.region != nil;
    }
    
    return !self.editing;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return !self.editing && [NSStringFromSelector(action) isEqualToString:@"copy:"];
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    NSString *text = @"";
    
    if (indexPath.section == AFDetailViewControllerNameSection)
    {
        if (indexPath.row == AFDetailViewControllerNameSectionNameRow)
        {
            text = self.whiskey.name;
        }
        else if (indexPath.row == AFDetailViewControllerNameSectionRegionRow)
        {
            text = self.whiskey.region.name;
        }
    }
    else if (indexPath.section == AFDetailViewControllerDetailsNoseSection)
    {
        text = self.whiskey.nose;
    }
    else if (indexPath.section == AFDetailViewControllerDetailsNotesSection)
    {
        text = self.whiskey.notes;
    }
    else if (indexPath.section == AFDetailViewControllerDetailsTasteSection)
    {
        text = self.whiskey.taste;
    }
    
    UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
    [pasteBoard setString:text];
}


#pragma mark - Overridden Properties

-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.photoButton.editing = self.editing;
    
    if (!editing)
    {
        if (self.whiskey)
        {
            [self updateItem];
        }
    }
    
    if (!self.creatingNewEntity)
    {
        if (self.isEditing)
        {
            [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(userDidCancelExistingItem:)] animated:YES];
        }
        else
        {
            [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        }
    }
    
    // Check to make sure we're on screen (this is called from viewDidLoad).
    if (self.view.window)
    {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:self.tableView.numberOfSections - 1] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)setWhiskey:(AFWhiskey *)newDetailItem
{
    if (_whiskey != newDetailItem) {
        self.savedRegion = [newDetailItem valueForKey:@"region"];
        self.savedName = newDetailItem.name;
        self.savedNose = newDetailItem.nose;
        self.savedNotes = newDetailItem.notes;
        self.savedAge = newDetailItem.age.integerValue;
        self.savedTaste = newDetailItem.taste;
        _whiskey = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

#pragma mark - User Interaction Methods

-(void)userDidTapEditPhotoButton:(id)sender
{
    if (self.editing)
    {
        BOOL hasExistingPhoto = [self.whiskey valueForKeyPath:@"image.imageData"] != nil;
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            //If this device has a camera, then present an action sheet
            
            if (hasExistingPhoto)
            {
                imageActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:NSLocalizedString(@"Delete Photo", @"") otherButtonTitles:NSLocalizedString(@"Take a Photo", @""), NSLocalizedString(@"Choose Existing Photo", @""), nil];
            }
            else
            {
                //If this device has a camera, then present an action sheet
                imageActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Take a Photo", @""), NSLocalizedString(@"Choose Existing Photo", @""), nil];
            }
            
            [imageActionSheet showInView:self.view];
        }
        else
        {
            if (hasExistingPhoto)
            {
                imageActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:NSLocalizedString(@"Delete Photo", @"") otherButtonTitles:NSLocalizedString(@"Choose Existing Photo", @""), nil];
                
                [imageActionSheet showInView:self.view];
            }
            else
            {
                //This device has no camera. Present the image picker now
                UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
                pickerController.delegate = self;
                pickerController.allowsEditing = YES;
                pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                
                [self presentViewController:pickerController animated:YES completion:nil];
            }
        }
    }
    else
    {
        if (self.photoButton.photo)
        {
            AFZoomedPhotoViewController *viewController = [[AFZoomedPhotoViewController alloc] init];
            viewController.image = self.photoButton.photo;
            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
}

-(void)userTappedAgeChanger:(id)sender
{
    self.savedAge = [(UIStepper *)sender value];
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:AFDetailViewControllerDetailsAgeSection]] withRowAnimation:UITableViewRowAnimationNone];
}

-(void)confirmDeleteWhiskey:(id)sender
{
    // Asks the user to confirm they want to delete the whiskey
    
    deletionActionSheet = [[UIActionSheet alloc] initWithTitle:@"Delete Whiskey?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:nil];
    [deletionActionSheet showInView:self.view];
}

-(void)deleteWhiskey
{
    // Called after confirmDeleteWhiskey: to confirm
    
    NSAssert(self.whiskey != nil, @"Tried to delete a nil detail item.");
    
    [[self.whiskey valueForKey:@"region"] removeWhiskiesObject:self.whiskey];
    [self.managedObjectContext deleteObject:self.whiskey];
    self.whiskey = nil;
    [self.navigationController popViewControllerAnimated:YES];
    [self saveContext];
}

-(void)userDidCancelNewItem:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)userDidCancelExistingItem:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)userDidFinish:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    [self insertNewObject];
}

#pragma mark - Private Custom Methods

#pragma mark UITableViewCell Cofiguration methods

-(void)configureNameSectionCell:(AFNameSectionCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.enableTextField = YES;
    
    cell.textFieldText = self.savedName;
    cell.textFieldPlaceholder = NSLocalizedString(@"Whiskey Name", @"");
}

-(void)configureAgeCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    UIStepper *stepper = [[UIStepper alloc] initWithFrame:CGRectZero];
    stepper.maximumValue = 1000;
    stepper.minimumValue = 1;
    stepper.value = self.savedAge;
    [stepper addTarget:self action:@selector(userTappedAgeChanger:) forControlEvents:UIControlEventValueChanged];
    
    cell.editingAccessoryView = stepper;
    
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d years", self.savedAge];
}

-(void)configureRegionCell:(AFNameSectionCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    cell.enableTextField = NO;
    
    NSString *regionName = self.savedRegion.name;
    
    cell.accessibilityHint = NSLocalizedString(@"Selects the region of the whiskey", @"region select cell accessbility hint");
    [[cell viewWithTag:100] setIsAccessibilityElement:NO];
    
    if (regionName.length > 0)
    {
        cell.textLabel.text = regionName;
        cell.textLabel.textColor = [UIColor blackColor];
    }
    else
    {
        cell.textLabel.text = NSLocalizedString(@"No Region", @"");
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
}

-(void)configureDetailCell:(AFDetailSectionCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == AFDetailViewControllerDetailsNoseSection)
    {
        cell.detailText = self.savedNose;
    }
    else if (indexPath.section == AFDetailViewControllerDetailsNotesSection)
    {
        cell.detailText = self.savedNotes;
    }
    else if (indexPath.section == AFDetailViewControllerDetailsTasteSection)
    {
        cell.detailText = self.savedTaste;
    }

    // 0 means "infinite"
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    cell.shouldIndentWhileEditing = NO;
}

#pragma mark NSNotificationCenter Methods

-(void)handleTextViewChange:(NSNotification *)notification
{
    UITextView *textView = (UITextView *)notification.object;
    
    if (![textView isDescendantOfView:self.view]) return;
    if (!self.editing) return;
    
    if ([textView isDescendantOfView:[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:AFDetailViewControllerDetailsNoseSection]]])
    {
        self.savedNose = textView.text;
    }
    else if ([textView isDescendantOfView:[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:AFDetailViewControllerDetailsNotesSection]]])
    {
        self.savedNotes = textView.text;
    }
    else if ([textView isDescendantOfView:[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:AFDetailViewControllerDetailsTasteSection]]])
    {
        self.savedTaste = textView.text;
    }
}

-(void)handleTextFieldChange:(NSNotification *)notification
{
    UITextField *textField = (UITextField *)notification.object;
    
    if (![textField isDescendantOfView:self.view]) return;
    if (!self.editing) return;
    
    self.navigationItem.rightBarButtonItem.enabled = [[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] > 0;
    self.savedName = textField.text;
}

#pragma mark Others

-(void)handleDeletionActionSheetButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == deletionActionSheet.destructiveButtonIndex)
    {
        [self deleteWhiskey];
    }
    
    deletionActionSheet = nil;
}

-(void)handleImageActionSheetButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == imageActionSheet.destructiveButtonIndex)
    {
        [self.photoButton setPhoto:nil];
        [[self.whiskey valueForKey:@"image"] setValue:nil forKey:@"imageData"];
        [self saveContext];
        
        return;
    }
    else if (buttonIndex == imageActionSheet.cancelButtonIndex)
    {
        return;
    }
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    pickerController.allowsEditing = YES;
    
    if (buttonIndex == imageActionSheet.firstOtherButtonIndex)
    {
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		{
			//Take new photo
			pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
			pickerController.showsCameraControls = YES;
			if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront])
			{
				pickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
			}
		}
		else
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot Take Photo", @"")
															message:NSLocalizedString(@"Unable to access the camera.", @"")
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
												  otherButtonTitles:nil];
			[alert show];
			return;
		}
    }
    else if (buttonIndex == 1)
    {
        //Choose existing photo
        pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    [self presentViewController:pickerController animated:YES completion:nil];
    
    imageActionSheet = nil;
}

-(void)saveContext
{
    // Save the context.
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

- (void)configureView
{
    self.photoButton = [AFPhotoButton buttonWithType:UIButtonTypeCustom];
    self.photoButton.frame = CGRectMake(10, 10, 90, 90);
    self.photoButton.accessibilityFrame = CGRectMake(10, 10, 90, 90);
    [self.photoButton addTarget:self action:@selector(userDidTapEditPhotoButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableView addSubview:self.photoButton];
    
    if (self.whiskey && !self.creatingNewEntity)
    {
        self.title = [self.whiskey valueForKey:@"name"];
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        self.editing = NO;
        
        [self.photoButton setPhoto:[UIImage imageWithData:[self.whiskey valueForKeyPath:@"image.imageData"]]];
        
        self.title = NSLocalizedString(@"Info", @"Detail edit default title");
    }
    else if (self.creatingNewEntity)
    {
        self.title = NSLocalizedString(@"New Whiskey", @"Detail default title");
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(userDidCancelNewItem:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(userDidFinish:)];
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        self.editing = YES;
    }
    
    self.tableView.allowsSelectionDuringEditing = YES;
    
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"subtle_stripes"] resizableImageWithCapInsets:UIEdgeInsetsZero]];
}

- (void)insertNewObject
{
    AFWhiskey *newWhiskeyObject = [NSEntityDescription insertNewObjectForEntityForName:@"Whiskey" inManagedObjectContext:self.managedObjectContext];
    
    NSString *name = self.savedName;
    
    [newWhiskeyObject setValue:name forKey:@"name"];
    [newWhiskeyObject setValue:[name lowercaseString] forKey:@"canonicalName"];
    newWhiskeyObject.nose = self.savedNose;
    newWhiskeyObject.notes = self.savedNotes;
    newWhiskeyObject.taste = self.savedTaste;
    newWhiskeyObject.age = @(self.savedAge);
    
    if (self.savedRegion)
    {
        [newWhiskeyObject setValue:self.savedRegion forKey:@"region"];
        [[newWhiskeyObject valueForKey:@"region"] addWhiskiesObject:newWhiskeyObject];
    }
    
    NSManagedObject *newWhiskeyImage = [NSEntityDescription insertNewObjectForEntityForName:@"WhiskeyImage" inManagedObjectContext:self.managedObjectContext];
    [newWhiskeyImage setValue:newWhiskeyObject forKey:@"whiskey"];
    [newWhiskeyObject setValue:newWhiskeyImage forKey:@"image"];
    [newWhiskeyImage setValue:UIImageJPEGRepresentation(self.savedImage, 0.75f) forKey:@"imageData"];
    
    [self saveContext];
}

-(void)updateItem
{
    // Attributes
    self.whiskey.name = self.savedName;
    self.whiskey.canonicalName = [self.savedName lowercaseString];
    self.whiskey.nose = self.savedNose;
    self.whiskey.notes = self.savedNotes;
    self.whiskey.taste = self.savedTaste;
    self.whiskey.age = @(self.savedAge);
    
    // Relationships
    [self.whiskey.region removeWhiskiesObject:self.whiskey];
    self.whiskey.region = self.savedRegion;
    [self.whiskey.region addWhiskiesObject:self.whiskey];
}

#pragma mark - UIActionSheetDelegate methods
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet == imageActionSheet)
    {
        [self handleImageActionSheetButtonIndex:buttonIndex];
    }
    else if (actionSheet == deletionActionSheet)
    {
        [self handleDeletionActionSheetButtonIndex:buttonIndex];
    }
}

#pragma mark - UIImagePickerController methods
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    self.savedImage = info[UIImagePickerControllerEditedImage];
    
    [self.photoButton setPhoto:self.savedImage];
    
    [[self.whiskey valueForKey:@"image"] setValue:UIImageJPEGRepresentation(self.savedImage, 0.75f) forKey:@"imageData"];
    [self saveContext];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - AFRegionSelectViewControllerDelegate Methods

-(void)regionSelectViewController:(AFRegionSelectViewController *)controller didSelectRegion:(AFRegion *)region
{
    self.savedRegion = region;
    [self.navigationController popToViewController:self animated:YES];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:AFDetailViewControllerNameSectionRegionRow inSection:AFDetailViewControllerNameSection]] withRowAnimation:UITableViewRowAnimationFade];
    
    [self saveContext];
}

@end
