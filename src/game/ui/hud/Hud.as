package game.ui.hud 
{
	import com.greensock.easing.Back;
	import com.greensock.easing.Linear;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.group.UIView;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.components.ui.Button;
	import game.components.ui.HUDIcon;
	import game.creators.ui.ButtonCreator;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.managers.LanguageManager;
	import game.scene.template.SceneUIGroup;
	import game.scenes.hub.town.wheelPopup.WheelPopup;
	import game.systems.SystemPriorities;
	import game.systems.ui.HUDIconSystem;
	import game.ui.costumizer.Costumizer;
	import game.ui.costumizer.CostumizerDelegate;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.inventory.Inventory;
	import game.ui.popup.Popup;
	import game.ui.settings.SettingsPopup;
	import game.util.AudioUtils;
	import game.util.DataUtils;
	import game.util.DisplayAlignment;
	import game.util.DisplayPositions;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	// TODO: The HUD needs a state which persists between scene changes.
	// One way is to stop tearing it down and creating afresh at every scene change.
	// The Shell or ShellApi could hold it while it is parentless, and SceneUIGroup
	// could retrieve it when it inits.
	// Another way would be to create a HUDStateData value class,
	// which could be held by Shell or ShellApi.
	// The HUD would be given the responsibility
	// to read and write a HUDStateData, which would be stashed and
	// retrieved by SceneUIGroup.
	
	/**
	 * The Heads-Up Display is added to every <code>PlatformerGameScene</code>
	 * by <code>SceneUIGroup</code> and resides at the top of the viewport.
	 * When initialized, it hides all its buttons except the
	 * pauseBtn. When the player clicks the pauseBtn, Hud pauses
	 * its parent and unpauses it again when the user dismisses
	 * the Hud either by clicking the playBtn or the bgBtn. The bgBtn
	 * is disabled while the settings panel is overlaying the Hud, however.
	 * 
	 * @author Rich Martin/Bard McKinley
	 */
	public class Hud extends UIView 
	{
		// static constants should be declared at the beginning of a class
		// so they can be used as default parameter values
		public static const GROUP_ID:String = "hud";
		
		public static const HUD:String 			= 'Hud';
		public static const INVENTORY:String 	= 'Inventory';
		public static const COSTUMIZER:String 	= 'Costumizer';
		public static const REALMS:String 		= 'Realms';
		public static const FRIENDS:String 		= 'Friends';
		public static const MAP:String 			= 'Map';
		public static const STORE:String 		= 'Store';
		public static const HOME:String 		= 'Home';
		public static const AUDIO:String 		= 'Audio';
		public static const SETTINGS:String 	= 'Settings';
		public static const SAVE:String 		= 'Save';
		public static const ACTION:String 		= 'Action';
		
		private static const ASSETS_PREFIX:String	= 'ui/hud/';
		private static const SCREEN_ASSET:String	= "hud.swf";
		private static const SPILLING_SOUND:String	= 'ui_knock_over_items.mp3';
		
		protected static const SOUND_MUTED:String	= 'SoundMuted';
		protected static const SOUND_UNMUTED:String	= 'SoundUnmuted';
		
		protected static const OPENED:String = 'Opened';
		protected static const CLOSED:String = 'Closed';
		protected static const BUTTON:String = '_button';
		
		// dialog messages
		//private static const GO_TO_THE_MAP:String	= 'go to the Map?';
		private static const GO_HOME:String			= 'go Home?';
		private static const GO_TO_STORE:String		= 'go to the Store?';
		
		protected static const BUTTON_OFFSET:int = 10;
		protected static const BUTTON_BUFFER:int = 80;
		
		// states
		private var _isTransition:Boolean = false;
		private var _isHudOpen:Boolean = false;
		public function get isOpen():Boolean { return _isHudOpen; }
		
		// rows
		protected var _topRow:Entity;
		protected var _bottomRow:Entity;
		
		// buttons
		protected var _buttons:Vector.<Entity> = new Vector.<Entity>();
		protected var _hudBtnEntity:Entity;
		protected var _inventoryBtn:Entity;
		protected var _costumizerBtn:Entity;
		protected var _mapBtn:Entity;
		protected var _friendsBtn:Entity;
		protected var _homeBtn:Entity;
		protected var _audioButton:Entity;
		protected var _settingsBtn:Entity;
		protected var _storeBtn:Entity;
		protected var _background:Entity;
		protected var _backgroundTint:BitmapWrapper;
		protected var _saveBtn:Entity;
		public var _actionBtn:Entity;
		protected var _actionBtnClip:MovieClip;
		
		protected var _debugConsoleButton:Entity;
		
		protected var _inventoryGlint:Entity;	// sparkle animation within inventory button
		
		protected var _settingsPanel:Popup;
		protected var _hudSystem:HUDIconSystem;
		
		private var _currentPopup:Popup		// keeps track of the popup that is currently open
		
		[Inject]
		public var soundManager:SoundManager;
		
		public var darkenAlpha:Number = .4;
		public var photoNotificationCompleted:Signal;
		public var openingHudElement:Signal;
		public var openingHud:Signal;
		
		public var _showHudButton:Boolean = true;
		
		//// CONSTRUCTOR ////
		
		public function Hud(container:DisplayObjectContainer=null) 
		{
			super(container);
			super.id = GROUP_ID;
			
			photoNotificationCompleted = new Signal();
			openingHudElement = new Signal(String);
			openingHud = new Signal(Boolean);
		}
		
		public override function init(container:DisplayObjectContainer = null):void 
		{
			super.groupPrefix = ASSETS_PREFIX;
			super.screenAsset = SCREEN_ASSET;
			super.init(container);
			super.load();
		}
		
		public override function destroy():void 
		{
			this.shellApi.eventTriggered.remove(onEventTriggered);
			
			if(_backgroundTint )
			{
				_backgroundTint.destroy();
			}
			if( photoNotificationCompleted )
			{
				photoNotificationCompleted.removeAll();
				photoNotificationCompleted = null;
			}
			super.destroy();
		}
		
		public override function loaded():void 
		{
			super.setupScreen();
			
			this.shellApi.eventTriggered.add(this.onEventTriggered);
			
			initHud();
			reset();
			
			super.groupReady();
		}
		
		private function onEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "debug_mode_unlocked")
			{
				this.createDebugConsoleButton();
			}
		}
		
		// TODO :: Might be able to use command strcuture here?  Not sure if it's worth it though.
		protected function initHud():void 
		{
			// CREATE TOP ROW BUTTONS
			var topRowClip:MovieClip = screen.topRow as MovieClip;
			_topRow = EntityUtils.createSpatialEntity( this, topRowClip );
			_topRow.add( new Tween() );
			
			this.setupBottomRow();
			
			// create hud button
			_hudBtnEntity = ButtonCreator.createButtonEntity( topRowClip.hudBtn, this, onHudBtnClick, null, null, null, false );
			_hudBtnEntity.name = HUD + BUTTON;
			_hudBtnEntity.add( new Motion() );
			_hudBtnEntity.add( new Sleep(false, false) );
			//_hudBtnEntity.ignoreGroupPause = true;
			// reset timeline to reference the child button timeline(s), this is little weird, but it works.
			TimelineUtils.convertClip( topRowClip.hudBtn.hudClosedBtn, this, _hudBtnEntity, null, false );
			
			// define the position from where the hud icons will spill from
			var startSpatial:Spatial = _hudBtnEntity.get(Spatial);
			trace("HUD :: viewport width: " + super.shellApi.viewportWidth + " BUTTON_BUFFER: " + BUTTON_BUFFER);
			trace("HUD :: viewport height: " + super.shellApi.viewportHeight);
			startSpatial.x = super.shellApi.viewportWidth - ( BUTTON_BUFFER/2 + BUTTON_OFFSET );
			
			// NOTE :: Order buttons are create is important
			var hudBtnIndex:int = 0;
			var btnClip:MovieClip;
			
			// create settings button
			_settingsBtn = createHudButton( topRowClip.settingsBtn, hudBtnIndex, SETTINGS, startSpatial, onSettingsClick );
			
			// create sound button, i.e., the button should not try to make a sound immediately before muting all sounds, it should try after
			_audioButton = createHudButton( topRowClip.audioBtn, hudBtnIndex++, AUDIO, startSpatial, onAudioClicked );
			updateAudioBtn(_audioButton);	// update audio button state based on current volume level
			
			// create home button
			createHomeButton( (topRowClip.homeBtn as MovieClip), hudBtnIndex, HOME, startSpatial );
			
			// create realms button BROWSER ONLY
			createRealmsButton( (topRowClip.realmsBtn as MovieClip), hudBtnIndex, REALMS, startSpatial );
			
			// create friends button USAGE VARIES ACROSS PLATFORMS
			//createFriendsButton( (topRowClip.friendsBtn as MovieClip), hudBtnIndex, FRIENDS, startSpatial );
			
			// create friends button USAGE VARIES ACROSS PLATFORMS
			// create map/blimp button
			btnClip = topRowClip.storeBtn;
			btnClip.x = startSpatial.x - (BUTTON_BUFFER * 4 - BUTTON_OFFSET);
			createHudButton( btnClip, hudBtnIndex++, STORE, startSpatial, onStoreClick );
			
			// create map/blimp button
			btnClip = topRowClip.mapBtn;
			btnClip.x = startSpatial.x - (BUTTON_BUFFER * 3 - BUTTON_OFFSET);
			createHudButton( btnClip, hudBtnIndex++, MAP, startSpatial, onMapClick );
			
			// create costumizer button
			btnClip = topRowClip.costumizerBtn;
			btnClip.x = startSpatial.x - (BUTTON_BUFFER * 2 - BUTTON_OFFSET);
			createHudButton( btnClip, hudBtnIndex++, COSTUMIZER, startSpatial, onCostumizerClick );
			
			// create inventory button
			btnClip = topRowClip.inventoryBtn;
			btnClip.x = startSpatial.x - (BUTTON_BUFFER - BUTTON_OFFSET);
			_inventoryBtn = createHudButton( btnClip, hudBtnIndex++, INVENTORY, startSpatial, onInventoryClick, false );
			_inventoryGlint = TimelineUtils.convertClip( btnClip.glint_mc, this, null, _inventoryBtn, false);	// create inventory sparkle (within inventory button)
			_inventoryGlint.name = 'inventoryButtonGlint';
			
			// add HUDIconSystem
			_hudSystem = addSystem(new HUDIconSystem(), SystemPriorities.move) as HUDIconSystem;
			
			// CREATE BOTTOM ROW BUTTONS
			
			// BROWSER ONLY - so turn off
			setupSaveButton( screen.bottomRow.saveBtn );
			
			// MOBILE ONLY - so turn off
			setupActionButton( screen.bottomRow.actionButton, false );
			
			// NON-ROW ENTITIES
			
			// BROWSER ONLY - setup camera icon
			// TODO :: this doesn;t really need to be in the Hud, coudl be it's own group - bard
			setupPhotoIcon(screen.cameraIcon);
			
			// create background button to pick up click outside of hud.
			_background = new Entity();
			var bgClip:MovieClip = new MovieClip();
			bgClip.graphics.beginFill(0x000000);
			bgClip.graphics.drawRect(0, 0, shellApi.viewportWidth, shellApi.viewportHeight);
			bgClip.graphics.endFill();
			
			_backgroundTint = super.convertToBitmap( bgClip );
			bgClip.alpha = darkenAlpha;
			super.groupContainer.addChildAt(bgClip, 0);
			_background.add( new Display( bgClip ) );
			bgClip.visible = false;
			var interaction:Interaction = InteractionCreator.addToEntity( _background, [ InteractionCreator.CLICK ], bgClip );
			interaction.click.add( onBGClicked );
			super.addEntity( _background );
			
			this.createDebugConsoleButton();
		}
		
		public function createDebugConsoleButton():void
		{
			var display:DisplayObject = this.screen.bottomRow.getChildByName("debugConsole");
			if(display)
			{
				if(false)
				{
					if(!this._debugConsoleButton)
					{
						DisplayAlignment.alignToSide(display, 0, null, DisplayAlignment.MIN_X);
						DisplayAlignment.alignToSide(display, 0, null, DisplayAlignment.MAX_Y);
						this._debugConsoleButton = ButtonCreator.createButtonEntity(display as MovieClip, this, onDebugConsoleButtonClicked);
						this._debugConsoleButton.add(new Id("debugConsole"));
						this._debugConsoleButton.add(new Sleep(this._isHudOpen, true));
						
						Display(this._debugConsoleButton.get(Display)).visible = false;
						Sleep(this._debugConsoleButton.get(Sleep)).sleeping = true;
					}
				}
				else
				{
					display.visible = false;
				}
			}
		}
		
		private function onDebugConsoleButtonClicked(entity:Entity):void
		{
			this.shellApi.toggleConsole();
		}
		
		/**
		 * Creates a standard hud button, adding necessary components.
		 * @param displayObject
		 * @param index
		 * @param name
		 * @param startX
		 * @param handler
		 * @return 
		 */
		protected function createHudButton( displayObject:DisplayObjectContainer, index:int, name:String, startSpatial:Spatial, handler:Function = null, bitmap:Boolean = true ):Entity 
		{
			// position 
			var icon:HUDIcon = new HUDIcon();
			icon.index = index;
			icon.targetX = displayObject.x;	// TODO :: this will need to be updated to account for different screen sizes/ratios
			icon.startX = startSpatial.x;
			icon.ground = startSpatial.y;
			icon.calculateVars();
			
			var btnEntity:Entity = ButtonCreator.createButtonEntity( displayObject, this, handler, null, null, null, false, bitmap );
			btnEntity.name = name + BUTTON;
			
			EntityUtils.position( btnEntity, startSpatial.x, startSpatial.y );
			
			btnEntity
			.add( new Motion() )
				.add( icon )
				.add( new Sleep(true, true) )
			
			_buttons.push( btnEntity );
			return btnEntity;
		}
		
		/**
		 * Resets hud to default state, skipping any animation transitions 
		 */
		public function reset( disableAll:Boolean = false ):void
		{
			// turn off background btn
			if( _isHudOpen )
			{
				super.shellApi.currentScene.unpause();
				super.updateDefaultCursor(true);	// turn on platformer cursor
				EntityUtils.getDisplayObject(_background).visible = false;	
				
				// reset bottom buttons
				disableBottomBtns( disableAll );
			}
			
			if(this._debugConsoleButton)
			{
				Display(this._debugConsoleButton.get(Display)).visible = false;
				Sleep(this._debugConsoleButton.get(Sleep)).sleeping = true;
			}
			
			// reset hud button
			Spatial(_hudBtnEntity.get(Spatial)).rotation = 0;
			Button(_hudBtnEntity.get(Button)).isDisabled = disableAll;
			setHudButtonDisplay( false );
			_isTransition = false;
			_isHudOpen = false;
			_hudSystem.reset();
			
			// reset hud buttons
			var startSpatial:Spatial = _hudBtnEntity.get(Spatial);
			var btnEntity:Entity;
			for (var i:int=0; i<_buttons.length; i++) 
			{
				btnEntity = _buttons[i];
				EntityUtils.visible( btnEntity, false );
				EntityUtils.position( btnEntity, startSpatial.x, startSpatial.y );
				Sleep(btnEntity.get(Sleep)).sleeping = true;
				Spatial(btnEntity.get(Spatial)).scale = HUDIcon.MIN_SCALE;
				Interaction( btnEntity.get( Interaction ) ).lock = false;
			}
			
			openingHud.dispatch(false); // dispatch closing signal
			
		}
		
		/**
		 * Toggles visibility of Hud.
		 * @param show
		 */
		public function show( isShow:Boolean = true):void
		{
			enableHUDButtons( isShow, true );
			movenOffScreen( !isShow );
		}
		
		/**
		 * Hide/Show the darkened background. 
		 * @param hide
		 */
		public function hideDarken( hide:Boolean = true ):void
		{
			EntityUtils.getDisplayObject(_background).visible = !hide;
		}
		
		/**
		 * Move the hud buttons off/on screen
		 * @param offScreen
		 * @param handler
		 * 
		 */
		public function movenOffScreen( offScreen:Boolean = true, handler:Function = null):void
		{
			var spatial:Spatial
			if( offScreen )
			{
				spatial = _topRow.get(Spatial);
				if( handler != null ){
					TweenUtils.entityTo( _topRow, Spatial, .3, { y:-(spatial.height + 5), ease:Back.easeIn, onComplete:handler } );
				}else{
					TweenUtils.entityTo( _topRow, Spatial, .3, { y:-(spatial.height + 5), ease:Back.easeIn } );
				}
				
				if( _bottomRow ){
					spatial = _bottomRow.get(Spatial);
					TweenUtils.entityTo( _bottomRow, Spatial, .3, { y:super.shellApi.viewportHeight + spatial.height + BUTTON_OFFSET, ease:Back.easeIn } );
				}
			}
			else
			{
				spatial = _topRow.get(Spatial);
				if( handler != null ){
					TweenUtils.entityTo( _topRow, Spatial, .3, { y:0, ease:Back.easeOut, onComplete:handler } );
				}else{
					TweenUtils.entityTo( _topRow, Spatial, .3, { y:0, ease:Back.easeOut} );
				}
				
				if( _bottomRow ){
					spatial = _bottomRow.get(Spatial);
					TweenUtils.entityTo( _bottomRow, Spatial, .3, { y:super.shellApi.viewportHeight, ease:Back.easeOut } );
				}
			}
		}
		
		/**
		 * Disable/Enable Hud buttons.
		 * @param isEnable
		 * @param includeBG
		 * @param excludeButton
		 */
		public function enableHUDButtons( isEnable:Boolean = true, includeBG:Boolean=false, excludeButton:Entity = null ):void 
		{
			// enable lower row buttons
			disableBottomBtns( !isEnable );
			
			// enable bg
			if (includeBG && _background ) 
			{
				EntityUtils.getDisplayObject(_background).mouseEnabled = isEnable;	
			}
			
			// enable hud button
			if( _hudBtnEntity )
			{
				Button( _hudBtnEntity.get(Button) ).isDisabled = !isEnable;
			}
			
			// enable hud buttons
			var buttonEntity:Entity;
			var hudButton:HUDIcon;
			for (var i:int=0; i<_buttons.length; i++) 
			{
				buttonEntity = _buttons[i];
				hudButton = buttonEntity.get( HUDIcon );
				
				// check for excluded button
				if( buttonEntity == excludeButton )
				{
					continue;
				}
				
				if( hudButton && !hudButton.disabled )
				{
					Button( buttonEntity.get(Button) ).isDisabled = !isEnable;
					Interaction( buttonEntity.get( Interaction ) ).lock = !isEnable;
				}
			}
		}
		
		///////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////// HUD TRANSITIONS /////////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////////////////
		
		protected function onBGClicked( entity:Entity = null ):void 
		{
			super.playCancel();
			openHud(false);
		}
		
		/**
		 * Activates Hud's open/close sequences.
		 * @param makeOpen
		 * 
		 */
		public function openHud( makeOpen:Boolean = true ):void 
		{
			var displayObject:MovieClip
			
			if( makeOpen )
			{
				if( !_isHudOpen )	//open
				{
					openingHud.dispatch(true); // dispatch opening signal
					if( !_isTransition )	// can't reopen while closing
					{
						_isHudOpen = true;
						_isTransition = true;
						
						// pause scene, then unpause hud
						super.shellApi.sceneManager.currentScene.pause(true, true);
						this.unpause(true, true);
						
						rotateHudIcon( startHudTransition );		// start open animation
						var buttonEntity:Entity;
						for (var i:int=0; i<_buttons.length; i++) 	// reset all buttons 
						{
							buttonEntity = _buttons[i];
							var hudIcon:HUDIcon = buttonEntity.get(HUDIcon);
							if( hudIcon.hidden )
							{
								//do nothing
							}
							else if ( hudIcon.disabled )
							{
								Display( buttonEntity.get(Display)).visible = true;
								Sleep( buttonEntity.get(Sleep)).sleeping = false;
							}
							else
							{
								Display( buttonEntity.get(Display)).visible = true;
								Button( buttonEntity.get(Button)).isDisabled = false;
								Sleep( buttonEntity.get(Sleep)).sleeping = false;
								if( buttonEntity == _inventoryBtn )
								{
									if( super.shellApi.profileManager.active.newInventoryCard )
									{
										SceneUtil.delay( this, .6, doInventorySparkle ); // if there is a new item, inventory will sparkle
									}
								}
							}
						}
						
						AudioUtils.play(this, SoundManager.EFFECTS_PATH + SPILLING_SOUND);	// play sopund
						shellApi.track(HUD + OPENED, null, null, SceneUIGroup.UI_EVENT);	// track event
						var backgroundClip:DisplayObjectContainer = EntityUtils.getDisplayObject(_background);
						backgroundClip.visible = true;										// turn on background button to pick up clicks
						backgroundClip.mouseEnabled = true;
						disableBottomBtns( true );
						
						super.updateDefaultCursor(false);	
					}
				} 
			}
			else 
			{
				if( _isHudOpen )	//close
				{
					openingHud.dispatch(false); // dispatch closing signal
					_isHudOpen = false;
					super.shellApi.sceneManager.currentScene.unpause(true);	// NOTE :: pauses children, want to not pause hud...
					
					// start close animation
					if( _hudSystem.isActive ) 	
					{ 
						_hudSystem.reverse(); 
						_hudSystem.onComplete.removeAll();	// remove any pending handlers
					}
					startHudTransition( rotateHudIcon );
					
					shellApi.track(HUD + CLOSED, null, null, SceneUIGroup.UI_EVENT);
					// NOTE :: could possibly track what caused close?
					
					// disable bottom row buttons
					disableBottomBtns( false );
					
					super.updateDefaultCursor(true);								// turn on platformer cursor
					EntityUtils.getDisplayObject(_background).visible = false;		// turn off background btn
					
					_isTransition = true;
					
					// close any popups/dialogs that may be open
					for each( var group:Group in super.children )
					{
						if( group is Popup )
						{
							Popup(group).close();
						}
					}
				}
			}
			
			if(this._debugConsoleButton)
			{
				Display(this._debugConsoleButton.get(Display)).visible = this._isHudOpen;
				Sleep(this._debugConsoleButton.get(Sleep)).sleeping = !this._isHudOpen;
			}
		}
		
		/**
		 * Rotates the hud icon to open/close positions, as part of Hud sequence.
		 * @param handler
		 */
		private function rotateHudIcon( handler:Function = null ):void
		{
			if( !_isHudOpen )	// if is closing then switch prior to rotating hud 
			{
				setHudButtonDisplay( false );
				handler = transitionComplete;
			}
			
			var rotValue:Number = ( _isHudOpen ) ? -90 : 0;
			TweenUtils.entityTo( _hudBtnEntity, Spatial, .1, { rotation:rotValue, ease:Linear.easeIn, onComplete:handler } );
		}
		
		
		/**
		 * Triggers Hud buttons' open/close sequence.
		 * @param handler
		 * 
		 */
		private function startHudTransition( handler:Function = null ):void
		{
			if( _isHudOpen )	// if is opening then switch prior to spill
			{
				setHudButtonDisplay( true );
				handler = this.transitionComplete;
			}
			
			_hudSystem.start();
			if( handler != null )
			{
				_hudSystem.onComplete.addOnce( handler );
			}
		}
		
		/**
		 * Called when Hud has completed its open/close sequence.
		 */
		private function transitionComplete():void
		{
			_isTransition = false;
			// possibly dispatch at this point
		}
		
		///////////////////////////////////////////////////////////////////////////////////////////
		/////////////////////////////////////// HUD BUTTONS ///////////////////////////////////////
		///////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Get button Entity by id, ids are accessible from Hud ( e.g. Hud.INVENTORY, Hud.SETTINGS )
		 * @param buttonId
		 * @return 
		 * 
		 */
		public function getButtonById( buttonId:String ):Entity 
		{
			var button:Entity;
			for (var i:int = 0; i < _buttons.length; i++) 
			{
				button = _buttons[i];
				if( button.name == buttonId + BUTTON )
				{
					return button;
				}
			}
			
			if( buttonId == SAVE )
			{
				return _saveBtn;
			}
			else if( buttonId == ACTION )
			{
				return _actionBtn;
			}
			else if( buttonId == HUD )
			{
				return _hudBtnEntity;
			}
			return null
		}
		
		/**
		 * Hide & disable a hud button.
		 * Currently works for top row buttons contained within root Hud button.
		 * Button will remain hidden until hide turned off.
		 * @param buttonId
		 * @param hide
		 */
		public function hideButton( buttonId:String, hide:Boolean = true):void 
		{
			var buttonEntity:Entity = getButtonById( buttonId );
			if( buttonEntity )
			{
				var hudIcon:HUDIcon = buttonEntity.get(HUDIcon);
				var interaction:Interaction = buttonEntity.get(Interaction);
				var button:Button = buttonEntity.get(Button);
				if( hide )
				{
					interaction.lock = true;
					button.isDisabled = true;
					if (hudIcon)
						hudIcon.disabled = hudIcon.hidden = true;
					EntityUtils.visible( buttonEntity, false );
				}
				else
				{
					interaction.lock = false;
					button.isDisabled = false;
					if (hudIcon)
						hudIcon.disabled = hudIcon.hidden = false;
					EntityUtils.visible( buttonEntity, true );
				}
			}
		}
		
		/**
		 * Disable a hud button
		 * Currently works for top row buttons contained within root Hud button.
		 * Button will remain hidden until hide turned off.
		 * @param buttonId
		 * @param hide
		 */
		public function disableButton( buttonId:String, disable:Boolean = true):void 
		{
			var buttonEntity:Entity = getButtonById( buttonId );
			if( buttonEntity )
			{
				var hudIcon:HUDIcon = buttonEntity.get(HUDIcon);
				if( hudIcon )
				{
					var display:Display = buttonEntity.get(Display);
					var interaction:Interaction = buttonEntity.get(Interaction);
					var button:Button = buttonEntity.get(Button);
					if( disable )
					{
						display.alpha = .75;
						interaction.lock = true;
						button.isDisabled = true;
						hudIcon.disabled = true;
					}
					else
					{
						display.alpha = 1;
						interaction.lock = false;
						button.isDisabled = false;
						hudIcon.disabled = false;
					}
				}
			}
		}
		
		/**
		 * Creates a standard Dialog box for the hud 
		 * @param numButtons
		 * @param dialogText
		 * @param confirmHandler
		 * @param cancelHandler
		 * @param createClose
		 * @return  
		 */
		protected function createHudDialogBox( numButtons:int = 2, dialogText:String = "", confirmHandler:Function = null, cancelHandler:Function = null, createClose:Boolean = true):ConfirmationDialogBox 
		{
			var dialogBox:ConfirmationDialogBox = super.addChildGroup( new ConfirmationDialogBox( numButtons, dialogText, confirmHandler, cancelHandler, createClose )) as ConfirmationDialogBox;
			dialogBox.darkenBackground = false;
			dialogBox.pauseParent = false;
			dialogBox.popupRemoved.addOnce( enableHUDButtons );
			dialogBox.init( super.groupContainer );
			enableHUDButtons(false, false);
			return dialogBox;
		}
		
		/**
		 * Transfer hud reset &amp; scene unpause to passed Popup, if hud has a popup open.
		 * @param popup
		 */
		public function popupTransfer( popup:Popup ):void 
		{
			if( _currentPopup != null )	// if popup already open
			{
				_currentPopup.popupRemoved.remove(onFullScreenPopupClosed);
				popup.popupRemoved.addOnce(onFullScreenPopupClosed);
				_currentPopup = null;
			}
		}
		
		/**
		 * Initialize a full screen Popup ( e.g. Inventory, Costumizer).
		 * Manages hud and closing methods.
		 * @param popup
		 * @return 
		 * 
		 */
		protected function initFullScreenPopup( popup:Popup ):Popup 
		{
			//Immediately change the currentPopup before anything dispatches.
			//Was causing race conditions and crashes.
			var previousPopup:Popup = _currentPopup;
			_currentPopup = popup;
			
			super.addChildGroup( popup );
			popup.init( super.groupContainer);
			popup.popupRemoved.addOnce(onFullScreenPopupClosed);
			
			if( previousPopup != null )	// if popup already open
			{
				previousPopup.popupRemoved.remove(onFullScreenPopupClosed);
			}
			else
			{
				enableHUDButtons(false, true);
				popup.ready.addOnce( movenOffScreen );
			}
			
			_currentPopup = popup;
			openingHudElement.dispatch(popup.id);
			return _currentPopup;
		}
		
		private function onFullScreenPopupClosed():void 
		{	
			super.shellApi.currentScene.unpause();
			reset();
			movenOffScreen( false );
			_currentPopup = null;
		}
		
		/**
		 * Creates a whitening effect on a button.
		 */
		public function whiten(alpha:Number = 1):void 
		{
			var display:Display = _isHudOpen ? _inventoryBtn.get(Display) : _hudBtnEntity.get(Display);
			
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmap(display.displayObject, true, 0, null, null, false);
			wrapper.data.colorTransform(wrapper.data.rect, new ColorTransform(1, 1, 1, 1, 255, 255, 255));
			wrapper.bitmap.alpha = 0;
			
			var tween:Tween = this.getGroupEntityComponent(Tween);
			tween.to(wrapper.bitmap, 0.33, {alpha:alpha, onComplete:unwhiten, onCompleteParams:[wrapper]});
		}
		
		private function unwhiten(wrapper:BitmapWrapper):void 
		{
			var tween:Tween = this.getGroupEntityComponent(Tween);
			tween.to(wrapper.bitmap, 0.33, {alpha:0, onComplete:disposeWhitenBitmap, onCompleteParams:[wrapper]});
		}
		
		private function disposeWhitenBitmap(wrapper:BitmapWrapper):void
		{
			wrapper.bitmap.parent.removeChild(wrapper.bitmap);
			wrapper.destroy();
		}
		
		private function trackUIEvent(eventName:String):void 
		{
			if (eventName) {
				shellApi.track(eventName, null, null, SceneUIGroup.UI_EVENT);
			}
		}
		
		/////////////////////////////////////// HUD BUTTON /////////////////////////////////////// 
		
		protected function onHudBtnClick( btn:Entity ):void 
		{
			// check if button needs to change
			openHud( !_isHudOpen );
		}
		
		/**
		 * Swaps hud button between it's open and closed variations.
		 * @param toOpen
		 */
		private function setHudButtonDisplay( toOpen:Boolean, buttonState:String = InteractionCreator.UP ):void
		{
			var displayObject:MovieClip = Display(_hudBtnEntity.get( Display )).displayObject as MovieClip;
			if( toOpen )
			{
				// Switch icon display TODO :: probably need to finish animation first
				TimelineClip(_hudBtnEntity.get( TimelineClip )).mc = displayObject.hudOpenedBtn;
				displayObject.hudOpenedBtn.visible = true;
				displayObject.hudClosedBtn.visible = false;		
			}
			else
			{
				TimelineClip(_hudBtnEntity.get( TimelineClip )).mc = displayObject.hudClosedBtn;
				displayObject.hudOpenedBtn.visible = false;
				displayObject.hudClosedBtn.visible = true;
			}
			if( DataUtils.validString(buttonState) )
			{
				Button(_hudBtnEntity.get(Button)).state = buttonState;
			}
			_hudBtnEntity.get(Display).visible = _showHudButton;
		}
		
		public function showHudButton(state:Boolean):void
		{
			_showHudButton = state;
			if(_hudBtnEntity)
			{
				_hudBtnEntity.get(Display).visible = _showHudButton;
			}
		}
		
		///////////////////////////////////////// INVENTORY BUTTON /////////////////////////////////////////
		
		protected function onInventoryClick( btn:Entity = null ):void 
		{
			playOpenSatchelSound();
			var inventory:Inventory = new Inventory();
			initFullScreenPopup( inventory );
		}
		
		public function openPetInventory():void 
		{
			var inventory:Inventory = new Inventory();
			shellApi.profileManager.inventoryType = Inventory.PETS;
			initFullScreenPopup( inventory );
		}
		
		private function doInventorySparkle():void 
		{
			super.shellApi.profileManager.active.newInventoryCard = false;
			Timeline(_inventoryGlint.get(Timeline)).gotoAndPlay("begin");
		}
		
		/**
		 * Opens inventory directly.
		 */
		public function openInventory( removeCloseButton:Boolean = false ):Inventory 
		{
			// pause scene, then unpause hud
			super.shellApi.sceneManager.currentScene.pause(true, true);
			this.unpause(true, true);
			
			var backgroundClip:DisplayObjectContainer = EntityUtils.getDisplayObject(_background);
			backgroundClip.visible = true;
			_isHudOpen = true;
			
			super.updateDefaultCursor(false);
			
			playOpenSatchelSound();
			var inventory:Inventory = new Inventory();
			inventory.makeCloseButton = !removeCloseButton;
			initFullScreenPopup( inventory );
			
			return inventory;
		}
		
		///////////////////////////////////////// COSTUMIZER BUTTON /////////////////////////////////////////
		
		protected function onCostumizerClick( btn:Entity ):void 
		{
			// costumizer is currently disabled 
			//AudioUtils.play(this, SoundManager.EFFECTS_PATH + Inventory.OPEN_SATCHEL_AUDIO);
			playOpenSatchelSound();
			openCostumizer();
		}
		
		protected function playOpenSatchelSound():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + Inventory.OPEN_SATCHEL_AUDIO);
		}
		
		public function openCostumizer( look:LookData = null, fromCard:Boolean = false, skipNPCCheck:Boolean = false, delegate:CostumizerDelegate=null, isPet:Boolean=false):Costumizer
		{
			/*
			Drew - This if check was added to prevent people from spamming the Costumize button on 2 different cards in
			your Inventory, which was causing crashes when trying to remove the Inventory popup and add the Costumizer popup.
			*/
			if(!(_currentPopup is Costumizer))
			{
				var costumizer:Costumizer = new Costumizer( null, look, fromCard, skipNPCCheck, isPet );
				costumizer.delegate = delegate;
				initFullScreenPopup( costumizer );
				return costumizer;
			}
			return null;
		}
		
		///////////////////////////////////////// MAP BUTTON /////////////////////////////////////////
		
		protected function onMapClick( btn:Entity ):void 
		{
			// TODO :: Need better sound for blimp
			//AudioUtils.play(this, SoundManager.EFFECTS_PATH + 'ui_map.mp3');	// this (paper rustling) doesn't sound right for a button
			if(shellApi.networkAvailable())
			{
				shellApi.track(MAP + OPENED, null, null, SceneUIGroup.UI_EVENT);
				// Platform check now happens in the Map popup itself, though it could happen here now that we are creating platform specific classes
				super.shellApi.loadScene((shellApi.sceneManager).gameData.mapClass);
			}else
			{
				shellApi.showNeedNetworkPopup();
			}
			
		}
		
		///////////////////////////////////////// FRIENDS BUTTON /////////////////////////////////////////
		
		/**
		 * Create Friends hud button.
		 * Functionality varies across platforms, so this is overridden by extending classes. 
		 * @param btnClip
		 * @param index
		 * @param name
		 * @param startSpatial
		 */
		protected function createFriendsButton( btnClip:MovieClip, index:int, name:String, startSpatial:Spatial):void 
		{
			btnClip.x = startSpatial.x - (BUTTON_BUFFER * 5 - BUTTON_OFFSET);
			_friendsBtn = createHudButton( btnClip, index++, name, startSpatial, onFriendsClick );
		}
		
		/**
		 * BROWSER USE ONLY (FOR NOW)
		 * Will remain inactive until we have friends implementd on mobile 
		 * @param btn
		 */
		private function onFriendsClick( btn:Entity ):void 
		{
			goToFriends();
		}
		
		/**
		 * Currently platform specific, overridden by extending classes
		 */
		protected function goToFriends():void 
		{
		}
		
		///////////////////////////////////////// STORE BUTTON /////////////////////////////////////////
		
		/**
		 * Create Friends hud button.
		 * Functionality varies across platforms, so this is overridden by extending classes. 
		 * @param btnClip
		 * @param index
		 * @param name
		 * @param startSpatial
		 */
		protected function createStoreButton( btnClip:MovieClip, index:int, name:String, startSpatial:Spatial ):void 
		{
			btnClip.x = startSpatial.x - (BUTTON_BUFFER * 4 - BUTTON_OFFSET);
			_friendsBtn = createHudButton( btnClip, index++, name, startSpatial, onStoreClick );
		}
		
		/**
		 * @param btn
		 */
		protected function onStoreClick( btn:Entity ):void 
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + SoundManager.STANDARD_BUTTON_CLICK_FILE);
			shellApi.track(STORE + OPENED, null, null, SceneUIGroup.UI_EVENT);
			
			if (AppConfig.mobile)
			{
				var text:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.hud.store", SceneUIGroup.CONFIRMATION_PREAMBLE + GO_TO_STORE);
				var dialogBox:ConfirmationDialogBox = createHudDialogBox( 1, String("\r" + text), openStore );
			}
			else
			{
				if(shellApi.networkAvailable())
				{
					openStore();
				}else
				{
					shellApi.showNeedNetworkPopup();
				}
			}
		}
		
		/**
		 * Currently platform specific, overridden by extending classes
		 */
		protected function openStore():void 
		{
			super.shellApi.loadScene((shellApi.sceneManager).gameData.storeClass);
		}
		
		///////////////////////////////////////// REALMS BUTTON /////////////////////////////////////////
		
		/**
		 * FOR OVERRIDE : Create Realms hud button, currently BROWSER ONLY
		 * Functionality varies across platforms, so this is overridden by extending classes. 
		 * @param btnClip
		 * @param index
		 * @param name
		 * @param startSpatial
		 */
		protected function createRealmsButton( btnClip:MovieClip, index:int, name:String, startSpatial:Spatial ):void 
		{
			if( btnClip )
			{
				btnClip.parent.removeChild(btnClip);
			}
		}
		
		///////////////////////////////////////// HOME BUTTON /////////////////////////////////////////
		
		/**
		 * FOR OVERRIDE : Creation Home hud button varies across platforms
		 * Functionality varies across platforms, so this is overridden by extending classes. 
		 * @param btnClip
		 * @param index
		 * @param name
		 * @param startSpatial
		 */
		protected function createHomeButton( btnClip:MovieClip, index:int, name:String, startSpatial:Spatial ):void 
		{
			_homeBtn = createHudButton( btnClip, index++, HOME, startSpatial, onHomeClick );
		}
		
		protected function onHomeClick( btn:Entity ):void 
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + SoundManager.STANDARD_BUTTON_CLICK_FILE);
			shellApi.track(HOME + OPENED, null, null, SceneUIGroup.UI_EVENT);
			
			var text:String = LanguageManager(shellApi.getManager(LanguageManager)).get("shared.hud.home", SceneUIGroup.CONFIRMATION_PREAMBLE + GO_HOME);
			var dialogBox:ConfirmationDialogBox = createHudDialogBox( 1, String( "\r" + text), goToHome );
		}
		
		protected function goToHome():void 
		{
			super.shellApi.loadScene((shellApi.sceneManager).gameData.homeClass);
		}
		
		/////////////////////////////////////// AUDIO BUTTON ///////////////////////////////////////
		
		protected function onAudioClicked( btn:Entity ):void 
		{
			// determine if sound is on or off, using button's isSelected
			var button:Button = _audioButton.get(Button)
			var flag:Boolean = !button.isSelected;
			button.isSelected = flag;
			this.soundManager.muteMixer(flag);
			
			// update user field
			shellApi.setUserField("muted", flag, "", true);
			
			shellApi.track( flag ? SOUND_MUTED : SOUND_UNMUTED, null, null, SceneUIGroup.UI_EVENT);
			super.playClick();	// this won't be heard when mixer is muted, but it will be when the mixer is un-muted	
		}
		
		protected function updateAudioBtn( btnEntity:Entity ):void 
		{
			this.soundManager.updateMuted();
			var mixerVolume:Number = this.soundManager.mixerVolume;
			if( _audioButton )
			{
				Button(_audioButton.get(Button)).isSelected = (0 == mixerVolume);
			}
		}
		
		///////////////////////////////////////// SETTINGS /////////////////////////////////////////
		
		protected function onSettingsClick( btn:Entity ):void 
		{
			// if doesn't exists, create new popup
			if (!_settingsPanel)
			{
				super.playClick();
				shellApi.track(SETTINGS + OPENED, null, null, SceneUIGroup.UI_EVENT);
				
				_settingsPanel = new SettingsPopup();
				//_settingsPanel.pauseParent = false;
				_settingsPanel.popupRemoved.addOnce( closeSettings );
				this.addChildGroup(_settingsPanel);
				_settingsPanel.init( super.groupContainer );
				enableHUDButtons(false, true );
				openingHudElement.dispatch(_settingsPanel.id);
			} 
			else 				// if does exist, close
			{
				super.playCancel();
				shellApi.track(SETTINGS + CLOSED, null, null, SceneUIGroup.UI_EVENT);
				_settingsPanel.close();
			}
		}
		
		public function closeSettings():void
		{
			updateAudioBtn(_audioButton);		// is sound is now off, audio button should reflect this
			enableHUDButtons( true, true );
			_settingsPanel = null;
		}
		
		/////////////////////////////////////// BOTTOM ROW ///////////////////////////////////////
		
		protected function setupBottomRow():void
		{
			if( !_bottomRow )
			{
				screen.bottomRow.x = 0;
				screen.bottomRow.y = super.shellApi.viewportHeight;
				_bottomRow = EntityUtils.createSpatialEntity( this, screen.bottomRow );
				_bottomRow.add( new Tween() );
			}
		}
		
		protected function disableBottomBtns( disable:Boolean ):void
		{
			if( _saveBtn )	{ Button(_saveBtn.get(Button)).isDisabled = disable; }
			if( _actionBtn ){ Button(_actionBtn.get(Button)).isDisabled = disable; }
		}
		
		/////////////////////////////////////// ACTION BUTTON ///////////////////////////////////////
		/// MOBILE ONLY //
		
		/**
		 * Setup Action button.
		 * If Touch screen (mobile) save reference and disable, otherwise remove
		 */
		protected function setupActionButton( btnClip:MovieClip, remove:Boolean = true ):void
		{
			trace("does btn exist? " + btnClip);
			if( btnClip )
			{
				if( !remove )
				{
					// hide action button
					_actionBtnClip = btnClip;
					_actionBtnClip.visible = false;
					_actionBtnClip.mouseEnabled = false;
				}
				else
				{
					removeClip( btnClip );
				}
			}
		}
		
		/**
		 * Create Action button Entity
		 * Called by external classes in cases where an Action button is needed ( ex. SpcialAbiltiyControlSystem )
		 * @param clickedHandler
		 * @param screenPosition
		 * @param buffer
		 * @return - Entity for action button
		 */
		public function createActionButton( clickedHandler:Function = null, screenPosition:String = DisplayPositions.CENTER,  buffer:int = BUTTON_OFFSET):Entity
		{
			trace("action buttun clip exists? "+(_actionBtnClip != null))
			if(_actionBtnClip == null && !isReady)
			{
				ready.add(Command.create(waitThenCreateActionButton, clickedHandler, screenPosition, buffer));
				return null;
			}
			_actionBtnClip.mouseEnabled = true;
			
			if( _actionBtn == null )
			{
				_actionBtn = ButtonCreator.createButtonEntity( _actionBtnClip, this, clickedHandler, null, null, null, false );
				// for mobile add touch support so you can use the button when an alternate touch is active
				if(PlatformUtils.isMobileOS)
				{
					InteractionCreator.addToComponent(_actionBtnClip, [InteractionCreator.TOUCH], _actionBtn.get(Interaction));
				}
				
				EntityUtils.visible( _actionBtn );
				positionActionButton( screenPosition, buffer )
			}
			
			EntityUtils.visible( _actionBtn );
			EntityUtils.visible( _bottomRow );
			EntityUtils.position( _bottomRow, 0, super.shellApi.viewportHeight );
			
			return(_actionBtn);
		}
		
		private function waitThenCreateActionButton(group:Group, clickedHandler:Function = null, screenPosition:String = DisplayPositions.CENTER,  buffer:int = BUTTON_OFFSET):void
		{
			trace("had to wait before it could be created");
			createActionButton(clickedHandler, screenPosition, buffer);
		}
		
		/**
		 * Remove Action button Entity 
		 */
		public function removeActionButton():void
		{
			if( _actionBtn != null )
			{
				// NOTE :: before removing Entity, slate Display component so that displayObject is not lost during RenderSystem's remove node process
				var display:Display = _actionBtn.get(Display);
				display.clearReference();
				_actionBtnClip.visible = false;
				
				super.removeEntity( _actionBtn );
				_actionBtn = null;
			}
		}
		
		/**
		 * Add handler to Action button interaction
		 * @param handler
		 */
		public function addActionButtonHandler( handler:Function ):void
		{
			trace("add action button");
			if( handler != null )
			{
				if( _actionBtn == null )
				{
					trace("create action button");
					createActionButton( handler );
				}
				else
				{
					trace("action button already exists");
					Interaction(_actionBtn.get(Interaction)).click.add( handler );
				}
			}
		}
		
		/**
		 * Remove handler from Action button interaction. 
		 * @param handler
		 */
		public function removeActionButtonHandler( handler:Function ):void
		{
			if( handler != null && _actionBtn != null )
			{
				Interaction(_actionBtn.get(Interaction)).click.remove( handler );
			}
		}
		
		private function positionActionButton( screenPosition:String = DisplayPositions.BOTTOM_RIGHT, buffer:int = BUTTON_OFFSET ):void
		{
			if( _actionBtn == null )
			{
				_actionBtn = createActionButton();
			}
			
			var spatial:Spatial = _actionBtn.get(Spatial);
			spatial.x = shellApi.viewportWidth - (spatial.width/2 + buffer);
			spatial.y = -spatial.height/2 - buffer;
		}
		
		/////////////////////////////////////// SAVE BUTTON ///////////////////////////////////////
		
		/**
		 * BROWSER ONLY - FOR OVERRIDE in browser pop version.
		 */
		protected function setupSaveButton( clip:MovieClip ):void
		{
			removeClip( clip );
		}
		
		/////////////////////////////////////// PHOTO ICON ///////////////////////////////////////
		
		/**
		 * BROWSER ONLY - FOR OVERRIDE in browser pop version.
		 */
		protected function setupPhotoIcon(clip:MovieClip):void
		{
			removeClip( clip );
		}
		
		/**
		 * BROWSER ONLY - FOR OVERRIDE in browser pop version.
		 * @param callback
		 */
		public function showPhotoNotification( callback:Function = null ):void 
		{
			if( callback != null )	{ callback(); }
		}
		
		/////////////////////////////////////// HELPER ///////////////////////////////////////
		
		/**
		 * BROWSER ONLY - FOR OVERRIDE in browser pop version.
		 */
		protected function removeClip(clip:MovieClip):void
		{
			if( clip )
			{
				clip.parent.removeChild( clip );
			}
		}
	}
}