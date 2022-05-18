package game.scenes.map.map
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.net.URLVariables;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.EntityCreator;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.collider.SceneCollider;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.TargetEntity;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.components.ui.Book;
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.WaveMotionData;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.data.ui.ToolTipType;
	import game.managers.ads.AdManager;
	import game.managers.ads.AdManagerBrowser;
	import game.managers.ads.AdManagerMobile;
	import game.scene.template.GameScene;
	import game.scenes.americanGirl.AmericanGirlEvents;
	import game.scenes.americanGirl.mainStreet.MainStreet;
	import game.scenes.americanGirl.mainStreetKira.MainStreetKira;
	import game.scenes.hub.town.Town;
	import game.scenes.lego.mainStreet.MainStreet;
	import game.scenes.map.map.components.Banner;
	import game.scenes.map.map.components.Bird;
	import game.scenes.map.map.components.Blimp;
	import game.scenes.map.map.components.IslandInfo;
	import game.scenes.map.map.components.MapCloud;
	import game.scenes.map.map.components.MapControl;
	import game.scenes.map.map.groups.IslandPopup;
	import game.scenes.map.map.groups.LegendarySwordsMembership;
	import game.scenes.map.map.groups.PopWorldsPopup;
	import game.scenes.map.map.swipe.Swipe;
	import game.scenes.map.map.swipe.SwipeSystem;
	import game.scenes.map.map.systems.BannerSystem;
	import game.scenes.map.map.systems.BirdSystem;
	import game.scenes.map.map.systems.BlimpSystem;
	import game.scenes.map.map.systems.MapMovementSystem;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.systems.ui.BookSystem;
	import game.ui.hud.HudMap;
	import game.ui.popup.IslandBlockPopup;
	import game.util.Alignment;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	import game.util.StringUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.Utils;
	import game.utils.AdUtils;
		
	/**
	 * Scene containing the Poptropica map.
	 * From here islands can be selected. 
	 * @author umckiba
	 * 
	 */
	public class Map extends GameScene
	{
		private var doMapABTest:Boolean = false;
		private var overrideAS2Map:Boolean = false;
		
		// lego island impressions
		private const LegoIslandImpression:String = null;
		private const LegoIslandClicked:String = null;
		private const AmericanGirlIslandImpression:String = null;
		private const AmericanGirlIslandClicked:String = null;
		
		private const cloudShadow:DropShadowFilter 	= new DropShadowFilter(15, 100, 0x000000, 0.05, 8, 8, 1, 1);
		private const cloudOutline:DropShadowFilter = new DropShadowFilter(0, 0, 0x000000, 1, 2, 2, 1, 3);
		
		private const PAGE_SIZE_SMALLEST:int 		= 2;
		private const PAGE_SIZE_SMALL:int 			= 3;
		private const PAGE_SIZE_MEDIUM:int			= 4;
		private const PAGE_SIZE_DEFAULT:int			= 7;
		
		private const POPWORLDS_POPUP:String 		= "popWorldsPopup";
		
		public var autoLoadIsland:String;
		
		/*
		For reference. These filters should be applied to the island.flas themselves.
		*/
		//GlowFilter(0xF3E1B6, 1, 6, 6, 4, 1);
		//GlowFilter(0xFADC63, 1, 6, 6, 4, 1);
		
		private var islandsToLoad:int = 0;
		private var numIslands:int 	= 0;
		private var numPages:int 	= 0;
		
		private var pageButtonsLoaded:int = 0;
		
		private var rectangle:Rectangle = new Rectangle(150, 200, 660, 200);
		private var numRows:int = 2;
		private var numCols:int = 3;
		
		private var mapXML:XML;
		
		private var blimp:Entity;
		private var blimpShape:Entity;
		private var disabledAS2Islands:Boolean = false;
		
		// blimp takeover variables
		private var hasBlimpTakeover:Boolean = false;
		private var blimpTakeoverPath:String;
		private var loadCount:int = 0;
		
		private var islands:Array = [];
		private var customPlacements:Array = [];
		private var partitions:Vector.<IslandPartition> = new Vector.<IslandPartition>();	// 0229 :: Island Partitions -- See mobile/browser.xml comments
		private var partition_current:IslandPartition;
		
		private var banners:Vector.<Entity> = new Vector.<Entity>();	// 0229 :: Banners (shown below the islands per partition)
		
		public function Map(overrideAS2Map:Boolean = false)
		{
			super();
			this.overrideAS2Map = overrideAS2Map;
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			this.groupPrefix = "scenes/map/map/";
			
			super.init(container);		
		}
		
		override public function destroy():void
		{
			if (_hitContainer) {
				this._hitContainer.removeEventListener(MouseEvent.MOUSE_DOWN, blimpStart);
				this._hitContainer.removeEventListener(MouseEvent.MOUSE_UP, blimpStop);
				this._hitContainer.removeEventListener(MouseEvent.RELEASE_OUTSIDE, blimpStop);
			}
			super.destroy();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// check for blimp takover
			var adData:AdData = shellApi.adManager.getAdData(shellApi.adManager.blimpType);
			if (adData != null)
			{
				// impression tracking	
				shellApi.adManager.track(adData.campaign_name, AdTrackingConstants.TRACKING_MAP_IMPRESSION);
				
				hasBlimpTakeover = true;
				// set path to takeover swfs
				blimpTakeoverPath = shellApi.assetPrefix + AdvertisingConstants.AD_PATH_KEYWORD + "/" + adData.campaign_name + "/";
				// load three takeover swfs
				super.loadFiles([blimpTakeoverPath + "mapBack.swf", blimpTakeoverPath + "mapFooter.swf", blimpTakeoverPath + "mapBlimp.swf"], true, false, doneLoadBlimpFiles);
			}
			else
			{
				super.load();
			}
		}
		
		// when done loading takeover files
		private function doneLoadBlimpFiles():void
		{
			// load rest of scene
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			// if takeover, then wait until both loads are done
			if (hasBlimpTakeover)
			{
				var clip:MovieClip = shellApi.getFile(blimpTakeoverPath + "mapBack.swf");
				this._hitContainer["map"]["background"].addChild(clip);
				this.setupFooter();
				this.setupBlimp();
			}
			
			// if ads are active, then prep scene for possible ads
			if (AppConfig.adsActive)
				super.shellApi.adManager.prepSceneForAds(this);
			
			this.shellApi.eventTriggered.add(eventTriggered);
			
			this.shellApi.camera.target = new Spatial(this.shellApi.viewportWidth / 2, this.shellApi.viewportHeight / 2);
			this.shellApi.camera.jumpToTarget = true;
			
			/**
			 * Some MovieClips are blocking clicks. This is UNACCEPTABLE. Get the Hit Container and iterate through
			 * everything currently on-screen and disable their mouse events.
			 */
			//this.disableClicks(this._hitContainer);
			
			this.addSystem(new FollowTargetSystem());
			this.addSystem(new MoveToTargetSystem(this.shellApi.viewportWidth, this.shellApi.viewportHeight));
			this.addSystem(new MotionControlBaseSystem());
			this.addSystem(new MotionTargetSystem());
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new BoundsCheckSystem());
			this.addSystem(new BitmapSequenceSystem());
			this.addSystem(new TimelineControlSystem());
			this.addSystem(new TimelineClipSystem());
			
			this.addSystem(new BlimpSystem());
			this.addSystem(new BannerSystem());
			this.addSystem(new BirdSystem());
			this.addSystem(new BookSystem());
			this.addSystem(new TimelineClipSystem());
			this.addSystem(new TimelineControlSystem());
			this.addSystem(new SwipeSystem());
			
			var mapMovementSystem:MapMovementSystem = new MapMovementSystem();
			mapMovementSystem.resetCloud.add(resetCloud);
			this.addSystem(mapMovementSystem);
			
			this.setupHUD();
			this.setupHeader();
			if (!hasBlimpTakeover)
			{
				this.setupFooter();
				this.setupBlimp();
			}
			this.setupMapBackground();
			this.setupArrows();
			this.setupPageClicks();
			this.setupPageSwipe();
			this.setupBirds();
			this.setupClouds();
			this.setupIslands();	// when islands are done loading, groupReady is called
		}
		
		private function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event.indexOf("reset_progress_") > -1)
			{
				//Get the island name from the rest of the event String.
				this.resetIslandProgress(event.substr(String("reset_progress_").length));
			}
		}
		
		private function resetIslandProgress(islandName:String):void
		{
			var parts:Array = islandName.split(/(\d+)/);this._hitContainer["map"]["background"]
			//If there is no episode number on the island, there's only one progress bar.
			if(parts.length == 1)
			{
				parts.push(1);
			}
			var entity:Entity = this.getEntityById(parts[0]);
			if(entity)
			{
				//Reset the island info's progress back to 0.
				var islandInfo:IslandInfo = entity.get(IslandInfo);
				islandInfo.progresses[parts[1] - 1] = 0;
				
				//Visibly put the progress for the island/episode down to 0.
				var progress:Entity = EntityUtils.getChildById(entity, "progress");
				var display:DisplayObjectContainer = Display(progress.get(Display)).displayObject;
				var child:DisplayObject = display.getChildByName("progress" + parts[1]);
				if(child)
				{
					child.width = 0;
				}
			}
		}
		
		private function setupHeader():void
		{
			var clip:MovieClip;
			
			var header:MovieClip = this._hitContainer["header"];
			header.x = 0;
			header.y = 0;
			
			var background:MovieClip = header["background"];
			background.width = this.shellApi.viewportWidth;
			
			clip = header["poptropica"];
			clip.x = background.width / 2;
			clip.y = background.height / 2;
			
			clip = header["cloudLeft"];
			clip.x = 0;
			clip.y = background.height;
			
			clip = header["cloudRight"];
			clip.x = background.width;
			clip.y = background.height;
			
			clip = header["gradient"];
			clip.x = background.width / 2;
			clip.y = background.height;
			clip.width = background.width;
			
			this.convertToBitmap(header);
		}
		
		private function setupFooter():void
		{			
			var clip:MovieClip;
			
			var footer:MovieClip = this._hitContainer["footer"];
			footer.x = 0;
			footer.y = this.shellApi.viewportHeight;
			
			var background:MovieClip = footer["background"];
			background.width = this.shellApi.viewportWidth;
			
			// get promotion clip
			clip = footer["promotion"];
			// if takeover
			if (hasBlimpTakeover)
			{
				// remove promotion clip
				footer.removeChild(clip);
				// get footer takeover clip
				var takeoverClip:MovieClip = shellApi.getFile(blimpTakeoverPath + "mapFooter.swf");
				// add to blimpTakeover placeholder
				footer["blimpTakeover"].addChild(takeoverClip);
				// set placeholder as clip
				clip = MovieClip(footer["blimpTakeover"]);
			}
			// set location of promotion or takeover clip
			clip.x = background.width / 2;
			clip.y = -background.height / 2;
			
			clip = footer["gradient"];
			clip.x = background.width / 2;
			clip.y = -background.height;
			clip.width = background.width;
			
			this.convertToBitmap(footer);
		}
		
		private function setupMapBackground():void
		{
			var clip:MovieClip;
			
			var header:DisplayObject = this._hitContainer["header"];
			var footer:DisplayObject = this._hitContainer["footer"];
			var map:MovieClip = this._hitContainer["map"];
			
			//Adding an extra -2 / +4 to the y and height of the map because for some reason it wasn't lining up with the header and footer well enough.
			
			map.x = 0;
			map.y = header.height - 2;
			
			var content:MovieClip = map["content"];
			content.mouseEnabled = false;
			content.mouseChildren = true;
			
			var background:MovieClip = map["background"];
			background.width = this.shellApi.viewportWidth;
			background.height = this.shellApi.viewportHeight - (header.height + footer.height) + 4; //(100 + 65) are the header and footer
			this.convertToBitmap(background);
			
			if (hasBlimpTakeover)
			{
				map.removeChild(map["barTop"]);
				map.removeChild(map["barBottom"]);
			}
			else
			{
				clip = map["barTop"];
				clip.x = background.width / 2;
				clip.y = 20;
				this.convertToBitmap(clip);
				
				clip = map["barBottom"];
				clip.x = background.width / 2;
				clip.y = background.height - 20;
				this.convertToBitmap(clip);
			}
		}
		
		/**
		 * Iterates through container setting mouse enabled to fals on all clips.  
		 * @param container
		 * 
		 */
		private function disableClicks(container:DisplayObjectContainer):void
		{
			container.mouseEnabled = false;
			for(var i:int = 0; i < container.numChildren; i++)
			{
				var child:DisplayObject = container.getChildAt(i);
				if(child is DisplayObjectContainer)
				{
					disableClicks(child as DisplayObjectContainer);
				}
			}
		}
		
		// setup a map specific hud
		private function setupHUD():void
		{
			var hudMap:HudMap = new HudMap(this.overlayContainer);
			this.addChildGroup(hudMap);
		}
		
		private function setupPageSwipe():void
		{
			var clip:MovieClip = this._hitContainer["map"];
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
			
			InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.OUT]);
			
			var swipe:Swipe = new Swipe();
			swipe.stop.add(this.onMapSwipe);
			entity.add(swipe);
		}
		
		private function setupArrows():void
		{
			var map:MovieClip = this._hitContainer["map"];
			var background:DisplayObject = map["background"];
			
			var clip:DisplayObject;
			var entity:Entity;
			var wave:WaveMotion;
			
			clip 	= map["arrowLeft"];
			clip.x 	= 10;
			clip.y 	= background.height * 0.5;
			clip = this.createBitmapSprite(clip);
			
			entity = EntityUtils.createSpatialEntity(this, clip);
			entity.add(new SpatialAddition());
			entity.add(new Id(clip.name));
			wave = new WaveMotion();
			wave.data.push(new WaveMotionData("x", 5, 2, "sin", 0, true));
			entity.add(wave);
			//Display(entity.get(Display)).visible = false;
			
			clip 	= map["arrowRight"];
			clip.x 	= background.width - 10;
			clip.y 	= background.height * 0.5;
			clip = this.createBitmapSprite(clip);
			
			entity = EntityUtils.createSpatialEntity(this, clip);
			entity.add(new SpatialAddition());
			entity.add(new Id(clip.name));
			wave = new WaveMotion();
			wave.data.push(new WaveMotionData("x", 5, 2, "sin", Math.PI, true));
			entity.add(wave);
		}
		
		private function setupPageClicks():void
		{
			var clip:MovieClip;
			var entity:Entity;
			var wave:WaveMotion;
			
			var map:MovieClip = this._hitContainer["map"];
			var background:DisplayObject = map["background"];
			
			//Page Left
			clip 	= map["pageLeft"];
			clip.x 	= 0;
			clip.y 	= background.height * 0.5;
			
			entity = ButtonCreator.createButtonEntity(clip, this, this.turnPage, null, null, ToolTipType.NONE);
			entity.add(new Id("pageLeft"));
			entity.get(Button).value = -1;
			
			//Page Right
			clip 	= map["pageRight"];
			clip.x 	= background.width;
			clip.y 	= background.height * 0.5;
			
			entity = ButtonCreator.createButtonEntity(clip, this, this.turnPage, null, null, ToolTipType.NONE);
			entity.add(new Id("pageRight"));
			entity.get(Button).value = 1;
		}
		
		private function setupBlimp():void
		{
			var background:DisplayObject = this._hitContainer["map"]["background"];
						
			var blimpClip:MovieClip = this._hitContainer["map"]["blimp"];
			blimpClip.x = background.width  * 0.5;
			blimpClip.y = background.height * 0.5;
			blimpClip.mouseChildren = false;
			blimpClip.mouseEnabled 	= false;
			
			this.blimp = EntityUtils.createSpatialEntity( this, blimpClip );
			
			//this.shellApi.player = this.blimp;
			
			var motion:Motion 	= new Motion();
			motion.friction 	= new Point(200, 200);
			motion.maxVelocity 	= new Point(200, 200);
			this.blimp.add(motion);
			
			var motionControlBase:MotionControlBase = new MotionControlBase();
			motionControlBase.freeMovement 			= false;
			motionControlBase.acceleration 			= 600;
			motionControlBase.stoppingFriction 		= 200;
			this.blimp.add(motionControlBase);
			
			var motionControl:MotionControl = new MotionControl();
			this.blimp.add(motionControl);
			
			var bounds:Rectangle 	= new Rectangle();
			bounds.left 			= 30;
			bounds.top 				= 60;
			bounds.right 			= background.width - 30;
			bounds.bottom 			= background.height - 20;
			this.blimp.add(new MotionBounds(bounds));
			
			if(!PlatformUtils.isMobileOS)
			{
				motionControl.lockInput = true;
				motionControl.forceTarget = true;
				
				//this._hitContainer.mouseChildren = true;
				//this._hitContainer.mouseEnabled = true;
				//this._hitContainer.addEventListener(MouseEvent.MOUSE_DOWN, onClick);
				//var input:Input = this.shellApi.inputEntity.get(Input);
				//input.inputUp.add(blimpStart);
			}
			else
			{
				/*
				Miserable input entity is behind the map that needs interactions for swiping,
				but with swiping and mouse enabled, the input entity isn't clicked...
				*/
				this._hitContainer.addEventListener(MouseEvent.MOUSE_DOWN, blimpStart);
				this._hitContainer.addEventListener(MouseEvent.MOUSE_UP, blimpStop);
				this._hitContainer.addEventListener(MouseEvent.RELEASE_OUTSIDE, blimpStop);
			}
			
			//this.blimp.add(new Player());
			this.blimp.add(new Id("blimp"));
			this.blimp.add(new MotionTarget());
			this.blimp.add(new SceneCollider());
			var targetEntity:TargetEntity = new TargetEntity(100, 100, this.shellApi.inputEntity.get(Spatial));
			targetEntity.forceTarget = true;
			targetEntity.offset = new Point(0, -40);
			this.blimp.add(targetEntity);
			
			// get blimp shape (actual timeline animation)
			var blimpShape:MovieClip = blimpClip.getChildByName("shape") as MovieClip;
			
			// if takeover
			if (hasBlimpTakeover)
			{
				// get takeover blimp
				var takeoverBlimp:MovieClip = shellApi.getFile(blimpTakeoverPath + "mapBlimp.swf");
				// delete old blimp
				blimpClip.removeChild(blimpShape);
				// load new blimp with timeline animation
				blimpShape = MovieClip(blimpClip.addChild(takeoverBlimp));
			}			
			this.blimpShape = EntityUtils.createSpatialEntity(this, blimpShape);
			TimelineUtils.convertClip( blimpShape, this, this.blimpShape, this.blimp, false);
			var timeline:Timeline = this.blimpShape.get(Timeline);
			timeline.handleLabel("flip", flipBlimp, false);
			
			this.blimp.add(new Blimp(this.shellApi.inputEntity.get(Spatial), this.blimpShape));
		}
		
		private function blimpStart(...args/*input:Input*/):void
		{
			this.blimp.get(MotionControl).forceTarget = true;
		}
		
		private function blimpStop(...args):void
		{
			this.blimp.get(MotionControl).forceTarget = false;
		}
		
		private function flipBlimp():void
		{
			this.blimp.get(Spatial).scaleX *= -1;
		}
		
		private function setupBirds():void
		{
			var container:DisplayObjectContainer = this._hitContainer["map"]["birds"];
			
			for(var i:int = 1; i <= 7; i++)
			{
				var sprite:Sprite 		= new Sprite();
				sprite.mouseChildren 	= false;
				sprite.mouseEnabled 	= false;
				container.addChildAt(sprite, container.numChildren);
				
				var entity:Entity = EntityUtils.createSpatialEntity(this, sprite);
				entity.add(new Id("bird" + i));
				
				var bird:Bird = new Bird(this.blimp, 8, i * 0.6, 100 - (i * 10));
				bird.flockTime = i * 1.2;
				entity.add(bird);
				
				var shape:Shape;
				
				shape = new Shape();
				shape.graphics.lineStyle(1.5, 0x8A7345);
				shape.graphics.lineTo(-3, 0);
				sprite.addChild(shape);
				bird.wing1 = shape;
				
				shape = new Shape();
				shape.graphics.lineStyle(1.5, 0x8A7345);
				shape.graphics.lineTo(-3, 0);
				shape.scaleX = -1;
				sprite.addChild(shape);
				bird.wing2 = shape;
				
				var spatial:Spatial = entity.get(Spatial);
				spatial.x = Utils.randNumInRange(300, 350);
				spatial.y = Utils.randNumInRange(300, 350);
			}
		}
		
		private function turnPage(roll:Entity):void
		{
			var book:Book = this.getEntityById("map").get(Book);
			var button:Button = roll.get(Button);
			
			switch(button.value)
			{
				case -1:
					if(book.page - 1 >= 1)
					{
						this.setPage(book.page - 1);
					}
					break;
				
				case 1:
					if(book.page + 1 <= book.numPages)
					{
						this.setPage(book.page + 1);
					}
					break;
			}
		}
		
		private function invalidateButton(page:int, isSelected:Boolean):void
		{
			var button:Button 	= this.getEntityById("pageButton" + page).get(Button);
			button.isSelected 	= isSelected;
			button.invalidate 	= true;
			
			isSelected ? button.downHandler() : button.outHandler();
		}
		
		private function setupIslands():void
		{
			var path:String;
			// check app of the day
			var ad:AdData = this.shellApi.adManager.getAdData(AdCampaignType.APP_OF_THE_DAY);
			// if found, then use values from adData
			if (ad != null)//removing so we can test locally with out things being live more easily
			{
				// data/map/filename.xml
				if (AppConfig.mobile)
				{
					path = ad.campaign_file2;
					shellApi.loadFileWithServerFallback(path, mapXMLLoaded);
				}
				else
				{
					path = ad.campaign_file1;
					// if CMG use different xml (_cmg suffix)
					if (shellApi.cmg_iframe)
					{
						path = path.substr(0, path.indexOf(".xml")) + "_cmg.xml";
					}
					shellApi.loadFile(path, mapXMLLoaded);
				}
			}
			else
			{
				if(PlatformUtils.inBrowser)
				{
					path = "maps/browser.xml";
				}
				else // if mobile
				{
					path = "maps/mobile.xml";
				}
				this.loadFile(path, mapXMLLoaded);
			}
		}
		
		private function mapXMLLoaded(mapXML:XML, param2:Object = null, param3:Object = null):void
		{
			this.mapXML = mapXML;
			
			//var islandsXML:XMLList = this.mapXML.islands.children();
			var island_partitionsXML:XMLList = this.mapXML.islands.children();
			// 0229 :: Added Partitions to Islands -- See comments in mobile/browser.xml
			
			var adIslands:Array;
			
			this.islandsToLoad = 0;
			//this.islandsToLoad += islandsXML.length();
			
			// AD SPECIFIC
			if (AppConfig.adsActive)
			{
				// if mobile, then get map ads array
				if (AppConfig.mobile)
				{
					adIslands = AdManagerMobile(this.shellApi.adManager).getMobileMapAds();
					// inventory tracking
					this.shellApi.adManager.track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, AdCampaignType.WEB_MAP_AD_BASE);
				}
				else
				{
					// else get ad drivers array
					adIslands = AdManagerBrowser(this.shellApi.adManager).getMapAdDrivers();
					// inventory tracking
					this.shellApi.adManager.track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, AdCampaignType.WEB_MAP_AD_BASE);
				}
				this.islandsToLoad += adIslands.length;
			}
			
			// Get Island Partitions :: 0229
			trace ( " Map :: setupPartitions" );
			var partition:IslandPartition;
			for each(var partitionXML:XML in island_partitionsXML)
			{
				partition = new IslandPartition(partitionXML);
				this.islandsToLoad += partition.islandNum;
				partitions.push(partition);	// add new partition to collection
			}
			
			this.partition_current = partitions[0]; // set current partition
			this.numIslands = this.islandsToLoad;
			
			// Get and Load Islands from Partitions :: 0229
			trace ( " Map :: setupIslands :: total islands to load " + this.islandsToLoad );
			for each(partition in partitions)
			{
				// setup partitions
				setupIslandsInPartition(partition);
				
				// init and setup banner
				initBanner(partition);
			}
			
			
			// AD SPECIFIC
			if(AppConfig.adsActive)
			{
				var path:String;
				
				// for each campaign in array of ad islands
				for each(var campaignName:String in adIslands)
				{
					// if mobile, then load MMQ or map driver content
					if (AppConfig.mobile)
					{
						path = AdvertisingConstants.AD_PATH_KEYWORD + "/" + campaignName + "/map/";
						super.loadFiles([path + "island.swf", path + "island.xml"], true, true, Command.create(mobileMapDriverLoaded, campaignName));
					}
					else
					{
						// if browser, then load ad driver PNGs
						// get ad data by campaign name
						var adData:AdData = AdManager(super.shellApi.adManager).getAdDataByCampaign(campaignName);
						if ((adData) && (adData.campaign_file2))
						{
							path = super.shellApi.assetPrefix + "mapDrivers/" + adData.campaign_file2;
							super.shellApi.loadFilesReturn([path], Command.create(webMapDriverLoaded, campaignName));
						}
						else
						{
							this.islandLoaded();
						}
					}
				}
			}
		}
		
		private function initBanner(partition:IslandPartition):void
		{
			if(partition.name == null || partition.name == "")
				return;	// terminate -- don't make banner if no text to display
			
			this.loadFile("shared/banner.swf", Command.create(setupBanner, partition));
		}
		
		private function setupBanner(clip:DisplayObject, partition:IslandPartition):void
		{
			// disable mouse events on clip
			DisplayObjectContainer(clip).mouseEnabled = false;
			DisplayObjectContainer(clip).mouseChildren = false;
			
			// create entity from loaded clip
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
			var textField:TextField = clip["text"];
			
			// create and add banner component
			var banner:Banner = new Banner(textField, partition.page_start, partition.page_end);
			banner.setText(partition.name);
			entity.add(banner);
			
			// put banner in islandContainer
			var islandContainer:DisplayObjectContainer = this._hitContainer["map"]["content"]["islands"];
			islandContainer.addChild(Display(entity.get(Display)).displayObject);
			
			// set banner's entity's position
			var background:DisplayObject = this._hitContainer["map"]["background"];
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = (background.width * 0.5) + (background.width * (partition.page_start - 1));
			spatial.y = background.height * 0.82;
			
			// add spatial addition
			entity.add(new SpatialAddition());
			
			// add banner to collection
			banners.push(entity);
		}
		
		/**
		 * When mobile MMQ content or map driver is loaded 
		 * @param campaignName
		 */
		private function mobileMapDriverLoaded(campaignName:String):void
		{
			var path:String 	= AdvertisingConstants.AD_PATH_KEYWORD + "/" + campaignName + "/map/";
			var clip:MovieClip 	= this.getAsset(path + "island.swf", true, true);
			var islandXML:XML 	= this.getData(path + "island.xml", true, true);
			
			// if content loaded
			if(clip && islandXML)
			{
				// get ad islands data from map/maps/mobile.xml
				var adIslandsXML:XMLList = this.mapXML.adIslands.children();
				// get ad data by campaign name
				var adData:AdData = AdManager(this.shellApi.adManager).getAdDataByCampaign(campaignName);
				if (adData)
				{
					// get last number from campaign type and use as slot
					var slot:int = int(adData.campaign_type.substr(-1));
					// get slot data
					var adIslandXML:XML = adIslandsXML[slot - 1] as XML;
					if(adIslandXML)
					{
						// position map icon on map
						positionOnMap(clip, adIslandXML);
						
						// place on map and create button
						this.placeIsland(clip, islandXML);
						
						// map impression tracking
						this.shellApi.adManager.track(campaignName, AdTrackingConstants.TRACKING_MAP_IMPRESSION, "Mobile Map Driver");
					}
				}
			}
			this.islandLoaded();
		}
		
		/**
		 * When web map ad driver is loaded 
		 * @param clip (normally a png)
		 * @param campaignName
		 */
		private function webMapDriverLoaded(clip:DisplayObject, campaignName:String):void
		{
			if(clip)
			{
				// get ad islands data from map/maps/browser.xml
				var adIslandsXML:XMLList = this.mapXML.adIslands.children();
				// get ad data by campaign name
				var adData:AdData = AdManager(this.shellApi.adManager).getAdDataByCampaign(campaignName);
				if (adData)
				{
					// get last number from campaign type and use as slot
					var slot:int = int(adData.campaign_type.substr(-1));
					// get slot data
					var adDriverXML:XML = adIslandsXML[slot - 1] as XML;
					if(adDriverXML)
					{
						// add png to container and center
						var container:MovieClip = new MovieClip();
						var art:DisplayObject = container.addChild(clip);
						art.x = -clip.width/2;
						art.y = -clip.height/2;
						
						// position ad driver on map
						positionOnMap(container, adDriverXML);
						
						// add to map
						var islandContainer:DisplayObjectContainer = this._hitContainer["map"]["content"]["islands"];
						islandContainer.addChild(container);
						
						// make into button
						var entity:Entity = ButtonCreator.createButtonEntity(container, this, Command.create(onAdDriverClicked, adData), null, null, null, false, true);
						entity.add(new Id(campaignName));
						
						// map impression tracking
						super.shellApi.adManager.track(campaignName, AdTrackingConstants.TRACKING_MAP_IMPRESSION, "Web Map Driver");
					}
				}
			}
			this.islandLoaded();
		}
		
		/**
		 * when ad driver is clicked
		 * @param entity
		 * @param adData
		 */
		private function onAdDriverClicked(entity:Entity, adData:AdData):void
		{
			// click tracking
			this.shellApi.adManager.track(adData.campaign_name, AdTrackingConstants.TRACKING_CLICKED, "Map");
			// go to url (http or pop)
			AdUtils.openSponsorURL(this.shellApi, adData.clickURL, adData.campaign_name, "Map", "Driver");
		}
		
		/**
		 * position ad icon on map 
		 * @param clip
		 * @param adIslandXML
		 */
		private function positionOnMap(clip:MovieClip, adIslandXML:XML):void
		{
			var background:DisplayObject = this._hitContainer["map"]["background"];						
			var page:int = int(adIslandXML.page);
			clip.x = Number(adIslandXML.x) * background.width + (page - 1) * background.width;
			clip.y = Number(adIslandXML.y) * background.height;
		}
		
		/**
		 * setup islands in the partition :: 0229
		 * @param partition
		 * @auther uhendba
		 */
		private function setupIslandsInPartition(partition:IslandPartition):void
		{
			// 1. set page start of this partition
			partition.page_start = this.numPages + 1;
			
			// 2. check for custom location group
			var locationGroup:XMLList = (partition.locationGroup == null || partition.locationGroup == "") ? null : this.locationGroupByName(partition.locationGroup); 
			
			// 3. set page size
			var pageSize:int;
			if(locationGroup == null)
			{
				pageSize = (partition.islandNum >= 5) ? PAGE_SIZE_DEFAULT : partition.islandNum;
				locationGroup = this.defaultLocationGroupByPageSize(pageSize);
			}	
			else
			{
				pageSize = locationGroup.parent().descendants("location").length();
			}
				
			// 4. set island scale
			var islandScale:Number = (locationGroup[0].parent().@scale != undefined) ? locationGroup[0].parent().@scale : 1;	// bit of a hack to use locationGroup[0] as we need to get the list's parent node to get the attribute -- works in 99% cases but will throw an error if no elements
			
			// 5. setup islands!
			for (var i:int = 0; i < partition.islandNum; i++)
			{
				var islandName:String = String(partition.islands[i]);
				var page_i:int = this.numPages + 1 + Math.floor(i / pageSize);
				var mapIslandLoader:MapIslandLoader = new MapIslandLoader(this, islandName, true, islandScale);
				mapIslandLoader.loaded.add(Command.create(setupIsland, partition.islands[i], page_i, pageSize, locationGroup));
				mapIslandLoader.load();
			}
			
			// 6. setup custom placements if any!
			for (var p:int = 0; p < partition.customPlacementNum; p++)
			{
				var page_p:int = this.numPages + 1 + Math.floor(p / pageSize);
				
				var placement:String = String(partition.customPlacements[p]);
				var placementLoader:CustomPlacementLoader = new CustomPlacementLoader(this, placement);
				placementLoader.loaded.add(Command.create(setupCustomPlacement, partition.customPlacements[p], page_p, pageSize, partition.locationGroup));
				placementLoader.load();
			}
			
			// 7. update this.numPages and finish!
			this.numPages += Math.ceil(partition.islandNum / pageSize); 
			partition.page_end = this.numPages;
		}
		
		/**
		 * setup islands :: 0229
		 * @param mapIslandLoader
		 * @param mapIslandXML
		 * @param pageSize
		 * @auther uhendba 
		 */
		private function setupIsland(mapIslandLoader:MapIslandLoader, mapIslandXML:XML, page:int, pageSize:int, locationGroup:XMLList):Boolean
		{
			var validLoad:Boolean = false;
			
			if(mapIslandLoader.entity)
			{
				validLoad = true;
				
				// island entity
				var entity:Entity = mapIslandLoader.entity;
				
				islands.push(entity);
				
				// 1. get and place displayObjectContainer into the islandContainer
				var display:DisplayObject = Display(entity.get(Display)).displayObject;
				var spatial:Spatial = entity.get(Spatial);
				var islandContainer:DisplayObjectContainer = this._hitContainer["map"]["content"]["islands"];
				islandContainer.addChild(display);
				
				// 2. setup islands's interaction
				var island:Entity = EntityUtils.getChildById(entity, "island");
				var button:Button = island.get(Button);
				button.value = mapIslandLoader.islandXML;
				var interaction:Interaction = island.get(Interaction);
				interaction.click.add(this.onIslandClicked);
				
				// 3. get islands's location data
				//var locationGroup:XMLList 	= (locationGroupName == null || locationGroupName == "") ? this.defaultLocationGroupByPageSize(pageSize) : this.locationGroupByName(locationGroupName); // get locations by pagesize or location group name
				var index:int 				= mapIslandXML.childIndex(); // get index
				var p:int					= index - (Math.floor(index / pageSize) * pageSize); // get index relative to the page
				
				var location:XML 			= locationGroup[p]; // get location
				
				// 4. set islands info
				var islandInfo:IslandInfo = entity.get(IslandInfo);
				islandInfo.page = page;	
				
				// 5. position island
				var background:DisplayObject = this._hitContainer["map"]["background"];
				spatial.x = Number(location.x) * background.width + (page - 1) * background.width;
				spatial.y = Number(location.y) * background.height;
				
				// 6. scale island
				if (location.parent().@scale != undefined)
				{
				spatial.scale = location.parent().@scale;
				}
				
				// bitmap island ?
				// DisplayUtils.convertToBitmapSprite(Display(entity.get(Display)).displayObject);
				
				if(mapIslandLoader.islandXML.hasOwnProperty("notification"))
				{
					var xml:XMLList = mapIslandLoader.islandXML.notification;
					
					// get platform
					var platform:String = "both";
					if(xml.hasOwnProperty("@platform"))
						platform = DataUtils.getString(xml.attribute("platform")[0]);
					
					// filter by platforms
					if ((platform == "both") || ((platform == "web") && (!AppConfig.mobile)) || ((platform == "mobile") && (AppConfig.mobile)))
					{
						var notification:String = String(xml);
						
						var asset:String = "shared/notification.swf";
						if(xml.hasOwnProperty("@asset"))
							asset = DataUtils.getString(xml.attribute("asset")[0]);
						
						var event:String = null;
						if(xml.hasOwnProperty("@event"))
							event = DataUtils.getString(xml.attribute("event")[0]);
						
						var showNotification:Boolean = true;
						if(DataUtils.validString(event))
						{
							var params:Array = event.split(",");
							var eventName:String = params[0];
							var islandName:String = null;
							if(params.length > 1)
							{
								islandName = params[1];
								islandName = islandName.replace(" ","");// take out spaces
							}
							if(eventName.indexOf("gotItem_")>= 0)
							{
								if(shellApi.checkHasItem(eventName.substr(8), islandName))
									showNotification = false;
							}
							else if(shellApi.checkEvent(eventName, islandName))
								showNotification = false;
						}
						if(showNotification)
							this.loadFile(asset, notificationLoaded, notification, entity);
					}
				}
			}
			
			mapIslandLoader.destroy();
			
			// lego impressions
			if (islandInfo.name == "lego")
			{
				shellApi.adManager.track("LegoIsland", AdTrackingConstants.TRACKING_MAP_IMPRESSION);
				AdUtils.sendTrackingPixels(this.shellApi, "LegoIsland", LegoIslandImpression, AdTrackingConstants.TRACKING_MAP_IMPRESSION);
			}
			// lego impressions
			if (islandInfo.name == "americanGirl")
			{
				shellApi.adManager.track("AmericanGirlIsland", AdTrackingConstants.TRACKING_MAP_IMPRESSION);
				AdUtils.sendTrackingPixels(this.shellApi, "AmericanGirlIsland", AmericanGirlIslandImpression, AdTrackingConstants.TRACKING_MAP_IMPRESSION);
			}
			this.islandLoaded();
			
			return validLoad;
		}
		
		private function setupCustomPlacement(placementLoader:CustomPlacementLoader, placementXML:XML, page:int, pageSize:int, locationGroupName:String):Boolean
		{
			var validLoad:Boolean = false;
			
			if(placementLoader.entity)
			{
				validLoad = true;
				var entity:Entity = placementLoader.entity;
				customPlacements.push(entity);
				
				// 1. get and place displayObjectContainer into the islandContainer
				var display:DisplayObject = Display(entity.get(Display)).displayObject;
				var spatial:Spatial = entity.get(Spatial);
				var islandContainer:DisplayObjectContainer = this._hitContainer["map"]["content"]["islands"];
				var background:DisplayObject = this._hitContainer["map"]["background"];
				islandContainer.addChild(display);
				
				// 2. setup placement's interaction
				var placement:Entity = EntityUtils.getChildById(entity, "placement");
				var button:Button = placement.get(Button);
				//button.value = mapIslandLoader.islandXML;
				var interaction:Interaction = placement.get(Interaction);
				interaction.click.add(Command.create(onPlacementClicked, placementXML));
				
				// 3. get placement's location data
				var locationGroup:XMLList 	= this.locationGroupByName(locationGroupName); // get locations by group name (as this SHOULD be a custom location group)
				var index:int 				= placementXML.childIndex(); // get index
				var p:int					= index - (Math.floor(index / pageSize) * pageSize); // get index relative to the page
				var location:XML 			= locationGroup.parent().descendants("custom")[0]; // get custom location
				
				// 4. position placement
				spatial.x = Number(location.x) * background.width + (page - 1) * background.width;
				spatial.y = Number(location.y) * background.height;
				
			}
			
			// cleanup
			placementLoader.destroy();
			return validLoad;
		}
		
		private function onPlacementClicked(entity:Entity, placementXML:XML):void
		{
			switch(String(placementXML.@type))
			{
				case POPWORLDS_POPUP:
					// PopWorlds Popup :: Activate Popup
					var placementPopup:PopWorldsPopup = new PopWorldsPopup(String(placementXML), this.overlayContainer);
					this.addChildGroup(placementPopup);
					
					break;
			}
		}
		
		/**
		 * get default locations to position islands by pageSize :: 0229
		 * @param pageSize
		 * @auther uhendba 
		 */
		private function defaultLocationGroupByPageSize(pageSize:int):XMLList
		{
			var locationGroups:XMLList 	= this.mapXML.locations.children();
			var locations:XMLList;
			switch(pageSize)
			{
				case PAGE_SIZE_SMALLEST:
					locations = locationGroups.(@size == PAGE_SIZE_SMALLEST).children();
					break;
				case PAGE_SIZE_SMALL:
					locations = locationGroups.(@size == PAGE_SIZE_SMALL).children();
					break;
				case PAGE_SIZE_MEDIUM:
					locations = locationGroups.(@size == PAGE_SIZE_MEDIUM).children();
					break;
				default:
					locations = locationGroups.(@size == PAGE_SIZE_DEFAULT).children();
					break;
			}
			
			return locations;
		}
		
		/**
		 * get custom location group by name to position islands by pageSize :: 0229
		 * @param groupName
		 * @auther uhendba 
		 */
		private function locationGroupByName(groupName:String):XMLList
		{
			var locationGroups:XMLList = this.mapXML.locations.children();
			var locationGroup:XMLList;
			
			for each(var xml:XML in locationGroups)
			{
				if(xml.@name == groupName)
				{
					locationGroup = xml.children();
				}
			}
			
			if (locationGroup == null) throw new Error("No group found in Locations with the name of "+groupName+"\n did you create a new group node and set the name attribute correctly?");
			
			return locationGroup;
		}
		
		private function placeIsland(clip:MovieClip, islandXML:XML):Entity
		{
			var islandContainer:DisplayObjectContainer = this._hitContainer["map"]["content"]["islands"];
			islandContainer.addChild(clip);
			
			var island:String = String(islandXML.island);
			
			var entity:Entity = ButtonCreator.createButtonEntity(clip, this, this.onIslandClicked, null, null, null, false, true);
			entity.add(new Id(island));
			entity.get(Button).value = islandXML;	// TODO :: don't love storing teh xml in the button, might be better to use a Dict. - bard
			EntityCreator.addComponents(islandXML, entity);
			
			return entity;
		}
		
		private function islandLoaded():void
		{
			if(--this.islandsToLoad == 0)
			{
				this.sortIslands();
				this.setupMap();
				this.setupWaves();
				
				this.groupReady();
				
				this.setupAutoLoadIsland();
			}
		}
		
		private function sortIslands():void
		{
			this.islands.sort(compareIslands);
		}
		
		private function compareIslands(entity1:Entity, entity2:Entity):int
		{
			var islandInfo1:IslandInfo = entity1.get(IslandInfo);
			var islandInfo2:IslandInfo = entity2.get(IslandInfo);
			
			if(islandInfo1.page < islandInfo2.page)
			{
				return -1;
			}
			if(islandInfo1.page > islandInfo2.page)
			{
				return 1;
			}
			else
			{
				var spatial1:Spatial = entity1.get(Spatial);
				var spatial2:Spatial = entity2.get(Spatial);
				if(spatial1.y < spatial2.y)
				{
					return -1;
				}
				if(spatial1.y > spatial2.y)
				{
					return 1;
				}
				else
				{
					if(spatial1.x < spatial2.x)
					{
						return -1;
					}
					else if(spatial1.x > spatial2.x)
					{
						return 1;
					}
				}
			}
			return 0;
		}
		
		private function setupPreviousIslandPage():void
		{
			var island:String = this.shellApi.profileManager.active.previousIsland;
			if(island)
			{
				//AS2 island pop URL.
				if(island.indexOf("pop://") > -1)
				{
					var urlData:Object = ProxyUtils.parsePopURL(island);
					island = StringUtil.toLowerCamelCase(urlData.island);
				}
				
				var parts:Array = island.split(/(\d+)/);
				island = parts[0];
				
				trace(this, "Your previous island is", island);
				
				var islandEntity:Entity = this.getEntityById(island);
				if(islandEntity)
				{
					var spatial:Spatial = islandEntity.get(Spatial);
					var background:DisplayObject = this._hitContainer["map"]["background"];
					var page:int = Math.floor(spatial.x / background.width) + 1;
					this.setPage(page, true);
				}
			}
		}
		
		private function setupAutoLoadIsland():void
		{
			// TODO :: Explain this.
			if(this.autoLoadIsland)
			{
				var parts:Array = this.autoLoadIsland.split(/(\d+)/);
				var island:String = parts[0];
				
				//This is the entity with the island button, progress bar, and name.
				var islandEntity:Entity = this.getEntityById(island);
				if(islandEntity)
				{
					//This is the actual island.
					var buttonEntity:Entity = EntityUtils.getChildById(islandEntity, "island");
					if(buttonEntity)
					{
						//Get the island's Button to grab it's XML info.
						var button:Button = buttonEntity.get(Button);
						if(button)
						{
							var islandPopup:IslandPopup = new IslandPopup(this.overlayContainer);
							islandPopup.islandXML 		= button.value;
							islandPopup.autoFlipPage	= parts[1] ? int(parts[1]) : -1;
							this.addChildGroup(islandPopup);
						}
					}
				}
			}
		}
		
		private function setupMap():void
		{
			//Scrolling Map
			this._hitContainer["map"].mouseChildren = true;
			
			var content:DisplayObjectContainer = this._hitContainer["map"]["content"];
			
			var background:DisplayObject = this._hitContainer["map"]["background"];
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, content);
			entity.add(new SpatialAddition());
			entity.add(new Id("map"));
			entity.add(new MapControl());
			
			var book:Book = new Book(1, this.numPages, background.width, background.height);
			book.minDelta = 1;
			//book.pageTurnFinished.add(this.pageTurnFinished);
			entity.add(book);
			
			//Gradients
			var width:Number = background.width * this.numPages - 240;
			var x:Number = this.numPages * background.width;
			
			var i:int;
			/*
			content["edge1"].width 	= width;
			content["edge2"].height = background.height - 240;
			content["edge3"].x		= x;
			content["edge3"].height = background.height - 240;
			content["edge4"].y 		= background.height;
			content["edge4"].width 	= width;
			
			content["corner2"].x = x;
			content["corner3"].y = background.height;
			content["corner4"].x = x;
			content["corner4"].y = background.height;
			
			for(i = 1; i <= 4; i++)
			{
			this.convertToBitmap(content["corner" + i]);
			this.convertToBitmap(content["edge" + i]);
			}*/
			
			//Page Buttons
			for(i = 0; i < this.numPages; i++)
			{
				this.shellApi.loadFile(this.shellApi.assetPrefix + "ui/general/radioButton.swf", buttonLoaded, i);
			}
		}
		
		private function pageTurnFinished(book:Book):void
		{
			this.trackPageChange();
		}
		
		private function onMapSwipe(entity:Entity):void
		{
			var swipe:Swipe = entity.get(Swipe);
			
			var distanceX:Number = swipe.stopX - swipe.startX;
			if(Math.abs(distanceX) < 50) return;
			
			var book:Book = this.getEntityById("map").get(Book);
			if(book.page == 1 && distanceX > 0) return;
			if(book.page == book.numPages && distanceX < 0) return;
			
			var page:int = (distanceX < 0) ? 1 : -1;
			this.setPage(book.page + page);
		}
		
		private function setPartition(page:int):int	// return direction -1 (left) , 1 (right), 0 (none)
		{
			var partition:IslandPartition = partitionOnPage(page);
			if(partition == partition_current)
				return 0; // terminate
			
			this.partition_current = partition;	// update current partition
			
			return (partition.page_end < page) ? 1 : -1; // return direction
		}
		
		/*
		private function setBanner(direction:int):void
		{
		if(direction == 0)
		return; // terminate
		
		// swap banner shown
		this.banner_shown = (this.banner_shown != this.bannerA) ? this.bannerA : this.bannerB;
		var banner_hidden:Entity = (this.banner_shown != this.bannerA) ? this.bannerA : this.bannerB;
		
		// update and show current
		if(this.partition_current.name != null && this.partition_current.name != "")
		{
		Banner(this.banner_shown.get(Banner)).setText(this.partition_current.name);
		Display(this.banner_shown.get(Display)).visible = true;			// show banner
		}
		else
		{
		Display(this.banner_shown.get(Display)).visible = false;		// hide banner
		}
		
		
		var background:DisplayObject 	= this._hitContainer["map"]["background"];
		
		var tween_show:Tween 			= this.banner_shown.get(Tween);
		var tween_hide:Tween 			= banner_hidden.get(Tween);
		
		var spatial_show:Spatial 		= this.banner_shown.get(Spatial);
		var spatial_hide:Spatial 		= banner_hidden.get(Spatial);
		
		// slide in/out banners
		if(direction > 0)
		{
		tween_show.to(spatial_show, 2.0, {x:background.width * 0.5});
		tween_hide.to(spatial_hide, 2.0, {x:background.width * 1.5});
		}
		else
		{
		tween_show.to(spatial_show, 2.0, {x:background.width * 0.5});
		tween_hide.to(spatial_hide, 2.0, {x:background.width * -1.5});
		}
		}
		*/
		
		private function partitionOnPage(page:int):IslandPartition
		{
			for each(var partition:IslandPartition in partitions)
			{
				if(page >= partition.page_start && page <= partition.page_end)
					return partition;
			}
			
			return null;
		}
		
		private function setPage(page:int, invalidate:Boolean = false):void
		{
			// update book
			var book:Book = this.getEntityById("map").get(Book);
			if(book.page == page && !invalidate) return;
			book.page = page;
			
			// update partition
			setPartition(page);
			
			this.trackPageChange();
			
			for(var index:int = 1; this.getEntityById("pageButton" + index); ++index)
			{
				var pageButton:Entity = this.getEntityById("pageButton" + index);
				
				var button:Button 	= pageButton.get(Button);
				button.isSelected 	= index == page;
				button.invalidate 	= true;
				
				index == page ? button.downHandler() : button.outHandler();
			}
			
			if(book.page == 1)
			{
				Display(this.getEntityById("arrowLeft").get(Display)).visible = false;
				ToolTipCreator.removeFromEntity(this.getEntityById("pageLeft"));
			}
			else
			{
				Display(this.getEntityById("arrowLeft").get(Display)).visible = true;
				ToolTipCreator.addToEntity(this.getEntityById("pageLeft"), ToolTipType.EXIT_LEFT);
			}
			if(book.page == book.numPages)
			{
				Display(this.getEntityById("arrowRight").get(Display)).visible = false;
				ToolTipCreator.removeFromEntity(this.getEntityById("pageRight"));
			}
			else
			{
				Display(this.getEntityById("arrowRight").get(Display)).visible = true;
				ToolTipCreator.addToEntity(this.getEntityById("pageRight"), ToolTipType.EXIT_RIGHT);
			}
			//Display(this.getEntityById("arrowLeft").get(Display)).visible 	= (book.page == 1) ? false : true;
			//Display(this.getEntityById("arrowRight").get(Display)).visible 	= (book.page == book.numPages) ? false : true;
		}
		
		private function trackPageChange():void
		{
			var islandData:Array = this.getIslandsAndProgressesAndPage();
			
			var vars:URLVariables = new URLVariables();
			vars.context = 	"map_islands_shown:" + islandData[0] + ";" +
				"map_islands_shown_percentage_done:" + islandData[1] + ";" +
				"map_page_map_islands_shown:" + islandData[2];
			vars.dimensions = new Object();
			vars.dimensions["map_islands_shown"] = islandData[0];
			vars.dimensions["map_islands_shown_percentage_done"] = islandData[1];
			vars.dimensions["map_page_map_islands_shown"] = islandData[2];
			this.shellApi.track("MapPageChanged", null, null, null, null, null, null, vars);
		}
		
		/**
		 * Returns an Array of 2 items in the format of [islands, progresses, page].
		 */
		private function getIslandsAndProgressesAndPage():Array
		{
			var book:Book = this.getEntityById("map").get(Book);
			
			var entity:Entity;
			var islandInfo:IslandInfo;
			var progress:Number;
			
			var pageIslands:Array = [];
			
			for each(entity in this.islands)
			{
				islandInfo = entity.get(IslandInfo);
				if(islandInfo.page == book.page)
				{
					pageIslands.push(entity);
				}
			}
			
			var islandsList:String = "";
			var progressesList:String = "";
			
			for each(entity in pageIslands)
			{
				islandInfo = entity.get(IslandInfo);
				if(islandInfo.numEpisodes <= 0)
				{
					islandsList += islandInfo.name + "|";
					progressesList += int(islandInfo.progresses[0] * 100) + "|";
				}
				else
				{
					for(var index:int = 0; index < islandInfo.numEpisodes; ++index)
					{
						islandsList += islandInfo.name + (index + 1) + "|";
						progressesList += int(islandInfo.progresses[index] * 100) + "|";
					}
				}
			}
			
			//Remove the last extra ";".
			islandsList = islandsList.substr(0, islandsList.length - 1);
			progressesList = progressesList.substr(0, progressesList.length - 1);
			trace(islandsList);
			trace(progressesList);
			trace(book.page);
			return [islandsList, progressesList, book.page];
		}
		
		private function buttonLoaded(clip:MovieClip, i:int):void
		{
			var pages:DisplayObjectContainer = this._hitContainer["map"]["pages"];
			var background:DisplayObject = this._hitContainer["map"]["background"];
			
			Alignment.centerAtIndex(clip, "x", background.width * 0.5, 40, i, this.numPages);
			clip.y = background.height - 40;
			pages.addChild(clip);
			
			var entity:Entity = ButtonCreator.createButtonEntity(clip, this, turnToPage, null, null, null, true, true);
			
			++i;
			entity.add(new Id("pageButton" + i));
			
			var button:Button 	= entity.get(Button);
			button.value 		= i;
			
			if(i == 1)
			{
				button.isSelected = true;
				button.downHandler();
			}
			
			if(++this.pageButtonsLoaded == this.numPages)
			{
				this.setupPreviousIslandPage();
			}
		}
		
		private function turnToPage(pageButton:Entity):void
		{
			var book:Book 		= this.getEntityById("map").get(Book);
			var button:Button 	= pageButton.get(Button);
			
			this.setPage(button.value);
		}
		
		private function onIslandClicked(entity:Entity):void
		{
			var islandXML:XML = XML(entity.get(Button).value);
			var island:String = String(islandXML.island);
			// if members only and not member then show upsell popup for Legendary Swords
			if ((islandXML.membersOnly == "true") && (!this.shellApi.profileManager.active.isMember))
			{
				//var popup:LegendarySwordsMembership = new LegendarySwordsMembership(this.overlayContainer);
				if(shellApi.profileManager.active.isGuest) 
				{
					var popup:IslandBlockPopup = new IslandBlockPopup(groupPrefix, overlayContainer);
					this.addChildGroup(popup);
				}
				else
				{
					shellApi.profileManager.active.RefreshMembershipStatus(shellApi, Command.create(confirmMembership, entity));
				}
			}
			else
			{
				var islandFolder:String = islandXML.islandFolder;
				var arr:Array = islandFolder.split("/");
				
				var islandData:Array = this.getIslandsAndProgressesAndPage();
				
				var vars:URLVariables = new URLVariables();
				vars.context = 	"island_selected:" + island + ";" +
					"map_page_island_selected:" + islandData[2] + ";" +
					"map_islands_shown:" + islandData[0] + ";" +
					"map_islands_shown_percentage_done:" + islandData[1] + ";";
				vars.dimensions = new Object();
				vars.dimensions["island_selected"] = island;
				vars.dimensions["map_page_island_selected"] = islandData[2];
				vars.dimensions["map_islands_shown"] = islandData[0];
				vars.dimensions["map_islands_shown_percentage_done"] = islandData[1];
				this.shellApi.track("MapIslandClicked", island, null, null, null, null, null, vars);
				
				// AD SPECIFIC
				// if map ad, then track click
				if (islandFolder.indexOf(AdvertisingConstants.AD_PATH_KEYWORD) != -1)
				{
					var campaignName:String = arr[1];
					this.shellApi.adManager.track(campaignName, AdTrackingConstants.TRACKING_CLICK_ON_ICON);
					// if pop URL, then load scene immediately
					var adData:AdData = AdManager(this.shellApi.adManager).getAdDataByCampaign(campaignName);
					if ((adData != null) && (adData.clickURL.indexOf("pop://") == 0))
					{
						AdUtils.openSponsorURL(this.shellApi, adData.clickURL, campaignName, "Map", "Icon");
						return;
					}
				}
				
				// add sponsored islands here (lowercase)
				// if lego island, then load scene immediately
				if (islandFolder.indexOf("lego") != -1)
				{
					this.shellApi.adManager.track("LegoIsland", AdTrackingConstants.TRACKING_CLICK_ON_ICON);
					// click tracking
					AdUtils.sendTrackingPixels(this.shellApi, "LegoIsland", LegoIslandClicked, AdTrackingConstants.TRACKING_CLICK_ON_ICON);
					shellApi.loadScene(game.scenes.lego.mainStreet.MainStreet);
					return;
				}
				if(islandFolder.indexOf("americanGirl") != -1)
				{
					// if ag island, then load scene immediately
					if (islandFolder.indexOf("americanGirlKira") != -1 )
					{
						this.shellApi.adManager.track("AmericanGirlIsland", AdTrackingConstants.TRACKING_CLICK_ON_ICON);
						// click tracking
						AdUtils.sendTrackingPixels(this.shellApi, "AmericanGirlIsland", AmericanGirlIslandClicked, AdTrackingConstants.TRACKING_CLICK_ON_ICON);
						shellApi.loadScene(game.scenes.americanGirl.mainStreetKira.MainStreetKira);
						return;
					}
					else
					{
						this.shellApi.adManager.track("AmericanGirlIsland", AdTrackingConstants.TRACKING_CLICK_ON_ICON);
						// click tracking
						AdUtils.sendTrackingPixels(this.shellApi, "AmericanGirlIsland", AmericanGirlIslandClicked, AdTrackingConstants.TRACKING_CLICK_ON_ICON);
						shellApi.loadScene(game.scenes.americanGirl.mainStreet.MainStreet);
						return;
					}
				}
				
				var islandPopup:IslandPopup = new IslandPopup(this.overlayContainer);
				islandPopup.islandXML 		= islandXML;
				this.addChildGroup(islandPopup);
			}
		}
		
		private function confirmMembership(entity:Entity):void
		{
			if(shellApi.profileManager.active.isMember)
			{
				onIslandClicked(entity);
			}
			else
			{
				var popup:IslandBlockPopup = new IslandBlockPopup(groupPrefix, overlayContainer);
				this.addChildGroup(popup);
			}
		}
		
		private function setupClouds():void
		{
			var background:DisplayObject = this._hitContainer["map"]["background"];
			var clouds:DisplayObjectContainer = this._hitContainer["map"]["content"];
			
			for(var i:int = 1; i <= 5; i++)
			{
				var clip:DisplayObjectContainer = clouds["cloud" + i];
				clip.mouseEnabled = false;
				clip.filters = [cloudShadow, cloudOutline];
				
				for(var j:int = 1; j <= 3; j++)
				{
					this.convertToBitmap(clip["part" + j]);
				}
				
				var entity:Entity = EntityUtils.createMovingEntity(this, clip);
				
				var display:Display = entity.get(Display);
				display.alpha = 0.75;
				entity.add(new MapCloud());
				
				var spatial:Spatial = entity.get(Spatial);
				spatial.x = Utils.randNumInRange(0, background.width);
				
				this.resetCloud(entity);
			}
		}
		
		private function resetCloud(entity:Entity):void
		{
			//Reset cloud parts
			for(var i:int = 1; i <= 3; i++)
			{
				var part:DisplayObject = Display(entity.get(Display)).displayObject.getChildByName("part" + i);
				part.x = Utils.randNumInRange(-75, 75);
				part.y = Utils.randNumInRange(-10, 10);
				part.scaleX = Utils.randNumInRange(1, 1.5);
				part.scaleY = part.scaleX * Utils.randNumInRange(0.4, 0.6);
			}
			
			var background:DisplayObject = this._hitContainer["map"]["background"];
			Spatial(entity.get(Spatial)).y = Utils.randNumInRange(00, background.height - 50);
			
			var motion:Motion = entity.get(Motion);
			motion.velocity.x = Utils.randNumInRange(-100, -50);
		}
		
		private function setupWaves():void
		{
			for(var x:int = 0; x < this.numPages; x++)
			{
				for(var i:int = 1; i <= 10; i++)
				{
					//this.loadFile("shared/wave.swf", this.waveLoaded, x * WINDOW_WIDTH);
					super.shellApi.loadFile(this.shellApi.assetPrefix + super.groupPrefix + "shared/wave.swf", this.waveLoaded, x * this.shellApi.viewportWidth);
				}
			}
		}
		
		private function waveLoaded(clip:MovieClip, x:int):void
		{
			var map:MovieClip = this._hitContainer["map"];
			
			var background:DisplayObject = map["background"];
			
			var waves:DisplayObjectContainer = map["content"]["waves"];
			clip.x 				= Utils.randNumInRange(x + 100, x + background.width - 100);
			clip.y 				= Utils.randNumInRange(150, background.height - 150);
			clip.mouseChildren 	= false;
			clip.mouseEnabled 	= false;
			waves.addChildAt(clip, 0);
			
			for(var i:int = 1; i <= 3; i++)
			{
				var entity:Entity = EntityUtils.createSpatialEntity(this, clip["wave" + i]);
				entity.add(new SpatialAddition());
				
				var wave:WaveMotion = new WaveMotion();
				wave.data.push(new WaveMotionData("scaleY", 0.5, 2, "sin", i, true));
				entity.add(wave);
			}
		}
		
		/**
		 * TEMPORARY function to deal with format disprecencies in map xml bewteen mobile versions. 
		 * Possible versions include:
		 * 
		 *  <island>carrot</island>
		 * 
		 * -or-
		 * 
		 *	<island>
		 *		<islandFolder>myth/</islandFolder>
		 *		<page>1</page>
		 *		<x>480</x>
		 *		<y>320</y>
		 *	</island>
		 * 
		 * - or -
		 * 
		 * 	<island id="virusHunter">
		 *		<page>1</page>
		 *		<x>200</x>
		 *		<y>370</y>
		 *	</island>
		 *
		 * @param islandXML
		 * @return 
		 * 
		 */
		private function getIslandFromXml( islandXML:XML ):String
		{
			trace ( " Map :: getIslandFromXml :: looking for island in islandsXML : " + islandXML );
			
			var islandName:String;
			
			// check for various formats to retrieve island name
			if( islandXML.hasOwnProperty("islandFolder") )
			{
				islandName = DataUtils.getString( islandXML.islandFolder );
				var slashIndex:int = islandName.lastIndexOf( "/" );
				if( slashIndex != -1 )
				{
					islandName = islandName.slice(0, slashIndex);
				}
			}
			else if ( DataUtils.validString( DataUtils.getString(islandXML.attribute("id") ) ) )
			{
				islandName = DataUtils.getString(islandXML.attribute("id"));
			}
			else
			{
				islandName = DataUtils.getString( islandXML );
			}
			return islandName;
		}
		
		private function notificationLoaded(clip:MovieClip, text:String, entity:Entity):void
		{
			if(clip)
			{
				clip.mouseChildren = false;
				clip.mouseEnabled = false;
				clip.scaleX = 0;
				clip.scaleY = 0;
				
				var container:DisplayObjectContainer = Display(entity.get(Display)).displayObject;
				container.addChild(clip);
				
				var anim:MovieClip = clip["animation"];
				if(anim != null)//keeping animation and text separate
				{
					container.addChild(anim);
					container.setChildIndex(anim, 0);
					TimelineUtils.convertAllClips(anim, entity);
				}
				
				var notification:Entity = EntityUtils.createSpatialEntity(this, clip);
				notification.add(new Id("notification"));
				notification.add(new Tween());
				EntityUtils.addParentChild(notification, entity);
				
				var textfield:TextField = TextUtils.refreshText(TextField(clip.getChildByName("notification")));
				var bubble:DisplayObject = clip.getChildByName("bubble");
				
				textfield.mouseEnabled = false;
				textfield.autoSize = TextFieldAutoSize.LEFT;
				textfield.htmlText = TextUtils.formatAsBlock(text);
				
				textfield.x = -textfield.width/2;
				textfield.y = -textfield.height;
				
				bubble.x = textfield.x - 2;
				bubble.y = textfield.y - 2;
				bubble.width = textfield.width + 4;
				bubble.height = textfield.height + 4;
				
				var island:Entity = EntityUtils.getChildById(entity, "island");
				var interaction:Interaction = island.get(Interaction);
				interaction.over.add(notificationIn);
				interaction.out.add(notificationOut);
			}
		}
		
		private function notificationIn(entity:Entity):void
		{
			var notification:Entity = EntityUtils.getChildById(EntityUtils.getParent(entity), "notification");
			var tween:Tween = notification.get(Tween);
			var spatial:Spatial = notification.get(Spatial);
			tween.killAll();
			tween.to(spatial, (1 - spatial.scaleX) * 0.5, {scaleX:1, scaleY:1});
		}
		
		private function notificationOut(entity:Entity):void
		{
			var notification:Entity = EntityUtils.getChildById(EntityUtils.getParent(entity), "notification");
			var tween:Tween = notification.get(Tween);
			var spatial:Spatial = notification.get(Spatial);
			tween.killAll();
			tween.to(spatial, (spatial.scaleX - 0) * 0.5, {scaleX:0, scaleY:0});
		}
	}
}

