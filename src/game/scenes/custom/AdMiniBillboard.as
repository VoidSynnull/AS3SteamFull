package game.scenes.custom
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.systems.AudioSystem;
	import engine.util.Command;
	
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.ads.AdData;
	import game.data.ads.AdTrackingConstants;
	import game.data.ui.ToolTipType;
	import game.managers.HouseVideos;
	import game.managers.ads.AdManager;
	import game.scene.template.GameScene;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.utils.AdUtils;
	
	public class AdMiniBillboard
	{
		public const PADDING_HORIZONTAL:Number = 20;
		public const PADDING_VERTICAL:Number = 30;
		
		public const minibillboard_WIDTH:int = 390;
		public const minibillboard_HEIGHT:int = 208;
		public const minibillboard_DELAY:int = 10;
		
		private var _scene:GameScene;
		private var _shellApi:ShellApi;
		private var _minibillboardLoadCounter:int;
		private var _hasBillboard:Boolean = false;
		private var _currentSlot:int = 0; // zero is used for default billboard
		private var _slots:Array = [true, false, false, false, false, false, false, false, false, false, false];
		private var _slotData:Array = [null, null, null, null, null, null];
		private var _minibillboardHasTimer:Boolean = false;
		private var _externalBillboard:Boolean = false;
		private var _miniBillboardClip:DisplayObjectContainer;
		private var _miniBillboardEntity:Entity;
		
		private var _useVideoButton:Boolean = false;
		private var adVideosRemaining:int = 3;
		private var adVideosButton:Entity;
		private var _moveToBack:Boolean = true;
		
		public function AdMiniBillboard(scene:GameScene,shell:ShellApi, position:Point=null, assetPath:String=null,moveToBack:Boolean=true)
		{
			_scene = scene;
			_shellApi = shell;
			_moveToBack = moveToBack;	
			/*
			if(position != null)
			{
				if(assetPath != null)
					_scene.shellApi.loadFile(_scene.shellApi.assetPrefix + assetPath, Command.create(setupLoadedMiniBillboard, position));
				else
					_scene.shellApi.loadFile(_scene.shellApi.assetPrefix + "minibillboard/minibillboard.swf", Command.create(setupLoadedMiniBillboard, position));
				_externalBillboard = true;
			}
			else
				setupMiniBillboard();
			*/
			
			
		}
		private function setupLoadedMiniBillboard(clip:DisplayObjectContainer, position:Point):void
		{
			_miniBillboardClip = clip["minibillboard"];
			//_scene.hitContainer.addChild(clip["minibillboard"]);
			_miniBillboardClip.x = position.x;
			_miniBillboardClip.y = position.y;
			var MiniBillboardContainer:DisplayObjectContainer 	= clip;
			MiniBillboardContainer.mouseChildren 				= false;
			MiniBillboardContainer.mouseEnabled 				= true;
			
			// play videos
			if(_useVideoButton)
			{
				var videos:HouseVideos = new HouseVideos(_scene, "PlaywireBillboardVideos");
				adVideosButton = ButtonCreator.createButtonEntity(_miniBillboardClip["watchVideo"], _scene, videos.playVideos);
			}
			else
			{
				if(_miniBillboardClip["watchVideo"] != null)
					_miniBillboardClip.removeChild(_miniBillboardClip["watchVideo"]);
			}
			// get files from cms
			var hasSlots:Boolean = false;
			// check 10 slots
			for (var i:int = 1; i != 11; i++)
			{
				// get ad data for slot
				if(_shellApi.adManager)
				{
					var adData:AdData = AdManager(_shellApi.adManager).getMiniBillboardSlot(i);
					// if found and has file data
					if ((adData) && ((adData.campaign_file1) || (adData.campaign_file2)))
					{
						// filter out zomberry billboards
						if (adData.campaign_name.toLowerCase().indexOf("zomberry") == 0) {
							continue;
						}
						// filter out haxe billboards
						if (adData.campaign_name.toLowerCase().indexOf("haxe") == 0) {
							continue;
						}
						var imagePath:String;
						var isVideo:Boolean = false;
						// if video path in file2
						if (adData.campaign_file2.indexOf("video/") == 0)
						{
							imagePath = adData.campaign_file1;
							isVideo = true;
						}
						else if (adData.campaign_file2)
						{
							imagePath = adData.campaign_file2;
						}
						else if (imagePath = adData.campaign_file1)
						{
							imagePath = adData.campaign_file1;
						}
						else
						{
							continue;
						}
						
						hasSlots = true;
						
						var path:String
						// Note: make sure the swf is pushed live or this will fail on mobile
						// check if file2 starts with "images/"
						if (imagePath.substr(0,7) == "images/")
						{
							trace("Getting external billboard: " + imagePath);
							path = "https://" + _shellApi.siteProxy.fileHost + "/" + imagePath;
							var loader:Loader = new Loader();
							loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, Command.create(gotExternalBillboard, i, adData, isVideo));
							loader.contentLoaderInfo.addEventListener(Event.COMPLETE, Command.create(gotExternalBillboard, i, adData, isVideo));
							var url:URLRequest = new URLRequest(path);
							var loaderContext:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
							loader.load(url, loaderContext);			
						}
						else
						{
							path = _shellApi.assetPrefix + _scene.groupPrefix + "limited/" +  imagePath;
							// note that this will pull from the LIVE server if not found locally
							_shellApi.loadFile( path, minibillboardImageLoaded, i, adData, isVideo);
						}
						// increment load counter
						_minibillboardLoadCounter++;
					}
				}
			}
		}
		
		private function setupMiniBillboard():void
		{
			var MiniBillboardContainer:DisplayObjectContainer 	= _scene.hitContainer["minibillboard"];
			MiniBillboardContainer.mouseChildren 				= false;
			MiniBillboardContainer.mouseEnabled 					= true;
			
			// play videos
			if(_useVideoButton)
			{
				var videos:HouseVideos = new HouseVideos(_scene, "PlaywireBillboardVideos");
				adVideosButton = ButtonCreator.createButtonEntity(MiniBillboardContainer["watchVideo"], _scene, videos.playVideos);
			}
			else
			{
				MiniBillboardContainer.removeChild(MiniBillboardContainer["watchVideo"]);
			}
			
			// get files from cms
			var hasSlots:Boolean = false;
			// check 10 slots
			for (var i:int = 1; i != 11; i++)
			{
				// get ad data for slot
				if(_shellApi.adManager)
				{
					var adData:AdData = AdManager(_shellApi.adManager).getMiniBillboardSlot(i);
					// if found and has file data
					if ((adData) && ((adData.campaign_file1) || (adData.campaign_file2)))
					{
						var imagePath:String;
						var isVideo:Boolean = false;
						// if video path in file2
						if (adData.campaign_file2.indexOf("video/") == 0)
						{
							imagePath = adData.campaign_file1;
							isVideo = true;
						}
						else if (adData.campaign_file2)
						{
							imagePath = adData.campaign_file2;
						}
						else if (imagePath = adData.campaign_file1)
						{
							imagePath = adData.campaign_file1;
						}
						else
						{
							continue;
						}
						
						hasSlots = true;
						
						var path:String
						// Note: make sure the swf is pushed live or this will fail on mobile
						// check if file2 starts with "images/"
						if (imagePath.substr(0,7) == "images/")
						{
							trace("Getting external billboard: " + imagePath);
							path = "https://" + _shellApi.siteProxy.fileHost + "/" + imagePath;
							var loader:Loader = new Loader();
							loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, Command.create(gotExternalBillboard, i, adData, isVideo));
							loader.contentLoaderInfo.addEventListener(Event.COMPLETE, Command.create(gotExternalBillboard, i, adData, isVideo));
							var url:URLRequest = new URLRequest(path);
							var loaderContext:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, null);
							loader.load(url, loaderContext);			
						}
						else
						{
							path = _shellApi.assetPrefix + _scene.groupPrefix + "limited/" +  imagePath;
							// note that this will pull from the LIVE server if not found locally
							_shellApi.loadFile( path, minibillboardImageLoaded, i, adData, isVideo);
						}
						// increment load counter
						_minibillboardLoadCounter++;
					}
				}
			}
			// if minibillboard slots, then hide default billboard
			var defaultBillbaoard:DisplayObject = _scene.hitContainer["defaultBillboard"];
			trace("is there a default billbaoard? " + defaultBillbaoard);
			if (hasSlots && defaultBillbaoard)
				defaultBillbaoard.visible = false;
		}
		
		private function gotExternalBillboard(event:Event, numSlot:int, adData:AdData, isVideo:Boolean):void
		{
			trace("got external billboard: " +  event.toString());
			trace("target: " + event.target);
			trace("content: " + event.target.content);
			minibillboardImageLoaded(event.target.content, numSlot, adData, isVideo);
		}
		
		/**
		 * When minibillboard jpeg or swf loaded 
		 * @param event
		 * @param numSlot
		 */
		private function minibillboardImageLoaded(asset:DisplayObject, numSlot:int, adData:AdData, isVideo:Boolean):void
		{
			_minibillboardLoadCounter--;
			if (asset == null)
			{
				// if the swf fails to load from the server, make sure it has been pushed live
				trace("mini billboard image is null for slot " + numSlot);
			}
			else
			{
				_hasBillboard = true;
				_slots[numSlot] = true;
				_slotData[numSlot] = adData;
				trace("mini billboard image loaded in slot " + numSlot);
				
				// add to movie clip
				var clip:MovieClip = new MovieClip();
				clip.addChild(asset);
				// add campaign name and clickURL
				clip.campaign_name = adData.campaign_name;
				clip.clickURL = adData.clickURL;
				clip.x = _miniBillboardClip["billboardBack"].x - (_miniBillboardClip["billboardBack"].width/2);
				clip.y = _miniBillboardClip["billboardBack"].y - (_miniBillboardClip["billboardBack"].height/2);
				if(clip.height < 250) //old size
				{
					clip.y += PADDING_VERTICAL;
					clip.x -= PADDING_HORIZONTAL;
				}

				// add to minibillboard
				var slot:MovieClip;
				if(_externalBillboard)
				{
					var miniclip:MovieClip = _miniBillboardClip["minibillboard"];
					
					slot = MovieClip(_miniBillboardClip["content"].addChild(clip));
					_miniBillboardClip["slot" + numSlot] = slot;
				}
				else
				{
					var miniBill:MovieClip = _scene.hitContainer["minibillboard"];
					slot = MovieClip(miniBill["content"].addChild(clip));
					_scene.hitContainer["minibillboard"]["slot" + numSlot] = slot;
				}
				
				// position
				//slot.x = 9;
				//slot.y = 9;
				slot.visible = false;
				// ad impression (needed to change to every refresh)
				//shellApi.adManager.track(adData.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, adData.campaign_type);
				// setup video
				/*ignoring video for now
				if (isVideo)
				{
				// fixes problem with video buttons
				_scene.hitContainer["minibillboard"].mouseChildren = true;
				// setup video
				// if video group exists, then don't create new one
				_videoGroup = AdVideoGroup(this.groupManager.getGroupById("AdVideoGroup"));
				if (_videoGroup == null)
				_videoGroup = new AdVideoGroup();
				// get video path and duration
				var arr:Array = adData.campaign_file2.split(",");
				slot.duration = Number(arr[1]);
				var videoData:Object = {};
				videoData.width = minibillboard_WIDTH;
				videoData.height = minibillboard_HEIGHT;
				videoData.videoFile = arr[0];
				videoData.locked = (slot.duration <= 15 ? true : false);
				videoData.clickURL = adData.clickURL;
				//videoData.impressionURL = adData.impressionURL; // don't pass to video click impression (use campaign.xml instead for that)
				videoData.campaign_name = adData.campaign_name;
				_videoGroup.setupTownminibillboardVideo(this, slot.getChildAt(0)["minibillboardVideoContainer"], this._hitContainer, videoData);
				slot.isVideo = true;
				}
				*/
			}
			
			// when all loaded
			if (_minibillboardLoadCounter == 0)
				minibillboardDoneLoading();
		}
		
		
		public function moveToFront():void
		{
			_scene.hitContainer.setChildIndex(_scene.hitContainer["minibillboard"],0);
			//_miniBillboardClip.setChildIndex(
		}
		/**
		 * When minibillboard had loaded all slots 
		 */
		private function minibillboardDoneLoading():void
		{
			var minibillboardContainer:DisplayObjectContainer 
			if(_externalBillboard)
				minibillboardContainer = _miniBillboardClip;
			else
				minibillboardContainer = _scene.hitContainer["minibillboard"];
			
			// if have billboard slots
			if (_hasBillboard)
			{
				// make into entity
				_miniBillboardEntity = EntityUtils.createSpatialEntity(_scene, minibillboardContainer, _scene.hitContainer);
				
				if(_moveToBack)
					DisplayUtils.moveToBack(minibillboardContainer);
				
				// add tooltip
				var offset:Point = new Point(250, 131);
				ToolTipCreator.addToEntity(_miniBillboardEntity, ToolTipType.CLICK, null, offset);
				
				// create interaction for clicking on post
				var interaction:Interaction;
				if(_externalBillboard)
					interaction = InteractionCreator.addToEntity(_miniBillboardEntity, [InteractionCreator.CLICK,InteractionCreator.TOUCH], minibillboardContainer["content"]);
				else
					interaction = InteractionCreator.addToEntity(_miniBillboardEntity, [InteractionCreator.CLICK,InteractionCreator.TOUCH], minibillboardContainer);
				interaction.click.add(minibillboardClick);
				
				
				// disable default slot
				_slots[0] = false;
				
				// get next available slot
				getNextSlot(true);
				
				// check number of valid slots
				var count:int = 0;
				for (var i:int = _slots.length-1; i!= 0; i--)
				{
					if (_slots[i])
						count++;
				}
				trace("minibillboard count: " + count);
				// if more than one slot
				if (count > 1)
				{
					_minibillboardHasTimer = true;
					// setup rotation timer
					SceneUtil.addTimedEvent(_scene, new TimedEvent(AdManager(_shellApi.adManager).minibillboardDelay, 1, getNextSlot), "minibillboardTimer");
					// setup dots for clicking
					setupDots(count);
				}
			}
			else
			{
				// if no slots loaded
				// show default billboard
				//_scene.hitContainer["defaultBillboard"].visible = true;
			}
		}
		/**
		 * Get next minibillboard slot and make visible
		 * Also called when more than one slot and slots rotate
		 */
		private function getNextSlot(firstTime:Boolean = false):void
		{
			// if timer then setup delay till next billboard
			if (_minibillboardHasTimer)
			{
				_scene.removeEntity(_scene.getEntityById("minibillboardTimer"));
				SceneUtil.addTimedEvent(_scene, new TimedEvent(AdManager(_shellApi.adManager).minibillboardDelay, 1, getNextSlot), "minibillboardTimer");
			}
			
			// hide current slot and deselect dot if non-zero
			if (_currentSlot != 0)
			{
				if(_externalBillboard)
					_miniBillboardClip["slot" + _currentSlot].visible = false;
				else
					_scene.hitContainer["minibillboard"]["slot" + _currentSlot].visible = false;
				_scene.getEntityById("dot" + _currentSlot).get(Button).isSelected = false;
			}
			
			while(true)
			{
				// increment slot
				_currentSlot++;
				// wrap to 1 if equals number of slots
				if (_currentSlot == _slots.length)
					_currentSlot = 1;
				// return if slot is filled
				if (_slots[_currentSlot])
					break;
			}
			// show slot
			// impression on every refresh
			var ad:AdData = _slotData[_currentSlot];
			if (ad != null)
			{
				_shellApi.adManager.track(ad.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, ad.campaign_type);
			}
			if(_externalBillboard)
				_miniBillboardClip["slot" + _currentSlot].visible = true;
			else
				_scene.hitContainer["minibillboard"]["slot" + _currentSlot].visible = true;
			// select dot if not first time
			if (!firstTime)
				_scene.getEntityById("dot" + _currentSlot).get(Button).isSelected = true;
		}
		/**
		 * When click on minibillboard
		 * @param entity
		 */
		private function minibillboardClick(entity:Entity):void
		{
			var clip:MovieClip; 
			if(_externalBillboard)
				clip = _miniBillboardClip["slot" + _currentSlot];
			else
				clip = _scene.hitContainer["minibillboard"]["slot" + _currentSlot];
			
			if (clip.isVideo == true)
			{
				// if timer active, then delete old timer and create new one based on duration plus delay
				if (_minibillboardHasTimer)
				{
					_scene.removeEntity(_scene.getEntityById("minibillboardTimer"));
					SceneUtil.addTimedEvent(_scene, new TimedEvent(AdManager(_shellApi.adManager).minibillboardDelay + clip.duration, 1, getNextSlot), "minibillboardTimer");
				}
				return;
			}
			
			if ((clip.clickURL) && (clip.clickURL != ""))
			{
				// if pop url, don't show bumper
				if (clip.clickURL.substr(0,3) == "pop")
				{
					triggerSponsorSite();
				}
				else
				{
					// else go through normal processing
					AdManager.visitSponsorSite(_shellApi, clip.campaign_name, triggerSponsorSite);
				}
			}
		}
		
		/**
		 * Setup dots on billboard frame for navigation 
		 * @param count
		 */	
		private function setupDots(count:int):void
		{
			trace("set up dots");
			var path:String = _shellApi.assetPrefix + "minibillboard/buttonSlide.swf";
			var pos:int = 0;
			for (var slot:int = 0; slot!= _slots.length; slot++)
			{
				// if slot filled
				if (_slots[slot])
				{
					// laod dot and increment position
					_shellApi.loadFile(path, dotLoaded, pos, slot, count);
					pos++;
				}
			}
		}
		
		/**
		 * When dot loaded
		 * @param clip
		 * @param pos dot index starting at 0
		 * @param slot occupied billboard slot starting at 1
		 * @param count total dots/billboards
		 */
		private function dotLoaded(clip:MovieClip, pos:int, slot:int, count:int):void
		{
			var spacing:int = 47; // was 50
			
			// add dot to scene
			var dot:MovieClip = MovieClip(_scene.hitContainer.addChild(clip));
			
			// position and scale dot
			var minibillboard:MovieClip;
			if(_externalBillboard)
				minibillboard = (MovieClip)(_miniBillboardClip);
			else
				minibillboard = _scene.hitContainer["minibillboard"];
			
			dot.y = minibillboard.y + minibillboard_HEIGHT + 24;
			dot.x = minibillboard.x + ((minibillboard_WIDTH + PADDING_HORIZONTAL) - (count - 1) * spacing) / 2 + pos * spacing;
			dot.scaleX = dot.scaleY = 0.5;
			
			DisplayUtils.moveToOverUnder(dot, minibillboard);
			
			// make into button
			var entity:Entity = ButtonCreator.createButtonEntity(clip, _scene, dotClicked, null, null, null, true, true);
			entity.add(new Id("dot" + slot));
			var button:Button = entity.get(Button);
			// point to billboard slot (won't match pos)
			button.value = slot;
			
			// select first dot
			if (pos == 0)
				button.isSelected = true;
		}
		
		/**
		 * When dot clicked 
		 * @param entity
		 */
		private function dotClicked(entity:Entity):void
		{
			// get button
			var button:Button = entity.get(Button);
			
			// hide current slot and deselect dot if non-zero
			if (_currentSlot != 0)
			{
				if(_externalBillboard)
					_miniBillboardClip["slot" + _currentSlot].visible = false;
				else
					_scene.hitContainer["minibillboard"]["slot" + _currentSlot].visible = false;
				_scene.getEntityById("dot" + _currentSlot).get(Button).isSelected = false;
			}
			
			if(_currentSlot != button.value)
			{
				//track
				var clip:MovieClip;
				if(_externalBillboard)
					clip = _miniBillboardClip["slot" + _currentSlot];
				else
					clip = _scene.hitContainer["minibillboard"]["slot" + _currentSlot];
				var ad:AdData = _slotData[_currentSlot];
				AdManager(_shellApi.adManager.track(clip.campaign_name, "DotClicked", ad.campaign_type, "slot " + _currentSlot));
				
			}
			// set current slot
			_currentSlot = button.value;
			// show billboard
			if(_externalBillboard)
				_miniBillboardClip["slot" + _currentSlot].visible = true;
			else
				_scene.hitContainer["minibillboard"]["slot" + _currentSlot].visible = true;
			// select dot
			button.isSelected = true;
			// restart timer
			SceneUtil.getTimer(_scene, "minibillboardTimer").timedEvents[0].start();
			
			
		}
		
		/**
		 * Open sponsor site (called after delay on mobile) 
		 */
		private function triggerSponsorSite():void
		{
			// tracking
			var clip:MovieClip;
			if(_externalBillboard)
				clip = _miniBillboardClip["slot" + _currentSlot];
			else
				clip = _scene.hitContainer["minibillboard"]["slot" + _currentSlot];
			
			var ad:AdData = _slotData[_currentSlot];
			AdManager(_shellApi.adManager.track(clip.campaign_name, AdTrackingConstants.TRACKING_CLICK_MINI_BILLBOARD, ad.campaign_type, "slot " + _currentSlot));
			// open sponsor URL
			AdUtils.openSponsorURL(_shellApi, clip.clickURL, clip.campaign_name, ad.campaign_type, "")
		}
	}
}