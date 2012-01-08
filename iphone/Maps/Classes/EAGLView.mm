#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "EAGLView.h"

#include "../../yg/screen.hpp"
#include "../../yg/texture.hpp"
#include "../../yg/resource_manager.hpp"
#include "../../yg/internal/opengl.hpp"
#include "../../yg/skin.hpp"
#include "../../map/render_policy.hpp"
#include "../../map/framework.hpp"
#include "../../platform/platform.hpp"
#include "../../platform/video_timer.hpp"
#include "RenderBuffer.hpp"
#include "RenderContext.hpp"

@implementation EAGLView

@synthesize framework;
@synthesize videoTimer;
@synthesize frameBuffer;
@synthesize renderContext;
@synthesize renderBuffer;
@synthesize renderPolicy;

// You must implement this method
+ (Class)layerClass
{
  return [CAEAGLLayer class];
}

// The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{
  if ((self = [super initWithCoder:coder]))
  {
    // Setup Layer Properties
    CAEAGLLayer * eaglLayer = (CAEAGLLayer *)self.layer;

    eaglLayer.opaque = YES;

    renderContext = shared_ptr<iphone::RenderContext>(new iphone::RenderContext());
    
    if (!renderContext.get())
    {
      [self release];
      return nil;
    }
    
    renderContext->makeCurrent();
    
    /// ColorFormat : RGB565
    /// Backbuffer : YES, (to prevent from loosing content when mixing with ordinary layers).
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:NO],
                                    kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGB565,
                                    kEAGLDrawablePropertyColorFormat,
                                    nil];

    int etalonW = 320;
    int scrW = etalonW;

    UIDevice * device = [UIDevice currentDevice];

    float ver = [device.systemVersion floatValue];
    NSLog(@"%@", device.systemVersion);
    /// rounding problems
    if (ver >= 3.199)
    {
      UIScreen * mainScr = [UIScreen mainScreen];
      scrW = mainScr.currentMode.size.width;
      if (scrW == 640)
        self.contentScaleFactor = 2.0;
    }
  }
  
  return self;
}

- (void)initRenderPolicy
{
  // to avoid grid bug on 3G device
  yg::DataFormat rtFmt = yg::Data4Bpp;
  yg::DataFormat texFmt = yg::Data4Bpp;
  if ([[NSString stringWithFormat:@"%s", glGetString(GL_RENDERER)] hasPrefix:@"PowerVR MBX"])
    rtFmt = yg::Data8Bpp;
  
  typedef void (*drawFrameFn)(id, SEL);
  SEL drawFrameSel = @selector(drawFrame);
  drawFrameFn drawFrameImpl = (drawFrameFn)[self methodForSelector:drawFrameSel];

  videoTimer = CreateIOSVideoTimer(bind(drawFrameImpl, self, drawFrameSel));
  
  yg::ResourceManager::Params rmParams;
  rmParams.m_videoMemoryLimit = GetPlatform().VideoMemoryLimit();
  rmParams.m_rtFormat = rtFmt;
  rmParams.m_texFormat = texFmt;
  
  try
  {
    renderPolicy = CreateRenderPolicy(videoTimer, false, rmParams, renderContext);
  }
  catch (yg::gl::platform_unsupported const & )
  {
    /// terminate program (though this situation is unreal :) )
  }
  
  frameBuffer = renderPolicy->GetDrawer()->screen()->frameBuffer();
  framework->SetRenderPolicy(renderPolicy);
}

- (void)onSize:(int)width withHeight:(int)height
{
  frameBuffer->onSize(width, height);
  
  shared_ptr<DrawerYG> drawer = framework->GetRenderPolicy()->GetDrawer();  

  /// free old video memory
  drawer->screen()->resetRenderTarget();
  drawer->screen()->resetDepthBuffer();
  renderBuffer.reset();

	/// allocate the new one
	renderBuffer = make_shared_ptr(new iphone::RenderBuffer(renderContext, (CAEAGLLayer*)self.layer));
  
  drawer->screen()->setRenderTarget(renderBuffer);
  drawer->screen()->setDepthBuffer(make_shared_ptr(new yg::gl::RenderBuffer(width, height, true)));

  framework->OnSize(width, height);  
  
  drawer->screen()->beginFrame();
  drawer->screen()->clear(yg::gl::Screen::s_bgColor);
  drawer->screen()->endFrame();
}

- (void)drawFrame
{
  shared_ptr<DrawerYG> drawer = framework->GetRenderPolicy()->GetDrawer();

	shared_ptr<PaintEvent> pe(new PaintEvent(drawer.get()));
  
  if (framework->NeedRedraw())
  {
    framework->SetNeedRedraw(false);
    framework->BeginPaint(pe);
    framework->DoPaint(pe);
    renderBuffer->present();
    framework->EndPaint(pe);
  }
}

- (void)layoutSubviews
{
  CGFloat const scale = self.contentScaleFactor;
  CGSize const s = self.bounds.size;
	[self onSize:s.width * scale withHeight:s.height * scale];
}

- (void)dealloc
{
  delete videoTimer;
  // m_framework->SetRenderPolicy(0);
  [EAGLContext setCurrentContext:nil];
  [super dealloc];
}


@end