/***
 * IslandPartition
 * Simple internal data struct to hold island partition data
 * @Author: uhendba :: 0299
 */
class IslandPartition
{
	public var name:String;
	public var locationGroup:String;
	public var page_start:int;
	public var page_end:int;
	
	public var xml:XML;
	
	internal var islands:Vector.<XML> = new Vector.<XML>();
	internal var customPlacements:Vector.<XML> = new Vector.<XML>();
	
	public function IslandPartition(partitionXML:XML):void{
		// get name of partition
		this.name = partitionXML.@name;	
		this.locationGroup = partitionXML.@location_group;
		this.xml = partitionXML;
		
		// get island and store island data
		for each(var islandXML:XML in partitionXML.descendants("island"))
		{
			islands.push(islandXML);
		}
		
		// get any custom placements
		for each(var customXML:XML in partitionXML.descendants("custom"))
		{
			customPlacements.push(customXML);
		}
	}
	
	public function get islandNum():int
	{
		return islands.length;
	}
	
	public function get customPlacementNum():int
	{
		return customPlacements.length;
	}
	
	public function ToString():String
	{
		var s:String = "  :: "+this.name+"\n";
		for each(var islandXML:XML in islands)
		{
			s += "   "+String(islandXML) +"\n";
		}
		return s;
	}
}