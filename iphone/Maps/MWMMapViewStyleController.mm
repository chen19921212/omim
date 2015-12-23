#import "MWMMapViewStyleController.h"
#import "SelectableCell.h"
#import "Statistics.h"

#include "Framework.h"

@interface MWMMapViewStyleController ()

@property (weak, nonatomic) IBOutlet SelectableCell * twoDimension;
@property (weak, nonatomic) IBOutlet SelectableCell * threeDimension;
@property (weak, nonatomic) IBOutlet SelectableCell * threeDimensionWithBuildings;
@property (weak, nonatomic) SelectableCell * selectedCell;

@end

@implementation MWMMapViewStyleController

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.title = L(@"prefs_map_view_title");
  bool is3d, is3dWithBuildings;
  GetFramework().Load3dMode(is3d, is3dWithBuildings);
  if (is3dWithBuildings)
  {
    self.threeDimensionWithBuildings.accessoryType = UITableViewCellAccessoryCheckmark;
    _selectedCell = self.threeDimensionWithBuildings;
  }
  else if (is3d)
  {
    self.threeDimension.accessoryType = UITableViewCellAccessoryCheckmark;
    _selectedCell = self.threeDimension;
  }
  else
  {
    self.twoDimension.accessoryType = UITableViewCellAccessoryCheckmark;
    _selectedCell = self.twoDimension;
  }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  self.selectedCell.accessoryType = UITableViewCellAccessoryNone;
  self.selectedCell = [tableView cellForRowAtIndexPath:indexPath];
  self.selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
  self.selectedCell.selected = NO;
}

- (void)setSelectedCell:(SelectableCell *)selectedCell
{
  _selectedCell = selectedCell;
  auto & f = GetFramework();
  bool is3d = false, is3dWithBuildings = false;
  NSString * value = nil;
  if ([selectedCell isEqual:self.threeDimension])
  {
    value = kStat3DWithBuildings;
    is3d = true;
  }
  else if ([selectedCell isEqual:self.threeDimensionWithBuildings])
  {
    value = kStat3D;
    is3d = is3dWithBuildings = true;
  }
  else
  {
    value = kStat2D;
  }

  [[Statistics instance] logEvent:kStatEventName(kStatMapViewStyleSettings, kStatMapViewStyle)
                     withParameters:@{kStatValue : value}];

  f.Save3dMode(is3d, is3dWithBuildings);
  f.Allow3dMode(is3d, is3dWithBuildings);
}

@end