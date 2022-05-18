package game.scenes.custom
{
	import com.poptropica.AppConfig;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.printing.PrintJob;
	import flash.printing.PrintJobOptions;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Scene;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.managers.ScreenManager;
	import game.managers.ads.AdManager;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.popup.Popup;
	import game.util.ColorUtil;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.utils.AdUtils;
	import flash.geom.Matrix;
	
	/**
	 * Display printable wishlist with blackout area
	 * Has toggable buttons that are saved to LSO
	 * Wishlist needs to be positioned at 0,0 at upper left corner
	 * Mobile wishlist needs movieClip named "content" with toggable selector button inside content clip
	 */
	public class WishlistPopup extends Popup
	{
		public function WishlistPopup()
		{
			_useLSO = _trackToggleButtons = false;
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = true;
			// assets will be found in campaign folder in custom/limited folder
			super.groupPrefix = AdvertisingConstants.AD_PATH_KEYWORD + "/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array(super.data.swfPath));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			_wishlist = super.screen = super.getAsset(super.data.swfPath, true) as MovieClip;
			
			if (_wishlist == null)
			{
				trace("WishlistPopup: Can't find popup: " + super.data.swfPath);
			}
			else
			{
				// TotalTime tracking currently disabled
				//_timer = getTimer();
				
				var targetProportions:Number = super.shellApi.viewportWidth/super.shellApi.viewportHeight;
				var destProportions:Number = ScreenManager.GAME_WIDTH/ScreenManager.GAME_HEIGHT;
				// if wider, then fit to width and center vertically
				if (destProportions >= targetProportions)
				{
					var scale:Number = super.shellApi.viewportWidth/ScreenManager.GAME_WIDTH;
				}
				else
				{
					// else fit to height and center horizontally
					scale = super.shellApi.viewportHeight/ScreenManager.GAME_HEIGHT;
				}
				_wishlist.x = super.shellApi.viewportWidth / 2 - ScreenManager.GAME_WIDTH * scale / 2;
				_wishlist.y = super.shellApi.viewportHeight / 2 - ScreenManager.GAME_HEIGHT * scale/ 2;
				_wishlist.scaleX = _wishlist.scaleY = scale;

				// add blackout area around wishlist
				var shape:Shape = new Shape();
				shape.graphics.beginFill(0);
				shape.graphics.drawRect(-ScreenManager.GAME_WIDTH, -ScreenManager.GAME_HEIGHT, 3 * ScreenManager.GAME_WIDTH, 3 * ScreenManager.GAME_HEIGHT);
				shape.graphics.drawRect(0, 0, ScreenManager.GAME_WIDTH, ScreenManager.GAME_HEIGHT);
				shape.graphics.endFill();
				_wishlist.addChild(shape);

				//if (ExternalInterface.available)
					//ExternalInterface.call("hideWrapper");
				
				if (_wishlist["closeButton"] != null)
					_wishlist.closeButton = null;
				
				// set up close button
				if (_wishlist["btnClose"] != null)
					setupButton(_wishlist.btnClose, closePopup, null);
				else
					trace("WishlistPopup: missing close button!");
				
				// set up sponsor button
				if (_wishlist["btnSponsor"] != null)
					setupButton(_wishlist.btnSponsor, visitSponsorSite, null);
				else
					trace("WishlistPopup: missing sponsor button!");
				
				// check to see if one should read the LSO (and set up a reference to it, if so
				// default is true
				if ((super.data.saveToggleButtons == null) || ( super.data.saveToggleButtons == true ))
					_useLSO = true;
				if ( _useLSO )
				{
					_wishlistLSO = SharedObject.getLocal(super.campaignData.campaignId, "/");
					_wishlistLSO.objectEncoding = ObjectEncoding.AMF0;
				}
				
				// check to see if toggle buttons, when present, should be reported (default is true)
				// this is only tracked when the wishlist is printed
				if ((super.data.trackToggleButtons == null) || ( super.data.trackToggleButtons == true ))
					_trackToggleButtons = true;
				
				// setup assets
				if (_wishlist["btnPrint"] != null)
					setupButton(_wishlist.btnPrint, doPrint, null);
				else
					trace("WishlistPopup: missing print button!");
				
				var requestFlush:Boolean = false;
				var buttonNumber:int = 1;
				
				// for every selector button...
				while (true)
				{
					var id:String = "btnSelector" + buttonNumber;
					var clip:MovieClip = _wishlist[id];
					
					if (clip)
					{
						var checked:Boolean = false;
						// if using the LSO...
						if ( _useLSO )
						{
							// check to see if the LSO has this info stored... if not, set its initial value to false
							// and trigger a flag signifying an LSO save is needed
							if ( _wishlistLSO.data[id] == undefined )
							{
								_wishlistLSO.data[id] = false;
								requestFlush = true;
							}
							
							// set the status of the button based on the LSO
							if ( _wishlistLSO.data[id] )
								checked = true;
						}
						
						// set up the button, sending an String ID to remember which one it is
						setupButton(_wishlist[id], toggleButton, id, checked);
						
						// iterate
						buttonNumber++;
					}
					else
					{
						break;
					}
				}
				
				// if any values were initialized, save the LSO
				if ( requestFlush )
					_wishlistLSO.flush();
			}
			
			// unlock input (that was locked in AdPoster class)
			SceneUtil.lockInput(super.parent, false);
			
			trace("WishlistPopup: done loading");
			
			super.loaded();
		}
		
		// there is probably a better way to do this that doesn't involve direct references
		// to the MovieClip (perhaps through the Display component, but it wasn't working that way)
		private function toggleButton(button:Entity):void
		{
			var timeline:Timeline = button.get(Timeline);
			if (timeline.currentIndex == 0)
				timeline.gotoAndStop(1);
			else
				timeline.gotoAndStop(0);
				
			if ( _useLSO )
				saveTogglesToLSO();
		}
		
		private function doPrint(button:Entity = null):void
		{
			trace("WishlistPopup: click print");
			
			// skip out if missing printable list
			if (_wishlist["printableList"] == null)
			{
				trace("WishlistPopup: no printable wishlist found!");
				return;
			}
			var content:MovieClip = _wishlist["printableList"]["content"];
			if (content == null)
			{
				trace("WishlistPopup: no printable wishlist content found!");
				return;
			}
			
			if ( _useLSO )
				saveTogglesToLSO();
			
			// set toggles in printable version
			// for each button, map to printable wishlist
			var buttonNumber:int = 1;
			while (true)
			{
				var id:String = "btnSelector" + buttonNumber;
				var buttonEntity:Entity = super.getEntityById(id);
				if (buttonEntity != null)
				{
					var timeline:Timeline = buttonEntity.get(Timeline);
					if (timeline != null)
					{
						// map printable list to current timeline index plus 1 since index start at zero
						content[id].gotoAndStop(timeline.currentIndex + 1);
						
						// if tracking buttons and index is 1 (checked box), then track
						if ( (_trackToggleButtons) && (timeline.currentIndex == 1) )
							super.shellApi.adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_WISHLISH_OPTION_SELECTED, _choice, "Option " + buttonNumber);
					}
					buttonNumber++;
				}
				else
				{
					break;
				}
			}
			
			// if mobile then add to photo stream
			if (AppConfig.mobile)
			{
				// save to camera roll
				trace("WishlistPopup: Save to camera roll");
				
				// unpause so input wheel spins and timer will advance
				super.parent.unpause();
				
				// lock input
				SceneUtil.lockInput(super.shellApi.sceneManager.currentScene, true);
				// dim screen
				ColorUtil.tint(super.shellApi.screenManager.container, 0x000000, 50);
				
				// set clipping rect to standard size (this fixes wrong movieClip dimensions when masks are used)
				var clipRect:Rectangle = new Rectangle(-content.width/2, -content.height/2, content.width, content.height);

				// save to camera roll (nothing happens in FlashBuilder)
				super.shellApi.saveMovieClipToCameraRoll(content, clipRect, super.campaignData.campaignId, onSaveSuccess, onSaveFailure);
			}
			else
			{
				// else send to printer
				trace("WishlistPopup: begin printjob");
				
				var printJob:PrintJob = new PrintJob();
				var started:Boolean = false;
				try
				{
					printJob.start();
					trace("WishlistPopup: printjob started");
					started = true;
				}
				catch (e:Error)
				{
					trace("WishlistPopup: can't start printjob");
					return;
				}
				
				if ( started )
				{
					var vWidth:Number, vHeight:Number;
					var vRotate:Boolean;
					
					var maxPrint:Number = Math.max(printJob.pageWidth, printJob.pageHeight);
					
					// if poster is horizontal
					if (container.width > container.height)
					{
						// if landscape then don't rotate
						if (printJob.orientation == "landscape")
							vRotate = false;
						else
							vRotate = true;
					}
					else
					{
						// if poster is vertical
						// if landscape then rotate
						if (printJob.orientation == "landscape")
							vRotate = true;
						else
							vRotate = false;
					}
					
					// draw white box behind
					var printableSprite:Sprite = Sprite(_wishlist.printableList);
					printableSprite.graphics.beginFill(0xFFFFFF);
					printableSprite.graphics.drawRect(-maxPrint, -maxPrint, 2 * maxPrint, 2 * maxPrint);
					printableSprite.graphics.endFill();
					
					if (vRotate)
					{
						vWidth = content.height;
						vHeight = content.width;
						content.rotation = -90;
					}
					else
					{
						vWidth = content.width;
						vHeight = content.height;
					}
					
					// get scale that will fit page
					var scaleDownW:Number = printJob.pageWidth / vWidth;
					var scaleDownH:Number = printJob.pageHeight / vHeight;
					var scaleDown:Number = Math.min(scaleDownW, scaleDownH);
					
					// scale content to fit
					content.scaleX = content.scaleY = scaleDown;
					
					// set printing bounds
					var xMin:Number = -printJob.pageWidth/2;
					var xMax:Number = printJob.pageWidth/2;
					var yMin:Number = -printJob.pageHeight/2;
					var yMax:Number = printJob.pageHeight/2;
					
					trace("PrintPoster: orientation: " + printJob.orientation);
					trace("PrintPoster: scaling: " + scaleDown);
					trace("PrintPoster: rotate: " + vRotate);
					trace("PrintPoster: print dimensions: " + printJob.pageWidth + "," + printJob.pageHeight);
					trace("PrintPoster: image dimensions: " + vWidth * scaleDown + "," + vHeight * scaleDown);
					trace("PrintPoster: printing page: " + xMin + "," + xMax + "," + yMin + "," + yMax);
					
					// print
					var pageAdded:Boolean = false;
					var options:PrintJobOptions = new PrintJobOptions(true);
					var printRect:Rectangle = new Rectangle(xMin, yMin, xMax - xMin, yMax - yMin);
					
					try
					{
						printJob.addPage(printableSprite, printRect, options);
						trace("WishlistPopup: page added");
						pageAdded = true;
					}
					catch(e:Error)
					{
						trace("WishlistPopup: can't add page to printjob");
						return;
					}
					
					if ( pageAdded )
					{
						printJob.send();
						trace("WishlistPopup: printjob sent");
						super.shellApi.adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_PRINTED_WISHLIST, _choice, _subchoice);
					}
				}
			}
		}
		
		/**
		 * When saved to camera roll successfully 
		 */
		private function onSaveSuccess():void
		{
			super.shellApi.adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_PRINTED_WISHLIST, _choice, _subchoice);
			onSave("Your wishlist has been added to your camera roll.");
		}
		
		/**
		 * When failed to save to camera roll
		 */
		private function onSaveFailure():void
		{
			onSave("Your wishlist failed to save to your camera roll.");
		}
		
		/**
		 * When saving to camera roll is complete, then cleanup and show dialog
		 * @param message
		 */
		private function onSave(message:String):void
		{
			var scene:Scene = super.shellApi.sceneManager.currentScene;
			
			// unlock input
			SceneUtil.lockInput(scene, false);

			closePopup();
			
			// undim screen
			ColorUtil.tint(super.shellApi.screenManager.container, 0xFFFFFF, 0);

			// display dialog box
			var dialogBox:ConfirmationDialogBox = new ConfirmationDialogBox(1, message);
			dialogBox.id = "Wishlist";
			
			dialogBox = ConfirmationDialogBox(scene.addChildGroup(dialogBox));
			dialogBox.darkenBackground = true;
			dialogBox.pauseParent = false;
			dialogBox.init(Scene(scene).overlayContainer);			
		}

		private function closePopup(button:Entity = null):void
		{
			trace("WishlistPopup: close popup");
			
			if ( _useLSO )
				saveTogglesToLSO();
			
			//if (ExternalInterface.available)
			//	ExternalInterface.call("unhideWrapper");
			
			super.close();
		}
		
		private function saveTogglesToLSO():void
		{
			var buttonNumber:int = 1;
			
			// for every selector button...
			while (true)
			{
				var id:String = "btnSelector" + buttonNumber;
				var buttonEntity:Entity = super.getEntityById(id);
				if (buttonEntity != null)
				{
					var timeline:Timeline = buttonEntity.get(Timeline);
					if (timeline != null)
					{
						// if the button is on index 0, store false; if the button is on index 1
						// (or another non-first frame), store true	
						if (timeline.currentIndex == 0 )
							_wishlistLSO.data[id] = false;
						else
							_wishlistLSO.data[id] = true;
					}
					// iterate
					buttonNumber++;
				}
				else
				{
					break;
				}
			}
			
			// save to the LSO
			_wishlistLSO.flush();
		}
		
		private function setupButton(button:MovieClip, action:Function, id:String, checked:Boolean = false):void
		{
			//create button entity
			var buttonEntity:Entity;
			if (button.totalFrames == 2)
			{
				buttonEntity = TimelineUtils.convertClip(button, super);
				if (checked)
					buttonEntity.get(Timeline).gotoAndStop(1);
				else
					buttonEntity.get(Timeline).gotoAndStop(0);
			}
			else
			{
				buttonEntity = new Entity();
				
				// add enity to group
				super.addEntity(buttonEntity);
			}
			buttonEntity.add(new Spatial(button.x, button.y));
			buttonEntity.add(new Display(button));
			if ( id )
				buttonEntity.add(new Id(id));					
			
			// add tooltip
			ToolTipCreator.addToEntity(buttonEntity);
			
			// add interaction
			var interaction:Interaction = InteractionCreator.addToEntity(buttonEntity, [InteractionCreator.CLICK], button);
			interaction.click.add(action);
		}
		
		private function visitSponsorSite(button:Entity = null):void
		{
			AdManager.visitSponsorSite(super.shellApi, super.campaignData.campaignId, triggerSponsorSite);
		}
		
		private function triggerSponsorSite():void
		{
			super.shellApi.adManager.track(super.campaignData.campaignId, AdTrackingConstants.TRACKING_CLICK_TO_SPONSOR, _choice, _subchoice);
			AdUtils.openSponsorURL(super.shellApi, AdvertisingConstants.CAMPAIGN_FILE, super.campaignData.campaignId, _choice, _subchoice);
		}
		
		// TotalTime tracking currently disabled
		// private var _timer:uint;
		
		private var _useLSO:Boolean;
		private var _wishlistLSO:SharedObject;
		private var _trackToggleButtons:Boolean;
		private var _wishlist:MovieClip;
		private var _choice:String = "Popup";
		private var _subchoice:String = "Wishlist";
	}
}

