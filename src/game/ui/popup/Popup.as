package game.ui.popup
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Tween;
	import engine.group.DisplayGroup;
	import engine.group.UIView;
	import engine.managers.SoundManager;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ParamData;
	import game.data.ParamList;
	import game.data.ads.CampaignData;
	import game.data.ui.TransitionData;
	import game.managers.ScreenManager;
	import game.util.AudioUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	
	import org.osflash.signals.Signal;
	
	public class Popup extends UIView
	{
		public function Popup(container:DisplayObjectContainer = null)
		{
			super(container);
			
			closeClicked = new Signal(Popup);
			popupRemoved = new Signal();
		}
		
		override public function destroy():void
		{
			closeClicked.removeAll();
			popupRemoved.removeAll();
			_darkBG = null;
			if(this.shellApi.currentScene && this.hideSceneWhenOpen)
			{
				this.shellApi.currentScene.groupContainer.visible = true;
			}
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			// NOTE :: specify prefix & screen asset here if overriding, if screenAsset is set it will be setup automatically 
			// super.screenAsset = "screenAsset.swf";
			// super.groupPrefix = "scenes/island/scene";
			super.init(container); // creates a new groupContainer, and adds it to container
			
			this.shellApi.loadFile(this.shellApi.assetPrefix + "ui/general/load_wheel.swf", this.addLoadWheel);
		}
		
		private function addLoadWheel(clip:MovieClip):void
		{
			if(this.isReady || this.removalPending) return;
			
			clip.x = this.shellApi.viewportWidth / 2;
			clip.y = this.shellApi.viewportHeight / 2;
			var entity:Entity = EntityUtils.createMovingEntity(this, clip, this.groupContainer);
			Motion(entity.get(Motion)).rotationVelocity = 350;
			entity.add(new Id("popupLoadWheel"));
			
			this.ready.addOnce(this.removeLoadWheel);
		}
		
		private function removeLoadWheel(...args):void
		{
			this.removeEntity(this.getEntityById("popupLoadWheel"));
		}
		
		// used for campaign card powers that play popup animations
		public function setParams(params:ParamList):void
		{
			data = {};
			for each (var obj:ParamData in params.params)
			{
				if (obj.id == "alignDirection")
					data.alignDirection = DataUtils.getBoolean(obj.value);
				else
					data[obj.id] = String(obj.value);
			}
		}
		
		/**
		 * Configure the popup from a single function
		 * @param	transIn
		 * @param	transOut
		 * @param	darkenBackground
		 * @param	autoOpen
		 * @param	autoRemove
		 * @param	pauseParent
		 */
		public function config( transIn:TransitionData = null, transOut:TransitionData = null, darkenBackground:Boolean = true, autoOpen:Boolean = true, autoRemove:Boolean = true, pauseParent:Boolean = true ):void
		{
			if ( transIn )
			{
				this.transitionIn = transIn;
			}
			if ( transOut )
			{
				this.transitionOut = transOut;
			}
			this.darkenBackground = darkenBackground;
			this.autoOpen = autoOpen;
			this.autoRemove = autoRemove;
			this.pauseParent = pauseParent;
		}
		
		/**
		 * adds screen to groupContainer, creates a closebutton if found, dispatch ready
		 */
		override public function loaded(): void 
		{
			if( !_isRemoved )	// NOTE :: make sure popup hasn't been removed before loaded has been called
			{
				preparePopup();	// manages popup specific start up
				super.loaded();
			}
		}
		
		/**
		 * Manages popup specifc loading
		 */
		protected function preparePopup(): void 
		{
			if( DataUtils.validString( super.screenAsset ) && screen == null )
			{
				super.screen = super.getAsset(super.screenAsset, true) as MovieClip;
			} 
			
			if ( this.autoOpen )
			{
				open();
			}
			else
			{
				hide();
			}
			
			if(darkenBackground)
			{
				var screenEffects:ScreenEffects = new ScreenEffects();
				_darkBG = screenEffects.createBox(shellApi.viewportWidth, shellApi.viewportHeight, 0x000000);
				_darkBG.alpha = darkenAlpha;
				super.groupContainer.addChildAt(_darkBG, 0);
			}
			
			if(pauseParent)
			{
				super.parent.pause(false);
				
				// pause video if any. NOTE :: this shoudl be handled by pausing in general. - Bard
//				 reworded for simplicity. TODO: this should be handled by pausing in general _RAM
//				var adVideoGroup:AdVideoGroup = AdVideoGroup(super.shellApi.sceneManager.currentScene.groupManager.getGroupById("AdVideoGroup"));
//				if (adVideoGroup != null)
//					adVideoGroup.pause();
				var adVideoGroup:DisplayGroup = shellApi.groupManager.getGroupById('AdVideoGroup') as DisplayGroup;
				if (adVideoGroup) {
					if (adVideoGroup.hasOwnProperty('pause')) {
						adVideoGroup['pause']();
					}
				}
			}
			
			if( super.screen )
			{
				super.groupContainer.addChild(super.screen);
				
				if (super.screen.closeButton) 
				{
					createCloseButton();
				}
			}
			
			if(this.shellApi.currentScene && this.hideSceneWhenOpen)
			{
				this.shellApi.currentScene.groupContainer.visible = false;
			}
		}
		
		/**
		 * Creates a default close button, override this function to create custom close buttons.
		 */
		protected function createCloseButton( displayObject:DisplayObjectContainer = null, bitmap:Boolean = false, oversampleScale:Number = 1): void 
		{
			if( !displayObject )
			{
				displayObject = super.screen.closeButton;
			}
			//this.closeButton = ButtonCreator.createStandardButton(displayObject, handleCloseClicked, null, this);
			this.closeButton = ButtonCreator.createButtonEntity(displayObject, this, handleCloseClicked, null, null, null, true, bitmap, oversampleScale);
		}
		
		/**
		 * Loads and sets the default close button from the shared asset.
		 * @param displayPosition - String defining position, refer to DisplayPositions for valid types
		 * @param xPadding
		 * @param yPadding
		 * @param viewportRelative
		 * @param btnContainer
		 * @param onLoadHandler
		 * @return 
		 */
		protected function loadCloseButton( displayPosition:String = "", xPadding:int = 50, yPadding:int = 50, viewportRelative:Boolean = true, btnContainer:DisplayObjectContainer = null, onLoadHandler:Function = null ): Entity 
		{
			if( !btnContainer )	{ btnContainer = super.screen; }
			this.closeButton = ButtonCreator.loadCloseButton( this, btnContainer, handleCloseClicked, displayPosition, xPadding, yPadding, viewportRelative, onLoadHandler );
			return this.closeButton;
		}
		
		protected function handleCloseClicked (...args): void 
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + SoundManager.STANDARD_CLOSE_CANCEL_FILE);
			closeClicked.dispatch(this);
			close( autoRemove );
		}
		
		/**
		 * Open the popup
		 */
		public function open( handler:Function = null):void
		{
			_isOpen = true;
			hide(false);
			if(transitionIn)
			{
				animate(transitionIn, handler);
			}
			else if(handler != null)
			{
				handler();
			}
			
			super.updateDefaultCursor(false);
		}
		
		/**
		 * Sets the popups visibility
		 * @param	bool
		 */
		public function hide( bool:Boolean = true ):void
		{
			if (super.groupContainer) super.groupContainer.visible = !bool;
		}
		
		/**
		 * Closes the popup, will remove popup on close complete if not otherwise specified
		 * @param	removeOnClose
		 */
		public function close( removeOnClose:Boolean = true, onClosedHandler:Function = null ):void
		{
			super.updateDefaultCursor(true);
			
			_isOpen = false;
			if ( removeOnClose )
			{
				if(this.transitionOut)
				{
					animate(this.transitionOut, remove);
				}
				else
				{
					remove();
				}
			}
			else
			{
				if(this.transitionOut)
				{
					animate(this.transitionOut, onClosedHandler);
				}
				else
				{
					hide(true);
					if ( onClosedHandler != null )
					{
						onClosedHandler();
					}
				}
			}
		}
		
		/**
		 * Remove the popup
		 */
		override public function remove():void
		{
			if(this.pauseParent)
			{
				super.parent.unpause();
				
				// force unpause any video
				// TODO :: this should not be here, ad video popup should override this via inheritance or handle it in another fashion. - bard
				/*
				var adVideoGroup:AdVideoGroup = AdVideoGroup(super.shellApi.sceneManager.currentScene.groupManager.getGroupById("AdVideoGroup"));
				if (adVideoGroup != null)
					adVideoGroup.unpause();
				*/
			}
				
			
			super.updateDefaultCursor(true);
			
			this._isRemoved = true;
			popupRemoved.dispatch();
			super.remove();
		}
		
		/**
		 * Animates popup in or out (based on 
		 * @param	trans
		 * @param	onComplete
		 * @param	... onCompleteParams
		 */
		private function animate(trans:TransitionData, onComplete:Function = null, ...onCompleteParams): void 
		{
			var screen:DisplayObjectContainer = super.screen;
			
			screen.x = trans.startPos.x;
			screen.y = trans.startPos.y;
			screen.scaleX = screen.scaleY = trans.startScale;
			screen.alpha = trans.startAlpha; 
			var tweenObject:Object = trans.customTweenObject;
			
			if(tweenObject == null)
			{
				tweenObject = { delay : .2, ease : trans.ease };
				if(onComplete != null) { tweenObject.onComplete = onComplete; }
				if(onCompleteParams) { tweenObject.onCompleteParams = onCompleteParams; }
				if (trans.startPos.x != trans.endPos.x) { tweenObject.x = trans.endPos.x; }
				if (trans.startPos.y != trans.endPos.y) { tweenObject.y = trans.endPos.y; }
				if (trans.startScale != trans.endScale) { tweenObject.scaleX = tweenObject.scaleY = trans.endScale; }
				tweenObject.alpha = trans.endAlpha;
			}
			
			//Only transition in if device quality allows it. Setting to 0 causes odd behavior...
			var duration:Number = PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM ? trans.duration : 0.001;
			
			var tween:Tween = this.getGroupEntityComponent(Tween);
			tween.to(screen, duration, tweenObject);
		}
		
		// used for campaign popup animations when the animation ends
		public function endPopupAnim():void
		{
			SceneUtil.lockInput(super, false);
			remove();
		}
		
		/**
		 * get scaled-up dimensions of centered 960x480 popup on mobile device
		 */
		public function centerPopupToDevice():void
		{
			// target proportions for device
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
			super.screen.x = super.shellApi.viewportWidth / 2;
			super.screen.y = super.shellApi.viewportHeight / 2;
			super.screen.scaleX = super.screen.scaleY = scale;
		}
		
		/**
		 * Dispatched when closing has begun, returns popup 
		 */
		public var closeClicked:Signal;
		public var popupRemoved:Signal;
		public var data:Object;
		
		protected var _darkBG:Sprite;
		protected var closeButton:Entity;
		protected var _isOpen:Boolean = false;
		/** Flag set to true once popup starts close/removal, used in cases where loaded may be called after remove process has begun */
		protected var _isRemoved:Boolean = false;
		public function get isOpened():Boolean { return _isOpen; }
		
		public var darkenAlpha:Number = .4;
		public var darkenBackground:Boolean = false;     // applys a dark transparent bacground if true.
		public var autoOpen:Boolean = true;              // should this popup open automatically after its loaded?
		public var autoRemove:Boolean = true;            // should this group remove itself after it is closed?
		public var pauseParent:Boolean = true;           // should this popup pause the parent (usually a scene) when it loads?
		
		public var transitionIn:TransitionData;          // optional data to store this popup's transition in and out.  If left out it will be added and removed right away.
		public var transitionOut:TransitionData;
		
		public var campaignData:CampaignData;
		
		/**
		 * Hides the current Scene when this Popup is opened. This can be used to improvement performance if
		 * this Popup and the current Scene running simultaneously is too heavy graphically. This also prevents
		 * clicks from happening in the Scene.
		 * 
		 * <p>It's important to note that this method only really works if there is 1 Popup at a time hiding the
		 * current Scene. Multiple Popups attempting to change the visibility of the Scene may conflict with each other,
		 * causing the Scene to be visible again if PopupA opens and hides, but PopupB closes and shows after.</p>
		 */
		public var hideSceneWhenOpen:Boolean = false;
	}
}