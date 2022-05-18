package game.scenes.lands.shared.groups {
	
	/**
	 * Group started out as the Tile Editing group only, but the UI all got put in the same swf,
	 * and now it's a UI group + some editing functions that aren't convenient anywhere.
	 * 
	 */
	
	import com.poptropica.AppConfig;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.SkinPart;
	import game.components.motion.TargetSpatial;
	import game.components.timeline.Timeline;
	import game.components.ui.Cursor;
	import game.components.ui.FloatingToolTip;
	import game.components.ui.ToolTip;
	import game.components.ui.ToolTipActive;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.SledgeHammer;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.lands.LandsEvents;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.ObjectIconPair;
	import game.scenes.lands.shared.classes.SharedTipTarget;
	import game.scenes.lands.shared.classes.SuperJump;
	import game.scenes.lands.shared.classes.TypeSelector;
	import game.scenes.lands.shared.components.Disintegrate;
	import game.scenes.lands.shared.components.FocusTileComponent;
	import game.scenes.lands.shared.components.InputManager;
	import game.scenes.lands.shared.components.LandEditContext;
	import game.scenes.lands.shared.components.LandHiliteComponent;
	import game.scenes.lands.shared.components.SharedToolTip;
	import game.scenes.lands.shared.components.ThrowHammer;
	import game.scenes.lands.shared.components.TileBlaster;
	import game.scenes.lands.shared.systems.AvalancheSystem;
	import game.scenes.lands.shared.systems.BlastTileSystem;
	import game.scenes.lands.shared.systems.DisintegrateSystem;
	import game.scenes.lands.shared.systems.SharedToolTipSystem;
	import game.scenes.lands.shared.systems.ThrowHammerSystem;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.LandAssetLoader;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;
	import game.scenes.lands.shared.ui.LandMenu;
	import game.scenes.lands.shared.ui.QuickBar;
	import game.scenes.lands.shared.ui.ScrollControl;
	import game.scenes.lands.shared.ui.panes.DialogPane;
	import game.scenes.lands.shared.ui.panes.LandModeMenu;
	import game.scenes.lands.shared.ui.panes.LandPane;
	import game.scenes.lands.shared.ui.panes.LandStatusPane;
	import game.scenes.lands.shared.ui.panes.LevelUpPane;
	import game.scenes.lands.shared.ui.panes.LosePane;
	import game.scenes.lands.shared.ui.panes.TemplatePane;
	import game.scenes.lands.shared.util.LandUtils;
	import game.scenes.virusHunter.condoInterior.systems.SimpleUpdateSystem;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class LandUIGroup extends Group {
		
		/**
		 * need to rush this through for star wars campaign.
		 */
		private const CAMPAIGN_ITEM:String = "";
		
		private var ZOOM_IN_SCALE:Number = 2.0;
		private var ZOOM_BASE_SCALE:Number = 1.0;
		private var ZOOM_OUT_SCALE:Number;
		
		private var _landGroup:LandGroup;
		public function get landGroup():LandGroup { return this._landGroup; }
		
		/**
		 * specifies which primary mode the ui is in. edit/mining/play
		 * template is included for now but will probably ultimately fall under editing.
		 */
		private var _uiMode:uint;
		public function get uiMode():uint { return this._uiMode; }
		/**
		 * set the LandEditMode to either LandEditMode.CREATE, LandEditMode.MINING, LandEditMode.CREATE, or LandEditMode.TEMPLATE
		 */
		public function set uiMode( mode:uint ):void {
			
			if ( (mode == this._uiMode) || (mode & this.allowedModes) == 0 ) {
				return;
			}
			
			if ( this.templatePane.visible == true && mode != LandEditMode.TEMPLATE ) {
				this.templatePane.hide();
			}
			
			this.hintArrow.visible = false;
			this._uiMode = mode;
			if ( mode == LandEditMode.MINING ) {
				this.beginMiningMode();
			} else if ( mode == LandEditMode.EDIT ) {
				this.beginEditMode();
			} else if ( mode == LandEditMode.TEMPLATE ) {
				
				this.beginTemplateMode();
				
			} else if ( mode & LandEditMode.SPECIAL ) {
				
				if ( mode & LandEditMode.MINING ) {
					this.beginMiningMode();
				} else if ( mode & LandEditMode.EDIT ) {
					this.beginEditMode();
				} else {
					this.beginPlayMode();
				}
				
			} else {
				this.beginPlayMode();
			} //
			
			this.onUIModeChanged.dispatch( mode );
			
		} //
		
		/**
		 * onUIModeChanged( uint )
		 */
		public var onUIModeChanged:Signal;
		
		private var levelUpPane:LevelUpPane;
		private var dialogPane:DialogPane;
		private var losePane:LosePane;
		
		/**
		 * points at places on the interface during certain level ups.
		 */
		private var hintArrow:MovieClip;
		
		/**
		 * tells the user how poptanium and levels work
		 */
		private var instructionPane:MovieClip;
		
		/**
		 * guidance from the Master Creator
		 */
		private var helpfulHint:MovieClip;
		
		private var modeMenu:LandModeMenu;
		public function getModeMenu():LandModeMenu { return this.modeMenu }
		
		/**
		 * A pane where you can select some basic brush size, fg/bg options, and bring up the material pane.
		 */
		protected var landMenu:LandMenu;
		public function getLandMenu():LandMenu { return this.landMenu; }
		
		/**
		 * of materials, worldMenu, helpPane, only one can be visible at a time.
		 */
		private var activePane:LandPane;
		
		/**
		 * hides/shows the land menu.
		 */
		private var btnToggleMenu:MovieClip;
		
		/**
		 * ugh place for this. this template pane probably will get swapped out pretty soon anyway.
		 * it's so jordan can create and edit templates along with other artists, if they want.
		 */
		private var templatePane:TemplatePane;
		
		/**
		 * used to display a lock on various controls.
		 */
		private var _lockBitmap:BitmapData;
		public function get lockBitmap():BitmapData {
			return this._lockBitmap;
		}
		
		/**
		 * used to display a loading icon on various controls.
		 */
		private var _loadingBitmap:BitmapData;
		public function get loadingBitmap():BitmapData {
			return this._loadingBitmap;
		}
		
		/**
		 * land game data.
		 */
		private var _gameData:LandGameData;
		public function get gameData():LandGameData { return this._gameData; }
		
		public function get assetLoader():LandAssetLoader {
			return this.landGroup.assetLoader;
		}
		
		/**
		 * component that collects the event dispatchers for all ui buttons.
		 */
		private var _inputManager:InputManager;
		public function get inputManager():InputManager {
			return this._inputManager;
		}
		
		/**
		 * true if the land mode menu and realms menu is visible.
		 */
		private var editingEnabled:Boolean;
		
		/**
		 * OR'd combination of the LandEditModes are available to the user.
		 */
		private var allowedModes:uint;
		
		/**
		 * I've gone back and forth on making the editEntity the same as the general gameEntity.  For now they are the same.
		 * The lightning strike might eventually be moved out into its own entity.
		 * 
		 * the reason for using the same entity is that a lot of game systems need to reference the same components -
		 * timedTileList, FocusedTile, TileBlaster, game audio.. its just easier to find them all in a single entity than to
		 * track multiple node lists.
		 */
		private var editContext:LandEditContext;
		public function getEditContext():LandEditContext { return this.editContext; }
		
		private var hiliteComponent:LandHiliteComponent;
		public function getHiliteComponent():LandHiliteComponent { return this.hiliteComponent; }
		private var focus:FocusTileComponent;
		
		private var statusPane:LandStatusPane;
		public function getStatusPane():LandStatusPane {
			return this.statusPane;
		}
		
		/**
		 * displays shared tool tips.
		 */
		private var _toolTipEntity:Entity;
		public function get toolTipEntity():Entity { return this._toolTipEntity; }
		
		/**
		 * used to create UI tool tips that use a single shared entity.
		 */
		public var sharedTip:SharedToolTip;
		
		private var scrollControl:ScrollControl;
		public function getScrollControl():ScrollControl { return this.scrollControl; }
		
		/**
		 * clip that holds the user interface buttons and the palette as a subclip.
		 */
		protected var uiClip:MovieClip;
		public function getUIClip():MovieClip {
			return this.uiClip;
		}
		
		public function get curScene():PlatformerGameScene { return this.landGroup.curScene; }
		
		public function LandUIGroup( landGroup:LandGroup, scene:PlatformerGameScene ) {
			
			super();
			
			this.allowedModes = uint.MAX_VALUE;
			
			this._landGroup = landGroup;
			this.onUIModeChanged = new Signal( uint );
			
		} //
		
		public function init( gameData:LandGameData, ui_clip:String ):void {
			
			if ( this.getSystem( SimpleUpdateSystem ) == null ) {
				this.addSystem( new SimpleUpdateSystem(), SystemPriorities.update );
			}
			
			this._gameData = gameData;
			
			// function to display the level up dialog on level change.
			gameData.progress.onLevelUp.add( this.onLevelUp );
			
			this.ZOOM_OUT_SCALE = this.shellApi.viewportWidth / this.curScene.sceneData.bounds.width;
			
			this.createEditEntity();
			
			this.shellApi.loadFile( this.landGroup.sharedAssetURL + ui_clip, this.onAssetsLoaded );
			
		} //
		
		/**
		 * flash a little graphic when there's not enough poptanium to do something.
		 */
		public function showPoptaniumWarning():void {
			
			var warning:MovieClip = this.uiClip.poptaniumWarning;
			warning.play();
			warning.visible = true;
			
			// annoying final frame check. move this somewhere else in time.
			this.inputManager.addEventListener( warning, Event.ENTER_FRAME, this.checkHideWarning );
			
			//AudioUtils.play(this, SoundManager.EFFECTS_PATH + "alarm_04.mp3");
			var url:String = SoundManager.EFFECTS_PATH + "alarm_04.mp3";
			var audio:Audio = this.landGroup.gameEntity.get( Audio ) as Audio;
			if ( !audio.isPlaying( url ) ) {
				audio.play( url );
			}
			
		} //
		
		private function checkHideWarning( e:Event ):void {
			
			var warning:MovieClip = e.target as MovieClip;
			if ( warning.currentFrame == warning.totalFrames ) {
				
				this.inputManager.removeEventListener( warning, Event.ENTER_FRAME, this.checkHideWarning );
				warning.gotoAndStop( 1 );
				warning.visible = false;
				
			}
			
		} //
		
		/**
		 * user leveled up event listener.
		 * this will display a level up pane and handle some annoying hint-triggers.
		 */
		private function onLevelUp( newLevel:int, unlocked:Vector.<ObjectIconPair> ):void {
			
			// brain tracking :\
			super.shellApi.track( "LevelUp", newLevel, null, LandGroup.CAMPAIGN );
			
			this.levelUpPane.showLevelUp( newLevel, unlocked );
			
			if ( (newLevel == 5 || newLevel == 10 || newLevel == 15) && (this._uiMode & LandEditMode.MINING) ) {
				this.landMenu.updateMenuBar( this._uiMode );
			} //
			
		} //
		
		private function showMaterialHint( newMode:int ):void {
			
			this.hintArrow.x = this.landMenu.pane.x + this.landMenu.getMaterialsBtn().x;
			this.hintArrow.visible = true;
			
		} //
		
		/**
		 * refresh the status view after level up pane has been closed - the level bar will have changed.
		 */
		/*private function onLevelUpClosed():void {
		
		this.statusPane.refresh();
		
		} //*/
		
		private function onAssetsLoaded( uiClip:MovieClip ):void {
			
			this.uiClip = uiClip;
			this.uiClip.mouseEnabled = false;
			
			this.initSurveyButton();
			
			// warning for not-enough poptanium.
			var warning:MovieClip = uiClip.poptaniumWarning;
			warning.mouseChildren = warning.mouseEnabled = false;
			warning.gotoAndStop( 1 );
			warning.visible = false;
			
			this.hintArrow = this.uiClip.arrowHint;
			this.hintArrow.visible = this.hintArrow.mouseChildren = this.hintArrow.mouseEnabled = false;
			
			this.initInstructionPane();
			
			this.initHelpfulHint();
			
			this.curScene.overlayContainer.addChildAt( uiClip, 0 );
			
			this.initUIBitmaps();			// must be done before materialPane - which use the lock Icon
			
			this.initUIPanes();			// various ui panes: help pane, status menu?, materialsPane, modeMenu
			this.initLandMenu();		// must happen after UI pane because it references the materialPane. annoying I know.
			
			this.createTemplatePane();
			
			this.scrollControl = new ScrollControl( uiClip, this );
			
			this.uiMode = LandEditMode.PLAY;
			if ( super.shellApi.checkItemEvent( "hammer" ) ) {
				
				this.enableEditing();
				
			} else {
				this.disableEditing();
			} // end-if.
			this.landGroup.gameEntity.sleeping = false;
			
			// dispatches the group ready signal.
			super.groupReady();
			
		} //
		
		private function initSurveyButton():void {
			
			var btn:MovieClip = this.uiClip.btnSurvey;
			this.uiClip.removeChild( btn );
			
			/*if ( this.shellApi.checkEvent( (this.landGroup.mainScene.events as LandsEvents).TOOK_SURVEY ) ) {
			
			this.uiClip.removeChild( btn );
			
			} else {
			
			btn.mouseChildren = false;
			if ( this.gameData.progress.curLevel < 5 ) {
			
			btn.visible = false;
			this.gameData.progress.onLevelUp.add( this.onLevelUpSurvey );
			
			} else {
			btn.visible = true;
			LandUtils.makeUIBtn( btn, this, this.onSurveyClicked );
			} //
			
			} //*/
			
		} //
		
		public function hasEditGrid():Boolean {
			return ( this.hiliteComponent.tileGrid.visible == true );
		}
		
		public function showEditGrid():void {
			
			this.hiliteComponent.tileGrid.visible = true;
			
		} //
		
		public function hideEditGrid():void {
			
			this.hiliteComponent.tileGrid.visible = false;
			
		} //
		
		private function initInstructionPane():void {
			
			this.instructionPane = this.uiClip.instructionPane;
			
			if ( this.shellApi.checkEvent( (this.landGroup.curScene.events as LandsEvents).SAW_INSTRUCTIONS ) ) {
				
				//this.uiClip.removeChild( this.instructionPane );
				//this.instructionPane = null;
				this.instructionPane.visible = false;
				
			} else {
				
				if ( super.shellApi.checkItemEvent( "hammer" ) ) {
					this.showInstructionPane();
				} else {
					this.instructionPane.visible = false;
				}
				
			} //
			
		}
		
		private function hideInstructionPane():void {
			
			this.instructionPane.mouseEnabled = false;
			this.inputManager.removeListeners( this.instructionPane );
			this.sharedTip.removeToolTip( this.instructionPane );
			this.instructionPane.visible = false;
			//this.uiClip.removeChild( this.instructionPane );
			//this.instructionPane = null;
			
		} //
		
		private function showInstructionPane():void {
			
			this.instructionPane.mouseEnabled = true;
			
			LandUtils.makeUIBtn( this.instructionPane, this, this.onInstructionPaneClicked );
			this.sharedTip.addClipTip( this.instructionPane, ToolTipType.CLICK );
			
			this.instructionPane.visible = true;
			this.shellApi.completeEvent( (this.landGroup.curScene.events as LandsEvents).SAW_INSTRUCTIONS );
			
		}
		
		private function initHelpfulHint():void {
			
			this.helpfulHint = this.uiClip.helpfulHint;
			this.helpfulHint.visible = false;
			this.helpfulHint.stop();
			
		}
		
		public function hideHelpfulHint():void {
			
			if ( this.helpfulHint.visible ) {
				this.helpfulHint.mouseEnabled = false;
				this.inputManager.removeListeners( this.helpfulHint );
				this.sharedTip.removeToolTip( this.helpfulHint );
				this.helpfulHint.visible = false;
			}
			
		}
		
		public function showHelpfulHint(frameNum:uint):void {
			
			this.helpfulHint.mouseEnabled = true;
			
			LandUtils.makeUIBtn( this.helpfulHint, this, this.onHelpfulHintClicked );
			this.sharedTip.addClipTip( this.helpfulHint, ToolTipType.CLICK );
			
			this.helpfulHint.gotoAndStop( frameNum );
			this.helpfulHint.visible = true;
			
			//1 happens when player gets first poptanium
			if ( frameNum == 1 ) {
				this.showCreateHint();
			} else if (frameNum == 2) {
				this.showMaterialHint( LandEditMode.EDIT );
			} else if (frameNum == 3) {
				if ( !this.shellApi.checkEvent( (this.landGroup.curScene.events as LandsEvents).GOT_REALMS_HINT ) ) {
					this.showRealmsHint();
				}
			}
			
		}
		
		/*private function onSurveyClicked( e:MouseEvent ):void {
		
		var pd:ProfileData = this.shellApi.profileManager.active;
		
		//updated url to new survey -Jordan 10/16/14
		var req:URLRequest = new URLRequest( "https://www.research.net/s/FCZ5FRC" );
		var vars:URLVariables = new URLVariables();
		vars.Age = pd.age;
		vars.Gender = pd.gender;
		req.data = vars;
		req.method = URLRequestMethod.GET;
		
		navigateToURL( req, "_blank" );
		
		this.shellApi.completeEvent( (this.landGroup.mainScene.events as LandsEvents).TOOK_SURVEY );
		
		var btn:MovieClip = this.uiClip.btnSurvey;
		this.inputManager.removeListeners( btn );
		this.uiClip.removeChild( btn );
		
		} //*/
		
		/*private function onLevelUpSurvey( newLevel:int, unlocked:Vector.<ObjectIconPair> ):void {
		
		if ( newLevel >= 5 ) {
		this.gameData.progress.onLevelUp.remove( this.onLevelUpSurvey );
		this.initSurveyButton();
		}
		
		} //*/
		
		private function initUIPanes():void {
			
			//this.uiClip.statusPane.mouseChildren = this.uiClip.statusPane.mouseEnabled = false;
			
			this.statusPane = new LandStatusPane( this, this.uiClip.statusPane, this._gameData.inventory, this._gameData.progress );
			
			this.levelUpPane = new LevelUpPane( this.uiClip.levelUpPane, this );
			//this.levelUpPane.onClosed = this.onLevelUpClosed;
			
			this.losePane = new LosePane( this.uiClip.losePane, this );
			this.dialogPane = new DialogPane( this.uiClip.dialogPane, this );
			
			this.modeMenu = new LandModeMenu( this.uiClip.modeMenu, this );
			
			this.btnToggleMenu = this.uiClip.btnToggleMenu;
			this.btnToggleMenu.gotoAndStop( 1 );
			LandUtils.makeUIBtn( this.btnToggleMenu, this, this.onToggleMenuClicked );
			this.sharedTip.addClipTip( btnToggleMenu, ToolTipType.CLICK );
			
			LandUtils.makeUIBtn( this.uiClip.statusPane, this, this.onInstructionPaneClicked );
			this.sharedTip.addClipTip( this.uiClip.statusPane, ToolTipType.CLICK );
			
		} //
		
		public function showLosePane( onClosed:Function=null ):void {
			
			// when you die go back to play mode or mining mode.
			if ( (this.uiMode & ( LandEditMode.PLAY + LandEditMode.MINING )) == 0 ) {
				this.uiMode = LandEditMode.PLAY;
			}
			
			this.losePane.showLose( onClosed );
			
		} //
		
		public function showDialog( dialogText:String ):void {
			
			this.dialogPane.showMessage( dialogText );
			
		} //
		
		private function createTemplatePane():void {
			
			if ( this.uiClip.templatePane ) {
				this.templatePane = new TemplatePane( this.uiClip.templatePane, this );
			} // end-if.
			
		} //
		
		public function isPainting():Boolean {
			return this.editContext.isPainting;
		}
		
		/**
		 * layerName must be 'foreground' or 'background'
		 */
		public function setCurLayer( layerName:String ):void {
			
			if ( layerName == "background" ) {
				
				var layerEntity:Entity = this.curScene.getEntityById( layerName );
				var display:Display = layerEntity.get( Display ) as Display;
				
				display.displayObject.addChild( this.hiliteComponent.tileGrid );
				
				this.editContext.setCurLayer( this.gameData.getBGLayer() );
				
			} else {
				
				this.curScene.hitContainer.addChild( this.hiliteComponent.tileGrid );
				this.editContext.setCurLayer( this.gameData.getFGLayer() );
				
			}
			
		} //
		
		/**
		 * allows the user to begin mining and editing land.
		 */
		public function enableEditing():void {
			
			this.inputManager.addEventListener( this.uiClip.stage, KeyboardEvent.KEY_DOWN, this.onKeyDown );
			this.editingEnabled = true;
			this.modeMenu.show();
			this.landMenu.visible = true;
			this.btnToggleMenu.visible = true;
			
		} //
		
		public function disableEditing():void {
			
			this.editingEnabled = false;
			this.modeMenu.hide();
			this.landMenu.visible = false;
			this.btnToggleMenu.visible = false;
			
		} //
		
		/**
		 * mode for playing in public realms.
		 */
		public function setPublicMode():void {
			
			this.allowedModes = LandEditMode.PLAY;
			this.modeMenu.setPublicMode();
			
			if ( (this._uiMode & this.allowedModes) == 0 ) {
				// User is in a mode that isn't allowed.
				this.uiMode = LandEditMode.PLAY;
			} //
			
		} //
		
		/**
		 * mode for playing in private/user realms.
		 */
		public function setPrivateMode():void {
			
			this.modeMenu.setPrivateMode();
			this.allowedModes = uint.MAX_VALUE;
			
		} //
		
		public function showHammerHint():void {
			
			this.hintArrow.visible = true;
			if ( this.instructionPane != null ) {
				this.showInstructionPane();
			}
			
		} //
		
		public function showCreateHint():void {
			
			if ( this.gameData.inventory.getResourceCount( "experience" ) == 0 ) {
				
				this.hintArrow.visible = true;
				this.hintArrow.x = 186; //position over btnCreate
				
			}
			
		} //
		
		public function showRealmsHint():void {
			
			this.hintArrow.visible = true;
			this.hintArrow.x = 37; //position over btnRealms
			
		} //
		
		/**
		 * select the current tile type from the quickBar and change the edit mode if necessary.
		 */
		public function selectCurType():void {
			
			var sel:TypeSelector = this.landMenu.getQuickBar().getCurrentSelection();
			if ( sel == null ) {
				
				this.focus.enabled = false;
				this.hiliteComponent.tileGrid.visible = false;
				this.hiliteComponent.hiliteBox.visible = false;
				
				// wait for a selection to be made before the EDIT mode is changed - although the UI mode is already changed.
				this.editContext.curEditMode = LandEditMode.PLAY;
				return;
				
			} //
			
			this.hiliteComponent.tileGrid.visible = true;
			this.hiliteComponent.hiliteBox.visible = true;
			
			this.selectTileType( sel, this.landMenu.getQuickBar().isFlipped() );
			
		} //
		
		/**
		 * select the tile type used for land editing. special checks need to be made to turn the focus system/grid on
		 * since it's disabled when no tile types are active.
		 */
		public function selectTileType( sel:TypeSelector, flipTile:Boolean=false ):void {
			
			if ( this.editContext.curTileType == null ) {
				
				// there was no previously selected tile type, so some basic things weren't visible before.
				this.hiliteComponent.tileGrid.visible = true;
				this.hiliteComponent.hiliteBox.visible = true;
				
			}
			
			var nextMode:int;
			this.focus.enabled = true;
			if ( (sel.tileType is ClipTileType) ) {
				nextMode = LandEditMode.DECAL;
			} else {
				nextMode = LandEditMode.EDIT;
			}
			
			this.editContext.flipped = flipTile;
			
			var tmap:TileMap = this.editContext.curLayer.getMapWithSet( sel.tileSet );
			if ( !tmap ) {
				return;
			} else if ( tmap != this.editContext.curTileMap ) {
				
				this.editContext.setCurTileMap( tmap );
				this.hiliteComponent.redrawGrid( this.editContext.curTileSize, tmap.rows, tmap.cols );
				
				if ( nextMode == LandEditMode.EDIT ) {
					this.hiliteComponent.setBrushSize( this.editContext.getCurBrushSize() );
				}
				
			} //
			
			this.editContext.curTileType = sel.tileType;
			this.editContext.curEditMode = nextMode;
			
		} //
		
		public function setLargeBrush( useLarge:Boolean ):void {
			
			if ( this.editContext.useLargeBrush == useLarge ) {
				return;
			}
			this.editContext.useLargeBrush = useLarge;
			
			if ( this.editContext.curEditMode == LandEditMode.EDIT ) {
				
				// redraw with the new brush size.
				this.hiliteComponent.setBrushSize( this.editContext.getCurBrushSize() );
				
			} //
			
		} //
		
		private function beginPlayMode():void {
			
			this.focus.enabled = true;
			
			this.editContext.curEditMode = LandEditMode.PLAY;
			// set the layer to the foreground so background tiles don't come into interactive-focus.
			this.editContext.setCurLayer( this._gameData.getFGLayer() );
			
			var player:Entity = this.landGroup.getPlayer();
			
			CharUtils.lockControls( player, false, false );
			
			this.scrollControl.hide();
			
			//SkinUtils.setSkinPart( player, SkinUtils.ITEM, SkinPart.DEFAULT_VALUE, false );
			SkinUtils.getSkinPart(player, SkinUtils.ITEM).revertValue();

			super.shellApi.camera.target = player.get( Spatial );
			Cursor( super.shellApi.inputEntity.get(Cursor) ).defaultType = ToolTipType.NAVIGATION_ARROW;
			
			this.hiliteComponent.tileGrid.visible = false;
			this.hiliteComponent.hiliteBox.visible = false;
			
		} //
		
		private function beginTemplateMode():void {
			
			this.hiliteComponent.tileGrid.visible = this.hiliteComponent.hiliteBox.visible = true;
			CharUtils.lockControls( this.landGroup.getPlayer(), true, true );
			
			this.scrollControl.hide();
			
			var sp:Spatial = this.scrollControl.getScrollSpatial();
			// using the cam spatial here doesn't seem to work. maybe because there is a screen offset?
			var camView:Rectangle = super.shellApi.camera.viewport;
			// start wherever the camera is.
			if ( camView ) {
				sp.x = camView.x + camView.width/2;
				sp.y = camView.y + camView.height/2;
			}
			super.shellApi.camera.target = sp;
			
			this.focus.enabled = false;
			this.editContext.curEditMode = LandEditMode.TEMPLATE;
			
			this.hiliteComponent.setHiliteColor(this.hiliteComponent.RED_HILITE );
			this.hiliteComponent.autoUpdate = false;
			
			Cursor( super.shellApi.inputEntity.get(Cursor) ).defaultType = ToolTipType.TARGET;
			
			this.templatePane.show();
			
		} //
		
		private function beginMiningMode():void {
			
			this.landMenu.pickSelectedLayer();
			
			this.hiliteComponent.tileGrid.visible = false;
			this.hiliteComponent.hiliteBox.visible = true;
			
			var player:Entity = this.landGroup.getPlayer();
			CharUtils.lockControls( player, false, false );
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "land_hammer", false );
			
			this.scrollControl.hide();
			
			this.editContext.curEditMode = LandEditMode.MINING;
			
			this.focus.enabled = true;
			this.hiliteComponent.hiliteColor = this.hiliteComponent.RED_HILITE;
			this.hiliteComponent.hiliteRect.width = this.hiliteComponent.hiliteRect.height = this.editContext.curTileSize;
			this.hiliteComponent.redrawHilite();
			
			this.hiliteComponent.autoUpdate = true;
			
			super.shellApi.camera.target = player.get( Spatial );
			Cursor( super.shellApi.inputEntity.get(Cursor) ).defaultType = ToolTipType.NAVIGATION_ARROW;
			
		} //
		
		/**
		 * enables a special ui-mode.
		 * 
		 * this function was added for plugin support but has since been redacted.
		 *
		 */
		/*public function setSpecialMode( itemType:String, baseMode:int ):void {
		
		this._uiMode = baseMode + LandEditMode.SPECIAL;
		
		if ( baseMode == LandEditMode.MINING ) {
		this.beginMiningMode();
		} else if ( baseMode = LandEditMode.EDIT ) {
		this.beginEditMode();
		}
		
		SkinUtils.setSkinPart( this.landGroup.getPlayer(), SkinUtils.ITEM, itemType, false );
		
		this.onUIModeChanged.dispatch( this._uiMode );
		
		} //*/
		
		private function beginEditMode():void {
			
			if ( this.gameData.inventory.getResourceCount( "experience" ) == 0 ) {
				this.showMaterialHint( LandEditMode.EDIT );
			}
			
			this.scrollControl.show();
			
			var player:Entity = this.landGroup.getPlayer();
			
			CharUtils.lockControls( player, true, true );
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "land_hammer", false );
			
			// start panning at the player's location.
			var sp:Spatial = this.scrollControl.getScrollSpatial();
			if ( super.shellApi.camera.target != sp ) {
				
				var ps:Spatial = player.get( Spatial );
				sp.x = ps.x;
				sp.y = ps.y;
				
				super.shellApi.camera.target = sp;
				
			} //
			
			/**
			 * select the type currently selected in the quick menu, or no types in the quickbar,
			 * open the materials pane.
			 */
			this.landMenu.pickSelectedLayer();
			if ( this.landMenu.getQuickBar().isEmpty() ) {
				this.landMenu.showMaterialPane();
			} else {
				this.selectCurType();
			}
			
			this.focus.enabled = true;
			this.hiliteComponent.setHiliteColor( this.hiliteComponent.WHITE_HILITE );
			this.hiliteComponent.autoUpdate = true;
			
			Cursor( super.shellApi.inputEntity.get(Cursor) ).defaultType = ToolTipType.TARGET;
			
		} //
		
		/**
		 * toggle menu button clicked. slide the landMenu in and out of the view. change
		 * the frame of the toggle button.
		 */
		public function onToggleMenuClicked( e:MouseEvent ):void {
			
			if ( this.btnToggleMenu.currentFrame == 1 ) {
				this.btnToggleMenu.nextFrame();
			} else {
				this.btnToggleMenu.prevFrame();
			}
			this.landMenu.toggleSlider();
			
		} //
		
		/**
		 * hide the instruction pane when clicked
		 */
		public function onInstructionPaneClicked( e:MouseEvent ):void {
			
			if ( this.instructionPane.visible || !super.shellApi.checkItemEvent( "hammer" ) ) {
				this.hideInstructionPane();
			} else {
				this.showInstructionPane();
			}
			
		} //
		
		/**
		 * hide the helpful hint when clicked
		 */
		public function onHelpfulHintClicked( e:MouseEvent ):void {
			
			this.hideHelpfulHint();
			
		} //
		
		/**
		 * the edit pane is the part that actually has the tiles that can be selected.
		 */
		protected function initLandMenu():void {
			
			this.landMenu = new LandMenu( this.uiClip.landMenu );
			this.landMenu.init( this, this._gameData, this.uiClip );
			
		} //
		
		private function createEditEntity():void {
			
			var gameEntity:Entity = this.landGroup.gameEntity;
			// sleep until UI is loaded/initialized.
			gameEntity.sleeping = true;
			
			var grp:AudioGroup = this.getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			grp.addAudioToEntity( gameEntity, "lightningStrike" );
			grp.addAudioToEntity( gameEntity, "landEditor" );
			
			gameEntity.add( new TileBlaster(), TileBlaster );
			
			this.editContext = new LandEditContext();
			this.editContext.curEditMode = LandEditMode.PLAY;
			gameEntity.add( this.editContext, LandEditContext );
			
			this.hiliteComponent = new LandHiliteComponent( this.curScene.hitContainer, this._gameData.mapOffsetX );
			gameEntity.add( this.hiliteComponent, LandHiliteComponent );
			
			this.focus = new FocusTileComponent();
			gameEntity.add( this.focus, FocusTileComponent );
			
			this._inputManager = new InputManager();
			this.sharedTip = new SharedToolTip();
			this._toolTipEntity = new Entity()
				.add( new Display(), Display )
				.add( new Spatial(), Spatial )
				.add( new ToolTip(), ToolTip )
				.add( this._inputManager, InputManager )
				.add( new FloatingToolTip(), FloatingToolTip )
				.add( new Tween(), Tween )
				.add( new ToolTipActive(), ToolTipActive )
				.add( this.sharedTip, SharedToolTip );
			
			this.addSystem( new SharedToolTipSystem(), SystemPriorities.update );
			
			this.addEntity( this._toolTipEntity );
			
		} //
		
		public function zoomOut():void {
			
			( this.getGroupById(CameraGroup.GROUP_ID) as CameraGroup ).zoomTarget = this.ZOOM_OUT_SCALE;
			
		} //
		
		public function zoomIn():void {
			
			( this.getGroupById(CameraGroup.GROUP_ID) as CameraGroup ).zoomTarget = this.ZOOM_IN_SCALE;
			
		} //
		
		/**
		 * return camera zoom to its base state.
		 */
		public function zoomBase():void {
			
			( this.getGroupById(CameraGroup.GROUP_ID) as CameraGroup ).zoomTarget = this.ZOOM_BASE_SCALE;
			
		} //
		
		protected function onKeyDown( e:KeyboardEvent ):void {
			
			if ( e.target != this.uiClip.stage ) {
				return;
			}
			var key:uint = e.keyCode;
			
			if ( key == Keyboard.EQUAL ) {			// equal sign is unshifted plus sign.
				
				var cameraGroup:CameraGroup = this.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
				
				if ( cameraGroup.zoomTarget == this.ZOOM_OUT_SCALE ) {
					cameraGroup.zoomTarget = this.ZOOM_BASE_SCALE;
				} else {
					cameraGroup.zoomTarget = this.ZOOM_IN_SCALE;
				}
				
			} else if ( key == Keyboard.MINUS ) {
				
				cameraGroup = this.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
				if ( cameraGroup.zoomTarget == this.ZOOM_IN_SCALE ) {
					cameraGroup.zoomTarget = this.ZOOM_BASE_SCALE;
				} else {
					cameraGroup.zoomTarget = this.ZOOM_OUT_SCALE;
				}
				
			} else if ( key == Keyboard.TAB && this.editingEnabled ) {		// replace with a more standard enabled-hammer check.
				
				if ( this.allowedModes & LandEditMode.EDIT ) {
					this.landMenu.toggleMaterialPane();
					this.uiMode = LandEditMode.EDIT;
				}
				
			} else if ( key == Keyboard.NUMBER_1 && this.editingEnabled ) {
				
				this.uiMode = LandEditMode.PLAY;
				
			} else if ( key == Keyboard.NUMBER_2 && this.editingEnabled  ) {
				
				this.uiMode = LandEditMode.MINING;
				
			} else if ( key == Keyboard.NUMBER_3 && this.editingEnabled  ) {
				
				this.uiMode = LandEditMode.EDIT;
				
			} else if ( key == Keyboard.F  && this._gameData.inventory.getResourceCount("experience") > 200 ) {
				
				// Avalanche secret ability.
				
				var avalanche:AvalancheSystem = this._landGroup.getSystem( AvalancheSystem ) as AvalancheSystem;
				if ( avalanche == null ) {
					avalanche = new AvalancheSystem( this.landGroup );
					this.landGroup.addSystem( avalanche, SystemPriorities.update );
				}
				
				var sp:Spatial = this.landGroup.getPlayer().get( Spatial ) as Spatial;
				avalanche.beginAvalanche( sp.x, sp.y - 500 );
				
			} else if ( key == Keyboard.S ) {
				
				this.landGroup.snapshot();
				
			} else if ( key == Keyboard.T ) {
				
				if ( this.templatePane.isVisible() ) {
					
					this.templatePane.hide();
					
				} else {
					
					this.uiMode = LandEditMode.TEMPLATE;
					
				} // end-if.
				
			} else if ( key == Keyboard.NUMBER_4 ) {
				
				// need to work on all these hammer specials. the key codes don't really belong here.
				// need to mvoe them to the land menu probably.
				if ( this.gameData.progress.hasHammerPound() ) {
					this.doHammerSmash();
				}
				
			} else if ( key == Keyboard.NUMBER_5 ) {
				
				if ( this.gameData.progress.hasHammerang() ) {
					this.doHammerang();
				}
				
			} else if ( key == Keyboard.NUMBER_6 ) {
				
				if ( this.gameData.progress.hasSuperJump() ) {
					this.doHammerJump();
				}
				
			} else if ( AppConfig.debug ) {
				
				if ( key == Keyboard.G ) {
					
					this.landGroup.getPoptanium( 50 );
					
				} else if ( key == Keyboard.H ) {
					
					this.landGroup.getExperience( 50 );
					
				} else if ( key == Keyboard.V ) {
					this.landGroup.saveDataToDisk();
				} else if ( key == Keyboard.L ) {
					this.landGroup.loadWorldFromDisk();
				} else if ( key == Keyboard.C ) {
					// advance the clock.
					this.gameData.clock.advanceTime();
				} //
				
			} // end key-if.
			
		} //
		
		public function doHammerJump():void {
			
			var player:Entity = this.landGroup.getPlayer();
			
			if ( (this.uiMode & (LandEditMode.MINING | LandEditMode.PLAY) ) == 0 ) {
				return;
			}
			
			var movement:CharacterMovement = player.get( CharacterMovement ) as CharacterMovement;
			if ( movement == null || movement.state == CharacterMovement.AIR ||
				movement.state == CharacterMovement.CLIMB || movement.state == CharacterMovement.DIVE ) {
				return;
			}
			
			CharUtils.setAnim( player, SuperJump, false );
			
			// i left the notes below to explain the difficulties with the different methods of char control:
			
			// PROBLEM: setting motion control overrides the velocity so it doesn't work.
			//var control:FSMControl = player.get( FSMControl );
			//control.setState( "jump" );
			
			// PROBLEM: overriding jump velocity makes it permanent.
			//var charControl:CharacterMotionControl = player.get( CharacterMotionControl );
			//charControl.jumpVelocity = -1200;
			// PROBLEM: setting the animation breaks the hits.
			//CharUtils.setAnim( player, Jump );
			
		} //
		
		/**
		 * throw the hammer in the direction the player is facing.
		 */
		public function doHammerang():void {
			
			if ( this.uiMode != LandEditMode.MINING ) {
				return;
			}
			
			var player:Entity = this.landGroup.getPlayer();
			
			var movement:CharacterMovement = player.get( CharacterMovement ) as CharacterMovement;
			if ( movement == null || movement.state == CharacterMovement.AIR ||
				movement.state == CharacterMovement.CLIMB || movement.state == CharacterMovement.DIVE ) {
				return;
			}
			
			var item:Entity = (player.get( Skin ) as Skin ).getSkinPartEntity( "item" );
			if ( item == null ) {
				return;
			}
			// need to convert from hammer coordinates to screen coordinates.
			var itemSpatial:Spatial = item.get( Spatial ) as Spatial;
			if ( itemSpatial == null ) {
				return;
			}
			
			var display:Display = item.get( Display );
			if ( display == null || display.visible == false ) {
				return;
			}
			
			MotionUtils.zeroMotion( player );
			
			CharUtils.setAnim( player, Salute );
			this.shellApi.loadFile( this.landGroup.sharedAssetURL + "hammer.swf", this.hammerLoaded );
			
		} //
		
		/**
		 * hammer loaded for throwing.
		 */
		private function hammerLoaded( clip:MovieClip ):void {
			
			var player:Entity = this.landGroup.getPlayer();
			
			this.landGroup.curScene.hitContainer.addChild( clip );
			
			var item:Entity = ( player.get( Skin ) as Skin ).getSkinPartEntity( "item" );
			if ( item == null ) {
				return;
			}
			var itemDisplay:Display = item.get( Display );
			if ( itemDisplay == null ) {
				return;
			}
			if ( itemDisplay.visible == false ) {
				return;
			}
			itemDisplay.visible = false;
			
			super.shellApi.track( "Hammerang", null, null, LandGroup.CAMPAIGN );
			
			// these numbers come from the offset to the hammer top. no good way to set them right now.
			var p:Point = new Point( 0, 0 );
			p = ( itemDisplay.displayObject as DisplayObjectContainer ).localToGlobal( p );
			p = this.curScene.hitContainer.globalToLocal( p );
			
			var playerSpatial:Spatial = player.get( Spatial );
			var hammerMotion:Motion = new Motion();
			// player scale is actually backwards from what you'd expect
			if ( playerSpatial.scaleX < 0 ) {
				hammerMotion.rotationVelocity = 500;
				hammerMotion.velocity.x = 800;
			} else {
				hammerMotion.rotationVelocity = -500;
				hammerMotion.velocity.x = -800;
			}
			
			var hammer:Entity = new Entity()
				.add( hammerMotion, Motion )
				.add( new Spatial( p.x, p.y ), Spatial )
				.add( new TargetSpatial( playerSpatial ), TargetSpatial )
				.add( new ThrowHammer( this.onHammerReturn ), ThrowHammer )
				.add( new Display( clip ), Display )
				.add( new Disintegrate(), Disintegrate );
			
			if ( !this.getSystem( DisintegrateSystem ) ) {
				this.landGroup.addSystem( new DisintegrateSystem(), SystemPriorities.update );
			} //
			if ( !this.getSystem( ThrowHammerSystem ) ) {
				this.landGroup.addSystem( new ThrowHammerSystem(), SystemPriorities.moveComplete );
			}
			
			this.landGroup.addEntity( hammer );
			
			AudioUtils.play( this.landGroup, SoundManager.EFFECTS_PATH + "whoosh_05.mp3", 1 , false, SoundModifier.EFFECTS );
			
		} //
		
		private function onHammerReturn( hammer:Entity ):void {
			
			var item:Entity = ( this.landGroup.getPlayer().get( Skin ) as Skin ).getSkinPartEntity( "item" );
			if ( item == null ) {
				return;
			}
			var itemDisplay:Display = item.get( Display );
			if ( itemDisplay == null ) {
				return;
			}
			
			itemDisplay.visible = true;
			
			this.landGroup.removeEntity( hammer, true );
			
		} //
		
		/**
		 * need to move this into it's own class or something, eventually.
		 */
		public function doHammerSmash():void {
			
			if ( this.uiMode != LandEditMode.MINING ) {
				return;
			}
			
			var player:Entity = this.landGroup.getPlayer();
			
			var movement:CharacterMovement = player.get( CharacterMovement ) as CharacterMovement;
			if ( movement == null || movement.state == CharacterMovement.AIR ||
				movement.state == CharacterMovement.CLIMB || movement.state == CharacterMovement.DIVE ) {
				return;
			}
			
			super.shellApi.track( "GroundPound", null, null, LandGroup.CAMPAIGN );
			
			CharUtils.setAnim( player, SledgeHammer);
			
			var tl:Timeline = CharUtils.getTimeline( player );
			tl.handleLabel( "trigger", this.doHammerImpact );
			
			MotionUtils.zeroMotion( player );
			
		} //
		
		private function doHammerImpact():void {
			
			var player:Entity = this.landGroup.getPlayer();
			var item:Entity = (player.get( Skin ) as Skin ).getSkinPartEntity( "item" );
			if ( item == null ) {
				return;
			}
			
			// need to convert from hammer coordinates to screen coordinates.
			var itemSpatial:Spatial = item.get( Spatial ) as Spatial;
			if ( itemSpatial == null ) {
				return;
			}
			
			var display:Display = item.get( Display );
			if ( display == null || display.visible == false ) {
				return;
			}
			
			// these numbers come from the offset to the hammer top. no good way to set them right now.
			var p:Point = new Point( -55, 28 );
			p = ( display.displayObject as DisplayObjectContainer ).localToGlobal( p );
			p = this.curScene.hitContainer.globalToLocal( p );
			
			/*
			// this test shows the actual hammer impact occurs somewhere around the player's head
			and that an extra y-offset must be added to the final hit.
			var s:Shape = new Shape();
			s.graphics.beginFill( 0xEE0000 );
			s.graphics.drawCircle( p.x, p.y, 32 );
			this.landGroup.mainScene.hitContainer.addChild( s );*/
			
			var blastSys:BlastTileSystem = this.getSystem( BlastTileSystem ) as BlastTileSystem;
			blastSys.blastSemiCircle( this.gameData.getFGLayer(), p.x, p.y+64, 128 );
			
			AudioUtils.play( this.landGroup, SoundManager.EFFECTS_PATH + "smash_02.mp3", 1 , false, SoundModifier.EFFECTS );
			
		} //
		
		/**
		 * reset mainly occurs when biome changes.
		 */
		public function reset():void {
			
			// the land mode is changed to play because mining/tile/edit systems rely on tile information that
			// is about to get completely wiped. the systems are disabled too but this is safer.
			this.uiMode = LandEditMode.PLAY;
			
			this.landMenu.reset();
			
			// these need to be cleared to remove dangling references to objects that no longer exist.
			this.editContext.curTileType = null;
			this.focus.tile = null;
			this.focus.type = null;
			
		} //
		
		public function hideHintArrow():void {
			
			this.hintArrow.visible = false;
			this.hideHelpfulHint();
			
		} //
		
		/**
		 * turns a display object into a button with a MouseEvent.CLICK event handler.
		 */
		public function makeButton( btn:DisplayObjectContainer, func:Function, rollOver:int=0, rollOverText:String=null ):void {
			
			this.inputManager.addEventListener( btn, MouseEvent.CLICK, func );
			var tipTarget:SharedTipTarget = this.sharedTip.addClipTip( btn, ToolTipType.CLICK, rollOverText );
			
			if ( btn is MovieClip ) {
				
				btn.mouseChildren = false;
				var mc:MovieClip = btn as MovieClip;
				mc.gotoAndStop( 1 );
				if ( mc.hilite ) {
					mc.hilite.mouseEnabled = false;
					mc.hilite.visible = false;
				}
				
			}
			if ( rollOver != 0 ) {
				tipTarget.rollOverFrame = rollOver;
			}
			
		} //
		
		/**
		 * initialize a lock bitmap, and a loading bitmap (that can be spun to indicate loading)
		 * or make this a more general initBitmap( clipName:String ):BitmapData?
		 */
		private function initUIBitmaps():void {
			
			var clip:MovieClip = this.uiClip.lockIcon;
			
			var bm:BitmapData = new BitmapData( clip.width, clip.height, true, 0 );
			bm.draw( clip );
			
			this._lockBitmap = bm;
			
			// remove the lock clip, don't need it any more.
			this.uiClip.removeChild( clip );
			
			clip = this.uiClip.loadIcon;
			bm = new BitmapData( clip.width, clip.height, true, 0 );
			bm.draw( clip, null, null, null, null, true );
			this._loadingBitmap = bm;
			
			this.uiClip.removeChild( clip );
			
		} //
		
		/**
		 * resume after a reset() has cleared out all the data from the previous session.
		 */
		public function resume():void {
			
			this.landMenu.getMaterialPane().resetTileButtons();
			
		} //
		
		public function hideUI():void {
			this.statusPane.hide();
			this.uiClip.visible = false;
		} //
		
		public function showUI():void {
			this.statusPane.show();
			this.uiClip.visible = true;
		} //
		
		public function getQuickBar():QuickBar {
			return this.landMenu.getQuickBar();
		}
		
		override public function destroy():void {
			
			this.templatePane.destroy();
			this.landMenu.destroy();
			
			this._inputManager.destroy();
			this.sharedTip.destroy();
			
			this.onUIModeChanged.removeAll();
			
			// it might be nice if this happened a bit more naturally.
			this.editContext.onEditModeChanged.removeAll();
			
			this.curScene.overlayContainer.removeChild( this.uiClip );
			
			super.destroy();
			
		} // destroy()
		
	} // class
	
} // package