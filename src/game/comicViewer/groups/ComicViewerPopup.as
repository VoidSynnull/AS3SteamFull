package game.comicViewer.groups
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.systems.RenderSystem;
	import engine.util.Command;
	
	import game.comicViewer.components.ComicData;
	import game.comicViewer.components.StayInBounds;
	import game.comicViewer.systems.CheckInBoundsSystem;
	import game.components.motion.Draggable;
	import game.components.motion.Edge;
	import game.components.motion.MotionThreshold;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.systems.SystemPriorities;
	import game.systems.input.InputMapSystem;
	import game.systems.input.InteractionSystem;
	import game.systems.motion.DraggableSystem;
	import game.systems.motion.EdgeSystem;
	import game.systems.motion.FollowInputSystem;
	import game.systems.motion.MotionThresholdSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.ui.popup.Popup;
	import game.util.DataUtils;
	import game.util.DisplayAlignment;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class ComicViewerPopup extends Popup
	{
		private var _comicScreen:Entity;
		
		// HUD elements
		private var _zoomInButton:Entity;
		private var _zoomOutButton:Entity;
		private var _homeButton:Entity;
		private var _nextButton:Entity;
		private var _prevButton:Entity;
		private var _closeButton:Entity;
		private var _loading:Entity;
		private var _banner:Entity;
		
		private var _zoomLevel:Number = 0;		
		private var _dragStartTime:Number;
		private var _startDragLoc:Point;
		
		private var _viewerData:XML;
		
		public var comicPrefix:String;
		
		/**
		 * Dispatches the Popup, the next page being turned to, and the total pages.
		 */
		public var pageForward:Signal = new Signal(Popup, int, int);
		
		/**
		 * Dispatches the Popup, the previous page being turned to, and the total pages.
		 */
		public var pageBackward:Signal = new Signal(Popup, int, int);
		
		/**
		 * The ComicViewerPopup is a Popup class that implements a template comic viewer. ComicViewerPopup will
		 * attempt to load a "comic.xml" at the "groupPrefix" you specify, load custom (or default, if not specified)
		 * UI assets, and then pages for your comic viewer from the XML.
		 */
		public function ComicViewerPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
				
		override public function destroy():void
		{
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.pauseParent 		= true;
			this.hideSceneWhenOpen 	= true;
			this.autoOpen 			= true;
			
			
			if(data)
			{
				if(data.hasOwnProperty("comic"))
				{
					comicPrefix = "comics/"+data.comic+"/";
				}
			}
			if(comicPrefix == null)
				comicPrefix="";
			
			//If no groupPrefix has be specified before loading, then load the example viewer
			if(this.groupPrefix == "")
			{
				this.groupPrefix = "comicViewer/";
			}
			this.screenAsset = "comic_viewer.swf";
			
			this.load();
		}
		
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array(this.screenAsset));
			var url:String = super.getFullUrl(this.screenAsset);
			super.shellApi.loadFile(url, gotFile);
		}
		
		public function gotFile(clip:MovieClip):void
		{
			if(clip != null)
			{
				super.screen = clip;
				super.loaded();
				super.preparePopup();
				this.addSystems();
				
				this.screen.visible = false;
				
				this.setupComics();
			}
		}
		
		private function setupCloseButton():void
		{
			var displayObject:DisplayObjectContainer = DisplayObjectContainer(this.screen).getChildByName("close") as DisplayObjectContainer;
			if(displayObject != null)
			{
				this.scaleAssetProportional(displayObject);
				
				_closeButton = ButtonCreator.createButtonEntity(displayObject, this, closeClicked);
			}
		}
		
		private function setupHomeButton():void
		{
			var displayObject:DisplayObjectContainer = DisplayObjectContainer(this.screen).getChildByName("home") as DisplayObjectContainer;
			if(displayObject != null)
			{
				this.scaleAssetProportional(displayObject);
				
				_homeButton = ButtonCreator.createButtonEntity(displayObject, this, homeClicked);
			}
		}
		
		private function setupArrowButtons():void
		{
			var displayObject:DisplayObjectContainer;
			
			displayObject = DisplayObjectContainer(this.screen).getChildByName("arrow_left") as DisplayObjectContainer;
			if(displayObject != null)
			{
				this.scaleAssetProportional(displayObject);
				
				_prevButton = ButtonCreator.createButtonEntity(displayObject, this, prevButtonClicked);
				showHideClick(_prevButton, false);
			}
			
			displayObject = DisplayObjectContainer(this.screen).getChildByName("arrow_right") as DisplayObjectContainer;
			if(displayObject != null)
			{
				this.scaleAssetProportional(displayObject);
				
				_nextButton = ButtonCreator.createButtonEntity(displayObject, this, nextButtonClicked);
			}
		}
		
		private function setupZoomButtons():void
		{
			var displayObject:DisplayObjectContainer;
			
			displayObject = DisplayObjectContainer(this.screen).getChildByName("zoom_out") as DisplayObjectContainer;
			if(displayObject != null)
			{
				this.scaleAssetProportional(displayObject);
				
				_zoomOutButton = ButtonCreator.createButtonEntity(displayObject, this, zoomOutClicked);
				showHideClick(_zoomOutButton, false);
			}
			
			displayObject = DisplayObjectContainer(this.screen).getChildByName("zoom_in") as DisplayObjectContainer;
			if(displayObject != null)
			{
				this.scaleAssetProportional(displayObject);
				
				_zoomInButton = ButtonCreator.createButtonEntity(displayObject, this, zoomInClicked);
			}
		}
		
		private function scaleAsset(displayObject:DisplayObject):void
		{
			if(displayObject != null)
			{
				var screen:DisplayObjectContainer = this.screen;
				var scaleX:Number = this.shellApi.viewportWidth / 960;
				var scaleY:Number = this.shellApi.viewportHeight / 640;
				
				displayObject.x *= scaleX;
				displayObject.y *= scaleY;
				displayObject.scaleX *= scaleX;
				displayObject.scaleY *= scaleY;
			}
		}
		
		private function scaleAssetProportional(displayObject:DisplayObject):void
		{
			if(displayObject != null)
			{
				var screen:DisplayObjectContainer = this.screen;
				var scaleX:Number = this.shellApi.viewportWidth / 960;
				var scaleY:Number = this.shellApi.viewportHeight / 640;
				var scale:Number = Math.min(scaleX, scaleY);
				
				displayObject.x *= scaleX;
				displayObject.y *= scaleY;
				displayObject.scaleX *= scale;
				displayObject.scaleY *= scale;
			}
		}
		
		private function setupBackground():void
		{
			var background:DisplayObject = DisplayObjectContainer(this.screen).getChildByName("background");
			if(background != null)
			{
				this.scaleAsset(background);
				
				var entity:Entity = EntityUtils.createSpatialEntity(this, background);
				entity.add(new Id(background.name));
			}
		}
		
		private function setupHeader():void
		{
			var header:MovieClip = DisplayObjectContainer(this.screen).getChildByName("header") as MovieClip;
			if(header != null)
			{
				this.scaleAsset(header);
				
				var entity:Entity = ButtonCreator.createButtonEntity(header, this, onHeaderClicked);
				entity.add(new Id(header.name));
				
				if(!DataUtils.getString(_viewerData.headerUrl))
				{
					ToolTipCreator.removeFromEntity(entity);
				}
			}
		}
		
		private function onHeaderClicked(entity:Entity):void
		{
			if(DataUtils.getString(_viewerData.headerUrl))
			{
				navigateToURL(new URLRequest(DataUtils.getString(_viewerData.headerUrl)), "_blank");
			}
		}
		
		private function setupFooter():void
		{
			var footer:MovieClip = DisplayObjectContainer(this.screen).getChildByName("footer") as MovieClip;
			if(footer != null)
			{
				this.scaleAsset(footer);
				
				var entity:Entity = ButtonCreator.createButtonEntity(footer, this, onFooterClicked);
				entity.add(new Id(footer.name));
				
				if(!DataUtils.getString(_viewerData.headerUrl))
				{
					ToolTipCreator.removeFromEntity(entity);
				}
			}
		}
		
		private function onFooterClicked(entity:Entity):void
		{
			if(DataUtils.getString(_viewerData.footerUrl))
			{
				navigateToURL(new URLRequest(DataUtils.getString(_viewerData.footerUrl)), "_blank");
			}
		}
		
		private function setupPanelLeft():void
		{
			var panel:MovieClip = DisplayObjectContainer(this.screen).getChildByName("panel_left") as MovieClip;
			if(panel != null)
			{
				this.scaleAsset(panel);
				
				var entity:Entity = ButtonCreator.createButtonEntity(panel, this, onPanelLeftClicked);
				entity.add(new Id(panel.name));
				
				if(!DataUtils.getString(_viewerData.panelLeftUrl))
				{
					ToolTipCreator.removeFromEntity(entity);
				}
			}
		}
		
		private function onPanelLeftClicked(entity:Entity):void
		{
			if(DataUtils.getString(_viewerData.panelLeftUrl))
			{
				navigateToURL(new URLRequest(DataUtils.getString(_viewerData.panelLeftUrl)), "_blank");
			}
		}
		
		private function setupPanelRight():void
		{
			var panel:MovieClip = DisplayObjectContainer(this.screen).getChildByName("panel_right") as MovieClip;
			if(panel != null)
			{
				this.scaleAsset(panel);
				
				var entity:Entity = ButtonCreator.createButtonEntity(panel, this, onPanelRightClicked);
				entity.add(new Id(panel.name));
				
				if(!DataUtils.getString(_viewerData.panelRightUrl))
				{
					ToolTipCreator.removeFromEntity(entity);
				}
			}
		}
		
		private function onPanelRightClicked(entity:Entity):void
		{
			if(DataUtils.getString(_viewerData.panelRightUrl))
			{
				navigateToURL(new URLRequest(DataUtils.getString(_viewerData.panelRightUrl)), "_blank");
			}
		}
		
		private function setupComics():void
		{
			this.loadFile(comicPrefix+"comic.xml", comicXMLLoaded);
		}
		
		private function comicXMLLoaded(comicXML:XML):void
		{
			_viewerData = comicXML;
			var data:ComicData =  new ComicData(this, comicXML);
			data.bufferLoaded.addOnce(comicDataLoaded);
			
			var comics:DisplayObjectContainer = DisplayObjectContainer(this.screen).getChildByName("comics") as DisplayObjectContainer;
			if(comics != null)
			{
				_comicScreen = EntityUtils.createMovingEntity(this, comics);
				_comicScreen.add( data );
				
				var rectangle:Rectangle = this.getComicRectangle();
				
				_comicScreen.add(new StayInBounds(rectangle));
			}
			
			this.setupBackground();
			this.setupHeader();
			this.setupFooter();
			this.setupPanelLeft();
			this.setupPanelRight();
			this.setupLoading();
			this.setupHomeButton();
			this.setupArrowButtons();
			this.setupZoomButtons();
			this.setupCloseButton();
			
			this.screen.visible = true;
		}
		
		private function getComicRectangle():Rectangle
		{
			var rectangle:Rectangle = new Rectangle(0, 0, shellApi.viewportWidth, shellApi.viewportHeight);
			var screen:DisplayObjectContainer = this.screen as DisplayObjectContainer;
			var displayObject:DisplayObject;
			
			displayObject = screen.getChildByName("header");
			if(displayObject != null)
			{
				rectangle.y += displayObject.height;
				rectangle.height -= displayObject.height;
			}
			
			displayObject = screen.getChildByName("footer");
			if(displayObject != null)
			{
				rectangle.height -= displayObject.height;
			}
			
			displayObject = screen.getChildByName("panel_left");
			if(displayObject != null)
			{
				rectangle.x += displayObject.width;
				rectangle.width -= displayObject.width;
			}
			
			displayObject = screen.getChildByName("panel_right");
			if(displayObject != null)
			{
				rectangle.width -= displayObject.width;
			}
			
			return rectangle;
		}
		
		private function comicDataLoaded(...p):void
		{
			var comic:ComicData = _comicScreen.get(ComicData);
			comic.comicPage = 0;
			updateComicScreen();
		}
		
		private function setupLoading():void
		{
			var displayObject:MovieClip = DisplayObjectContainer(this.screen).getChildByName("loading") as MovieClip;
			if(displayObject != null)
			{
				this.scaleAssetProportional(displayObject);
				_loading = EntityUtils.createSpatialEntity(this, displayObject);
				_loading = TimelineUtils.convertClip(displayObject, this, _loading, null, true);
				_loading.get(Display).visible = true;
			}
		}
		
		private function updateComicScreen():void
		{
			_loading.get(Display).visible = true;
			var display:Display = _comicScreen.get(Display);
			display.displayObject.removeChildren();
			display.visible = true;
			
			var comic:ComicData = _comicScreen.get(ComicData);
			
			if(comic.comicPage >= comic.pagePaths.length)
			{
				showHideClick(_nextButton, false);
			}
			else if(comic.comicPage == 0)
			{
				showHideClick(_prevButton,false);
			}
			else
			{
				showHideClick(_nextButton,true);
				showHideClick(_prevButton,true);
			}
			
			comic.getBufferedPage(comicPageLoaded);
			//shellApi.loadFile(shellApi.assetPrefix + comic.pagePaths[comic.comicNumber], comicPageLoaded);
		}
		
		private function comicPageLoaded(loadedImage:DisplayObject):void
		{
			_loading.get(Display).visible = false;
			
			//Loaded BitmapData seems to come in with data, but won't display.
			//Seemingly, the only way to fix it is to clone it.
			if(loadedImage is Bitmap){
				Bitmap(loadedImage).bitmapData = Bitmap(loadedImage).bitmapData.clone();
			}
			
			_comicScreen.get(Display).displayObject.addChild(loadedImage);
			scalePlaceComic();
		}
		
		private function homeClicked(entity:Entity):void
		{
			var comicData:ComicData = _comicScreen.get(ComicData);
			comicData.comicPage = 0;
			this.updateComicScreen();
		}
		
		private function closeClicked(closeButton:Entity):void
		{
			this.close();
		}
		
		private function zoomInClicked(zoomInBtn:Entity):void
		{
			_zoomLevel++;
			
			scalePlaceComic();
		}
		
		private function zoomOutClicked(zoomOutBtn:Entity):void
		{
			_zoomLevel--;
			
			scalePlaceComic();
		}
		
		private function nextButtonClicked(nextButton:Entity):void
		{
			// turn pages and check for ending
			if(_comicScreen.get(Display).visible)
			{
				var comicData:ComicData = _comicScreen.get(ComicData);
				if(comicData.comicPage + 1 < comicData.pagePaths.length)
				{
					comicData.comicPage++;
					updateComicScreen();
					this.pageForward.dispatch(this, comicData.comicPage + 1, comicData.pagePaths.length);
				}
			}
		}
		
		private function prevButtonClicked(prevButton:Entity):void
		{
			if(_comicScreen.get(Display).visible)
			{
				var comicData:ComicData = _comicScreen.get(ComicData);
				if(comicData.comicPage - 1 >= 0)
				{
					comicData.comicPage--;
					updateComicScreen();
					this.pageBackward.dispatch(this, comicData.comicPage + 1, comicData.pagePaths.length);
				}
			}
		}
		
		// show or hide clickable and their tooltip
		private function showHideClick(clickEnt:Entity, show:Boolean = true, toggleToolTip:Boolean = true):void
		{
			clickEnt.get(Display).visible = show;
			if(toggleToolTip){
				if(show){
					ToolTipCreator.addToEntity(clickEnt);
				}
				else{
					ToolTipCreator.removeFromEntity(clickEnt);
				}
			}
		}
		
		private function scalePlaceComic():void
		{
			// zoom in/out the page, fit withing bounds of screenview
			var displayObject:DisplayObject = _comicScreen.get(Display).displayObject;
			var fillRectangle:Rectangle = new Rectangle(0, 0, shellApi.viewportWidth, shellApi.viewportHeight);
			
			if(_zoomLevel == 0)
			{
				var header:Entity = this.getEntityById("header");
				var footer:Entity = this.getEntityById("footer");
				var headerDisplay:DisplayObject = Display(header.get(Display)).displayObject;
				var footerDisplay:DisplayObject = Display(footer.get(Display)).displayObject;
				
				EntityUtils.removeInteraction(_comicScreen);
				_comicScreen.remove(Draggable);
				_comicScreen.remove(Edge);
				_comicScreen.get(Motion).zeroMotion();
				
				var rectangle:Rectangle = this.getComicRectangle();
				DisplayAlignment.fitAndAlign(displayObject, rectangle);
				
				showHideClick(_zoomInButton,true);
				showHideClick(_zoomOutButton,false);
			}
			else if(_zoomLevel == 1)
			{
				DisplayAlignment.fillAndAlign(displayObject, fillRectangle, null, DisplayAlignment.MID_X_MIN_Y);
				
				// make draggable
				InteractionCreator.addToEntity(_comicScreen, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);				
				var draggable:Draggable = new Draggable();
				draggable.drag.add(startDrag);
				draggable.drop.add(stopDrag);
				draggable.forward = false;
				_comicScreen.add(draggable);
				
				var edge:Edge = new Edge();
				edge.unscaled = displayObject.getBounds(displayObject);
				_comicScreen.add(edge);
				
				//showHideClick(_homeBtn,false);
				showHideClick(_zoomInButton,true);
				showHideClick(_zoomOutButton,true);
			}
			else
			{
				fillRectangle.inflate(shellApi.viewportWidth/2, shellApi.viewportHeight/2);
				DisplayAlignment.fillAndAlign(displayObject, fillRectangle);
				
				showHideClick(_zoomInButton,false);
				showHideClick(_zoomOutButton,true);
			}
			
			var spatial:Spatial = _comicScreen.get(Spatial);
			spatial.x = displayObject.x;
			spatial.y = displayObject.y;
			spatial.scaleX = displayObject.scaleX;
			spatial.scaleY = displayObject.scaleY;			
		}
		
		private function startDrag(entity:Entity):void
		{
			// pick up page and log delta of time for moving later
			var spatial:Spatial = entity.get(Spatial);
			_startDragLoc = new Point(spatial.x, spatial.y);
			_dragStartTime = getTimer();
		}
		
		private function stopDrag(entity:Entity):void
		{
			if(!_startDragLoc) return;
			
			// drop the page, bring it to a stop
			var timeElapsed:Number = (getTimer() - _dragStartTime) * .001;
			var spatial:Spatial = entity.get(Spatial);			
			var movedX:Number = spatial.x - _startDragLoc.x;
			var movedY:Number = spatial.y - _startDragLoc.y;
			
			var speedX:Number = movedX/timeElapsed;	
			var speedY:Number = movedY/timeElapsed;
			var motion:Motion = entity.get(Motion);
			motion.velocity = new Point(speedX, speedY);
			motion.acceleration = new Point(-speedX, -speedY);
			
			var motionThreshold:MotionThreshold = new MotionThreshold("velocity");
			motionThreshold.operator = motion.velocity.x < 0 ? ">=" : "<=";
			motionThreshold.axisValue = "x";
			motionThreshold.threshold = 0;
			motionThreshold.entered.addOnce(Command.create(dragMotionEntered, entity));
			entity.add(motionThreshold);
		}
		
		private function dragMotionEntered(entity:Entity):void
		{
			var motion:Motion = entity.get(Motion);
			motion.zeroMotion();
		}
		
		private function addSystems():void
		{
			this.addSystem(new FollowInputSystem());
			this.addSystem(new InputMapSystem());
			this.addSystem(new InteractionSystem(), SystemPriorities.update);	
			this.addSystem(new RenderSystem(), SystemPriorities.render);
			this.addSystem(new TimelineControlSystem());
			this.addSystem(new TimelineClipSystem());
			this.addSystem(new EdgeSystem());
			this.addSystem(new DraggableSystem());
			this.addSystem(new CheckInBoundsSystem());
			this.addSystem(new MotionThresholdSystem());
		}
	}
}