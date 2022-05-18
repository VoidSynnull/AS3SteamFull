package game.scenes.lands.shared.popups.worldManagementPopup {

	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.systems.MotionSystem;
	import engine.util.Command;
	
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.data.ui.TransitionData;
	import game.proxy.PopDataStoreRequest;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.components.InputManager;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.popups.worldManagementPopup.components.BubbleRealm;
	import game.scenes.lands.shared.popups.worldManagementPopup.components.World;
	import game.scenes.lands.shared.popups.worldManagementPopup.nodes.BubbleRealmNode;
	import game.scenes.lands.shared.popups.worldManagementPopup.nodes.WorldNode;
	import game.scenes.lands.shared.popups.worldManagementPopup.systems.WorldManagementSystem;
	import game.scenes.lands.shared.popups.worldManagementPopup.ui.DropDownView;
	import game.scenes.lands.shared.popups.worldManagementPopup.ui.PopupMessagePane;
	import game.scenes.lands.shared.popups.worldManagementPopup.ui.PrivateRealmInfoPane;
	import game.scenes.lands.shared.popups.worldManagementPopup.ui.PublicRealmInfoPane;
	import game.scenes.lands.shared.popups.worldManagementPopup.ui.RealmCodePane;
	import game.scenes.lands.shared.popups.worldManagementPopup.ui.RealmInfoPane;
	import game.scenes.lands.shared.util.LandUtils;
	import game.scenes.lands.shared.util.NameGeneratorUtil;
	import game.scenes.lands.shared.world.LandGalaxy;
	import game.scenes.lands.shared.world.LandRealmData;
	import game.scenes.lands.shared.world.LandWorldManager;
	import game.scenes.lands.shared.world.PublicWorldSource;
	import game.scenes.lands.shared.world.RemoteWorldSource;
	import game.scenes.lands.shared.world.WorldDataSource;
	import game.systems.SystemPriorities;
	import game.systems.motion.PositionSmoothingSystem;
	import game.ui.hud.HudPopBrowser;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.SceneUtil;
	import game.util.Utils;
	
	public class WorldManagementPopup extends Popup {

		public const MAX_WORLDS:int = 20;

		private const MEMBER_EXCLUSIVE_BIOME:String = "ExclusiveBiome";
		private const MEMBER_SHARE_BLOCK:String = "ClickedShare";
		private const MEMBER_REALM_LIMIT:String = "HitRealmLimit";

		private const FLAG_CONFIRM_TITLE:String = "Flag Realm";
		private const FLAG_CONFIRM_MSG:String = "Flag this realm as inappropriate?";

		private const SHARE_CONFIRM_TITLE:String = "Share this realm?";
		private const SHARE_CONFIRM_MSG:String = "Other players will be able to explore and play in your shared realms! (Don't worry, they won't be able to change anything.) We may also share your creation with the world through our social media sites!";

		private const DELETE_REALM_MSG:String = "Are you sure you want to permanently remove this realm and all of its content?";
		private const DELETE_REALM_TITLE:String = "delete this realm?";

		private const BTN_CLICK_SND:String = "ui_roll_over.mp3";
		private const SELECT_REALM_SND:String = "ping_18.mp3";
		private const CREATE_REALM_SND:String = "event_05.mp3";
		private const DELETE_REALM_SND:String = "warp_zap.mp3";

		/**
		 * displays information about the selected realm.
		 */
		public var curInfoPane:RealmInfoPane;
		private var publicInfoPane:PublicRealmInfoPane;
		private var privateInfoPane:PrivateRealmInfoPane;

		private var messagePane:PopupMessagePane;
		
		public var bgClip:MovieClip;

		private var landGroup:LandGroup;
		private var bubblesContainer:MovieClip;
		private var worldsContainer:MovieClip;
		//private var uiScreen:MovieClip;

		private var newWorldPane:MovieClip;
		private var membershipPane:MovieClip;
		
		private var newWorldPaneY:Number;
		private var membershipPaneY:Number;
		//private var sharePaneY:Number;
		//private var deleteConfirmY:Number;		

		/**
		 * this is to get more public realms to view. only visible in public mode.
		 * need to change the name, really.
		 */
		private var btnSeeMore:MovieClip;

		private var realmCodePane:RealmCodePane;

		/**
		 * list for selecting a realm mode.
		 */
		private var realmViewList:DropDownView;

		private var mp_btnMembership:MovieClip;

		private var nw_btnConfirm:MovieClip;

		private var doMembershipRecheck:Boolean = false;

		private var landColors:Array = [0xFF8AAB50, 0xFF97C8D2, 0xFFDEB06B, 0xFFE15011, 0xFFAC82D2, 0xFF846937, 0xFFC7CEC1];
		private var waterColors:Array = [0xFF2F6580, 0xFF7BB9C6, 0xFFD67D43, 0xFF4D2215, 0xFF7558C0, 0xFF65492E, 0xFF9EA899];

		/**
		 * !!! TO-DO: organiaze biome names, biome display names, in some type of central location.
		 */
		private var biomeDisplayNames:Array = ["Forest", "Ice", "Desert", "Swamp", "Lunar", "Fire", "Crystal"];
		private var biomeNames:Array = [ "grass", "snow", "sand", "swamp", "lunar", "fire", "crystal" ];

		private var sizeNames:Array = ["small", "medium", "large"];
		private var selectedBiome:uint = 0;
		private var selectedSizeIndex:uint = 0;
		//private var landBlur:BlurFilter = new BlurFilter(4, 4, 3);
		
		public var selectedWorld:Entity;
		public var zoomSelectedWorld:Boolean = false;
		public var worldInfoOnY:uint;
		public var worldInfoOffY:uint;
		public var worldInfoTargetY:uint;

		/**
		 * they want to track the reason for a block when getMembership() is clicked,
		 * but this information can't be sent with the mouse event - because the reason
		 * doesn't exist yet. need to save the last membership blocked reason when
		 * the membership block is displayed to the user.
		 */
		private var lastBlockReason:String;

		/**
		 * it's possible for the WorldLoadSource to change while the swf for a realm is still loading.
		 * in this case, the realm swf will load and create a realm entity after the incorrect source type.
		 * for example, a public realm will be created when in private realm mode.
		 * To fix this, a batch number is assigned to loading realms and rechecked against the current batch
		 * before the entity is actually created. 
		 */
		//private var _worldLoadBatch:int;

		private var inputLocks:int = 0;

		/***
		 * used to add/remove worlds.
		 */
		private var worldMgr:LandWorldManager;

		public function WorldManagementPopup( container:DisplayObjectContainer=null ) {
			super(container);
		}

		override public function init( container:DisplayObjectContainer=null ):void {

			super.transitionIn = new TransitionData();
			super.transitionIn.duration = 1;
			super.transitionIn.startAlpha = 0;
			super.transitionIn.endAlpha = 1;

			super.transitionOut = new TransitionData();
			super.transitionOut.duration = 1;
			super.transitionOut.startAlpha = 1;
			super.transitionOut.endAlpha = 0;
			this.groupPrefix = "scenes/lands/shared/popups/";
			super.init(container);

			if ( !this.getSystem( MotionSystem ) ) {
				this.addSystem( new MotionSystem(), SystemPriorities.move );
			}
			if( !this.getSystem( PositionSmoothingSystem) ) {
				this.addSystem( new PositionSmoothingSystem(), SystemPriorities.preRender );
			}

			this.loadFiles( ["worldManagementPopup.swf"], false, true, this.loaded );

		} //

		override public function loaded():void {

			this.screen = super.getAsset( "worldManagementPopup.swf", true ) as MovieClip;
			this.screen.x *= this.shellApi.viewportWidth / 960;
			this.screen.y *= this.shellApi.viewportHeight / 640;

			var uiScreen:MovieClip = this.screen["ui"];

			this.worldsContainer = this.screen.worlds;
			this.bgClip = this.screen["bg"];
			this.bgClip.gotoAndStop( 1 );

			this.newWorldPane = uiScreen["newWorldPane"];
			this.membershipPane = uiScreen["membershipPane"];
			this.membershipPane.gotoAndStop( 1 );

			// These panes should no longer exist.
			var pane:MovieClip = uiScreen["sharePane"];
			if ( pane ) { uiScreen.removeChild( pane ); }
			pane = uiScreen["deleteConfirmation"];
			if ( pane ) { uiScreen.removeChild( pane ); }

			this.newWorldPane.visible = false;
			this.membershipPane.visible = false;

			//this.loadCloseButton();
			super.loaded();

			this.landGroup = this.parent as LandGroup;
			this.worldMgr = this.landGroup.worldMgr;

			var uiGroup:LandUIGroup = this.landGroup.getUIGroup();
			uiGroup.inputManager.addEventListener( this.bgClip, MouseEvent.CLICK, this.clickBG );
			uiGroup.sharedTip.addClipTip( this.bgClip, ToolTipType.ARROW );
			convertContainer( this.bgClip );

			super.addSystem( new WorldManagementSystem() );

			this.btnSeeMore = uiScreen.btnSeeMore;
			LandUtils.makeTipButton( this.btnSeeMore, this.landGroup.getUIGroup(), this.onViewMoreClicked );

			this.refreshWorlds( true );

			this.initPanes( uiScreen );

			this.initUI();

			this.setRealmViewMode();

		} //

		private function initUI():void {

			var btn:MovieClip;
			var uiGroup:LandUIGroup = this.landGroup.getUIGroup();

			this.nw_btnConfirm = this.newWorldPane["btnConfirm"];
			this.mp_btnMembership = this.membershipPane["btnMembership"];

			this.newWorldPaneY = newWorldPane.y;
			this.membershipPaneY = membershipPane.y;
			//this.sharePaneY = sharePane.y;
			//this.deleteConfirmY = deleteConfirmPane.y;

			LandUtils.makeTipButton( this.nw_btnConfirm, uiGroup, this.confirmNewWorld );
			LandUtils.makeTipButton( this.mp_btnMembership, uiGroup, this.getMembership );

			// biome selection buttons.
			for ( var i:int = this.biomeNames.length-1; i >= 0; i-- ) {
				btn = this.newWorldPane["btnBiome" + i];
				btn.biomeIndex = i;
				LandUtils.makeTipButton( btn, uiGroup, this.onRealmBiomeClick );
			}

			// world size buttons.
			for ( i = this.sizeNames.length-1; i >= 0; i-- ) {
				btn = this.newWorldPane["btnSize" + i];
				btn.sizeIndex = i;
				LandUtils.makeTipButton( btn, uiGroup, this.onRealmSizeClick );
			}

			this.hideUIPanes();
		}

		private function initPanes( uiScreen:MovieClip ):void {

			var worldInfo:MovieClip = uiScreen["myWorldInfo"];
			var uiGroup:LandUIGroup = this.landGroup.getUIGroup();

			this.privateInfoPane = new PrivateRealmInfoPane( worldInfo, uiGroup );
			this.privateInfoPane.setPrivateClicks( this.clickVisitRealm, this.clickDeleteWorld, this.showShareConfirm );
			this.curInfoPane = this.privateInfoPane;

			this.publicInfoPane = new PublicRealmInfoPane( uiScreen["publicWorldInfo"], uiGroup );
			this.publicInfoPane.setPublicClicks( this.clickVisitRealm, this.clickLikeRealm, this.clickFlagRealm );

			this.worldInfoOnY = worldInfo.y;
			worldInfo.y = this.worldInfoTargetY = this.worldInfoOffY = ( this.worldInfoOnY + 300 );

			this.messagePane = new PopupMessagePane( uiScreen["generalConfirmation"], uiGroup );

			// this is the button that switches between public/private worlds.
			this.realmViewList = new DropDownView( uiScreen["dropDownView"], uiGroup );
			this.realmViewList.onItemClicked = this.onRealmViewClicked;
			this.realmViewList.show();
			this.realmViewList.setItemNames( ["MY REALMS", "PUBLIC REALMS"] );

			this.realmCodePane = new RealmCodePane( uiScreen["realmCodePane"], uiGroup );
			this.realmCodePane.addRealmCodeClick( this.onRealmCodeClicked );

		} //

		/**
		 * refresh all the bubbles/realms after the realms loaded in the current galaxy have changed.
		 */
		/**
		 * NOTES WHILE IN TESTING:
		 * 
		 * MAKE so the world entities can be reused.
		 */
		private function refreshWorlds( selectCur:Boolean=false ):void {

			var galaxy:LandGalaxy = this.worldMgr.galaxy;

			// TO-DO: possibly some error checking here, complain if no galaxy data.

			var realms:Vector.<LandRealmData> = galaxy.getRealms();
			var realm:LandRealmData;

			// number of free bubbles is total available minus those taken by existing realms.
			var numBubbles:int = this.MAX_WORLDS - realms.length;

			if ( this.worldMgr.publicMode ) {
				// no create bubbles in public-mode.
				numBubbles = 0;
			} //
			
			//Drew - This was a +=
			//Needs to load a bubble plus the realm data for each realm bubble on-screen.
			this.inputLocks = ( numBubbles + realms.length );
			if ( this.inputLocks > 0 ) {
				this.lockInput();
			}
			else
			{
				this.unlockInput();
			}

			//create free bubbles
			this.bubblesContainer = this.screen.bubbles;
			for( var i:int = numBubbles; i > 0; i-- ){
				this.createBubbleEntity();
			}

			var curRealm:LandRealmData = null;
			if ( selectCur ) {
				curRealm  = this.worldMgr.curRealm;
			}

			//create worlds
			for ( i = realms.length-1; i >= 0; i-- ) {

				realm = realms[i];

				//this.shellApi.logWWW( "realm loaded: " + realm.id );

				// load each planet in the current 'galaxy'
				super.loadFile( "world.swf", this.createExistingRealm, realm, (realm == curRealm) );

			} //

		} //

		/**
		 * called when a single public realm is loaded by its id.
		 */
		private function onRealmLoaded( realmData:LandRealmData ):void {

			if ( realmData == null ) {

				// display error message?
				this.messagePane.showMessage( "Realms Error", "Could not load realm." );
				this.tryUnlockInput();

			} else {

				// true here selects the current realm.
				super.loadFile( "world.swf", this.createExistingRealm, realmData, true );

			} //

		} //

		private function destroyAllWorlds():void {

			var bubbleList:NodeList = this.systemManager.getNodeList( BubbleRealmNode );
			var worldList:NodeList = this.systemManager.getNodeList( WorldNode );

			this.shellApi.logWWW( "DELETING EXISTING WORLDS" );

			var e:Entity;

			// DESTROY ALL EXISTING Worlds/ENTITIES.
			// TO-DO: RE-USE THE EXISTING ENTITIES.
			for( var bubbleNode:BubbleRealmNode = bubbleList.head; bubbleNode; ) {

				// have to advance before the node gets deleted.
				e = bubbleNode.entity;
				bubbleNode = bubbleNode.next;
	
				this.removeBubbleEntity( e );

			} //
			for( var worldNode:WorldNode = worldList.head; worldNode; ) {

				e = worldNode.entity;
				worldNode = worldNode.next;

				this.removeWorldEntity( e );

			} //

			if ( this.selectedWorld != null ) {
				this.unselectWorld();
			}

		} //

		/**
		 * TEMP function until I decide on a way to integrate all the biome info in a central location.
		 * Probably a BiomeInfo class + biome list that i store somewhere.
		 */
		public function getBiomeIndex( planet:LandRealmData ):int {

			var name:String = planet.biome;

			for( var i:int = this.biomeNames.length-1; i >= 0; i-- ) {

				if ( name == this.biomeNames[i] ) {
					return i;
				}

			} //

			// whatever.
			return 0;

		} //

		public function getWorldSizeIndex( worldSize:int ):int {

			if ( worldSize >= 41 ) {
				return 2;
			} else if ( worldSize >= 21 ) {
				return 1;
			}

			return 0;

		} //

		/**
		 *
		 * exactly like createRealm, only used for realms which come from the server - not newly created.
		 * since these realms come from the server, they could already have an associated screenshot.
		 *
		 */
		private function createExistingRealm( clip:MovieClip, realmData:LandRealmData, selectNewWorld:Boolean=false ):void {

			// taking the world-clip child simplifies the event code.
			var realmClip:MovieClip = clip.world;

			this.createRealmEntity( realmClip, realmData, selectNewWorld );

			if ( realmData.thumbURL != null && realmData.thumbURL != "" ) {

				//this.shellApi.logWWW( "attempting load thumb: " + realmData.thumbURL );

				// !!!!!!!!
				// All this is annoying stuff to get the thumbnail to load because it doesn't seem possible to get it through
				// the shell API loading commands - I THINK because you need to set LoaderContext.checkPolicyFile = true
				var loader:Loader = new Loader();
				var context:LoaderContext = new LoaderContext( true );
				var input:InputManager = this.landGroup.getUIGroup().inputManager;
				input.addEventListener( loader.contentLoaderInfo, Event.COMPLETE, Command.create( this.onRealmThumbLoaded, realmData, realmClip ) );

				input.addEventListener( loader.contentLoaderInfo, IOErrorEvent.IO_ERROR, this.onThumbIOError );
				input.addEventListener( loader.contentLoaderInfo, SecurityErrorEvent.SECURITY_ERROR, this.onThumbSecurityError );

				loader.load( new URLRequest( realmData.thumbURL ), context );

			} //

			this.tryUnlockInput();

		} //

		private function createBubbleEntity():void {

			super.loadFile( "bubble.swf", this.bubbleLoaded );

		}
		
		private function bubbleLoaded( clip:MovieClip ):void {

			var bubbleClip:MovieClip = clip.bubble;

			this.bubblesContainer.addChild( bubbleClip );
			bubbleClip.cacheAsBitmap = true;

			var spatial:Spatial = new Spatial();

			var bubbleEntity:Entity = new Entity()
				.add( spatial, Spatial )
				.add( new Motion(), Motion )
				.add( new Display( bubbleClip, this.bubblesContainer ), Display );
			this.addEntity( bubbleEntity );

			spatial.scale = Math.random()*0.4 + 0.6;
			spatial.x = Math.random()*this.shellApi.viewportWidth;
			spatial.y = Math.random()*this.shellApi.viewportHeight;
			
			var vx:Number = Math.random()*2 - 1;
			var vy:Number = Math.random()*2 - 1;
			
			bubbleEntity.add( new BubbleRealm(vx, vy) );

			bubbleClip.loadIcon.visible = false;
			this.addBubbleEvents( bubbleClip, bubbleEntity );

			this.tryUnlockInput();

		} //

		/**
		 * selectNewWorld=true makes the world the actively selected world.
		 */
		private function createRealmEntity( realmClip:MovieClip, realmData:LandRealmData, selectNewRealm:Boolean=false):void {

			this.worldsContainer.addChild( realmClip );

			var spatial:Spatial = new Spatial();
			var worldEntity:Entity = new Entity()
				.add( new Motion(), Motion )
				.add( spatial, Spatial )
				.add( new Display( realmClip ), Display );
			this.addEntity( worldEntity );

			//if bubble was selected, place new world where bubble is
			if ( this.selectedWorld && this.selectedWorld.get(BubbleRealm) ){

				spatial.x = this.selectedWorld.get( Spatial ).x;
				spatial.y = this.selectedWorld.get( Spatial ).y;

				this.removeBubbleEntity( this.selectedWorld );
				this.selectedWorld = null;

			} else if ( selectNewRealm ) { //if select new world is true, place in center of screen

				spatial.x = this.shellApi.viewportWidth/2;
				spatial.y = this.shellApi.viewportHeight/2;

			} else { //place in random position in screen

				spatial.x = Math.random()*this.shellApi.viewportWidth;
				spatial.y = Math.random()*this.shellApi.viewportHeight;

			}

			var world:World = new World( realmData );
			worldEntity.add( world );

			var ratio:Number = Utils.convertRatio( realmData.realmSize, 5, 60, 50, 100 );
			if ( ratio > 100 ) {
				ratio = 100;
			} else if ( ratio < 50 ) {
				ratio = 50;
			}

			world.targetScale = ratio/100;
			var art:MovieClip = realmClip["art"];
			var twirl:MovieClip = realmClip["twirl"];
			var screenshot:MovieClip = art["screenshot"];
			art.cacheAsBitmap = true;

			screenshot.gotoAndStop(this.getBiomeIndex( realmData ) + 1);
			screenshot.alpha = 0.7;

			art.scaleX = art.scaleY = 0;
			twirl.scaleX = twirl.scaleY = 0;
			
			art["glow"].alpha = 0.2;

			world.vx = Math.random()*2 - 1;
			world.vy = Math.random()*2 - 1;

			//convertContainer(art);

			this.addWorldEvents( realmClip, worldEntity );

			if ( selectNewRealm ) {
				this.selectWorld( worldEntity );
				this.hideUIPanes();
			}

		} //

		/**
		 * giving the entity and worldClip ensures a reference to the entity gets placed in worldClip
		 */
		private function addWorldEvents( worldClip:MovieClip, entity:Entity ):void {

			worldClip.entity = entity;

			var uiGroup:LandUIGroup = this.landGroup.getUIGroup();
			uiGroup.makeButton( worldClip, this.clickWorld );

			// handle rollOver.
			uiGroup.inputManager.addEventListener( worldClip, MouseEvent.ROLL_OVER, this.rollOverWorld );

		} //

		/**
		 * giving the entity and worldClip ensures a reference to the entity gets placed in bubbleClip
		 */
		private function addBubbleEvents( bubbleClip:MovieClip, entity:Entity ):void {

			//( entity.get( Display ) as Display ).interactive = true;

			bubbleClip.entity = entity;

			var uiGroup:LandUIGroup = this.landGroup.getUIGroup();
			uiGroup.makeButton( bubbleClip, this.clickBubble );

		} //
		
		private function rollOverWorld( e:MouseEvent ):void {

			DisplayUtils.moveToTop( e.currentTarget as DisplayObject );

		}
		
		/*private function rollOutWorld(entity:Entity):void {
		}*/

		private function clickBubble( e:MouseEvent ):void {

			AudioUtils.play( this.landGroup, SoundManager.EFFECTS_PATH + this.SELECT_REALM_SND, 1 , false, SoundModifier.EFFECTS ); 
			this.showNewWorldPane( e.currentTarget.entity );

		} //

		private function clickWorld( e:MouseEvent ):void {

			this.selectWorld( e.currentTarget.entity );
			AudioUtils.play( landGroup, SoundManager.EFFECTS_PATH + this.SELECT_REALM_SND, 1, false, SoundModifier.EFFECTS );

		} //

		private function clickBG( e:MouseEvent ):void {

			this.playClickSound();
			this.unselectWorld();

			this.hideUIPanes();

		} //

		private function onRealmBiomeClick( e:MouseEvent ):void {

			var biomeIndex:int = ( e.target as MovieClip ).biomeIndex;

			// if member only
			if( biomeIndex == 5 || biomeIndex == 6 ){

				if( super.shellApi.profileManager.active.isMember ) {
					this.selectBiome( biomeIndex );
				} else {
					this.showMembershipPane( 3, this.MEMBER_EXCLUSIVE_BIOME );
				}

			} else {
				this.selectBiome( biomeIndex );
			}
			playClickSound();
		}
		
		private function onRealmSizeClick( e:MouseEvent ):void {
			this.selectSizeIndex( (e.target as MovieClip ).sizeIndex );
			this.playClickSound();
		}
		
		private function playClickSound():void {
			AudioUtils.play( landGroup, SoundManager.EFFECTS_PATH + this.BTN_CLICK_SND, 1, false, SoundModifier.EFFECTS );
		}

		private function confirmNewWorld( e:MouseEvent ):void {

			if ( this.worldMgr.publicMode ) {
				// can't create new realms in public mode.
				return;
			}

			// TO-DO: make an interface through the WorldManager so you dont deal with source directly.
			var worldSource:WorldDataSource = this.worldMgr.worldSource;
			if ( worldSource == null ) {
				return;
			}

			var worldName:String = this.newWorldPane["fldName"].text;
			// TO-DO: trim whitespace and then check.
			if (worldName == null || worldName == "" ) {
				trace( "error: invalid world name" );
				return;
			} //
			
			if ( !super.shellApi.profileManager.active.isMember ) {	
				if (this.worldMgr.getRealms().length > 2 ){
					showMembershipPane( 2, this.MEMBER_REALM_LIMIT );
					return;
				}
			}

			var biomeName:String = this.biomeNames[ this.selectedBiome ];

			// set world scene limits
			var worldSize:int = 0;
			if ( this.selectedSizeIndex >= 2 ) {
				worldSize = Utils.randInRange(41, 60);
			} else if ( this.selectedSizeIndex >= 1 ) {
				worldSize = Utils.randInRange(21, 40);
			} else {
				worldSize = Utils.randInRange(5, 20);
			}

			// pause input so the realm source isn't changed while the world is loading.
			this.lockInput();
			worldSource.createNewRealm( this.worldMgr.galaxy,
				biomeName, Math.round( Math.random()*uint.MAX_VALUE ), worldSize, worldName, this.onWorldCreated );

			this.shellApi.track("RealmsPopup", "CreatedRealm", biomeName, LandGroup.CAMPAIGN );
			
			AudioUtils.play( landGroup, SoundManager.EFFECTS_PATH + CREATE_REALM_SND, 1, false, SoundModifier.EFFECTS );
			this.hideUIPanes();
			
			//show loading arrow on current bubble
			if( this.selectedWorld && this.selectedWorld.get(BubbleRealm) ){ //if bubble was selected, show its loading arrow

				MovieClip( DisplayObject( this.selectedWorld.get(Display).displayObject )["loadIcon"] ).visible = true;

			}

		} //

		/**
		 * world was created and confirmed in the database.
		 */
		private function onWorldCreated( realmData:LandRealmData, errorCode:int ):void {

			if ( realmData != null ) {

				super.loadFile( "world.swf", this.createExistingRealm, realmData, true );

			} else {

				this.messagePane.showMessage( "Realms Error", "Oops. Your realm could not be created." );
				this.unlockInput();

			} //

		}//

		/**
		 * error when a thumbnail doesn't load because of an IO error.
		 */
		private function onThumbIOError( e:IOErrorEvent ):void {

			var input:InputManager = this.landGroup.getUIGroup().inputManager;
			input.removeListeners( e.target as LoaderInfo );

			this.shellApi.logWWW( "thumb error: " + e.toString() );

		} //

		/**
		 * error when a thumbnail doesn't load because of a security error.
		 * this should not occur. 
		 */
		private function onThumbSecurityError( e:SecurityErrorEvent ):void {

			var input:InputManager = this.landGroup.getUIGroup().inputManager;
			input.removeListeners( e.target as LoaderInfo );

			this.shellApi.logWWW( "thumb error: " + e.toString() );

		} //

		private function onRealmThumbLoaded( e:Event, realmData:LandRealmData, realmClip:MovieClip ):void {

			var loaderInfo:LoaderInfo = e.target as LoaderInfo;
			if ( loaderInfo == null )  {
				this.shellApi.logWWW( "error: no loaderInfo" );
				return;
			}
			var bitmap:Bitmap = loaderInfo.content as Bitmap;

			var input:InputManager = this.landGroup.getUIGroup().inputManager;
			input.removeListeners( loaderInfo );

			try {

				if ( bitmap == null || bitmap.bitmapData == null ) {
					this.shellApi.logWWW( "invalid thumbnail for realm" );
					return;
				} //

				//this.shellApi.logWWW( "THUMNAIL LOADED FOR REALM: " + realmData.name );

				var screenshot:MovieClip = realmClip["art"]["screenshot"];

				screenshot.removeChildren();
			//	var bitmap:Bitmap = new Bitmap( bitmapData );
				screenshot.addChild( bitmap );

			} catch ( e:SecurityError ) {

				this.shellApi.logWWW( e.message );

			} //

		} //

		private function getMembership( e:MouseEvent ):void {

			this.shellApi.track("RealmsPopup", "ClickedGetMembership", this.lastBlockReason, LandGroup.CAMPAIGN );

			this.playClickSound();
			//super.shellApi.track("IntroPopup", "Clicked Membership", campaignName);
			HudPopBrowser.buyMembership(super.shellApi, "source=POP_img_GetMembership _RealmsBlock-pop&medium=Display&campaign=Realms");
		}
		
		private function shareWorld():void {

			var allowEveryoneToShare:Boolean = false;
			if( allowEveryoneToShare || super.shellApi.profileManager.active.isMember ) {

				this.hideUIPanes();
				this.playClickSound();

				if ( this.selectedWorld != null ) {

					var worldComp:World = this.selectedWorld.get( World );
					if ( !worldComp ) {
						return;
					} else if ( this.worldMgr.loadSource != "remote" ) {

						this.shellApi.logWWW( "ERROR: NO REMOTE SOURCE" );
						return;

					}

					var source:RemoteWorldSource = this.worldMgr.worldSource as RemoteWorldSource;
					if ( source == null ) {
						this.shellApi.logWWW( "ERROR: NO REMOTE SOURCE" );
					}

					var realm:LandRealmData = worldComp.realmData;
					realm.shareStatus = LandRealmData.REALM_STATUS_SHARED;
					// clear any disapprove marker.
					realm.approveStatus = LandRealmData.REALM_STATUS_NONE;

					source.setShareStatus( realm );

					AudioUtils.play( this, SoundManager.EFFECTS_PATH + "selection_02.mp3", 1, false, SoundModifier.EFFECTS );

					this.curInfoPane.displayRealm( realm );

					this.shellApi.track("RealmsPopup", "SharedRealm", null, LandGroup.CAMPAIGN );

					// !! --- OLD SHARE FOR SCREENSHOT. JORDAN STILL WANTS THIS.
					if ( worldComp.realmData.id == this.worldMgr.curRealm.id ) {
						this.landGroup.shareWorld();
					}

				} //
				
			} else {

				this.worldInfoTargetY = this.worldInfoOffY;
				this.showMembershipPane( 1, MEMBER_SHARE_BLOCK );

			}
			
		} // shareWorld()

		/**
		 * selecting a realm mode from the realm view list.
		 */
		private function onRealmViewClicked( itemNum:int ):void {

			if ( this.worldMgr.loadSource != "remote" ) {
				this.shellApi.logWWW( "ERROR: NO REMOTE SOURCE" );
				// don't toggle for local-play.
				return;
			} //

			var selectPublic:Boolean = ( itemNum == 1 );
			if ( worldMgr.publicMode == selectPublic ) {
				// case where selected mode matches the existing mode --> ignore.
				return;
			}

			// PAUSE ALL INPUTS.
			this.lockInput();
			this.hideUIPanes();

			// destroy existing worlds. currently the world entities are not reused.
			this.destroyAllWorlds();

			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "teleport_01.mp3", 1, false, SoundModifier.EFFECTS );

			if ( selectPublic ) {

				this.worldMgr.usePublicSource( this.shellApi );
				( this.worldMgr.worldSource as PublicWorldSource ).loadPublicRealms( this.onGalaxyLoaded );
				this.shellApi.track("RealmsPopup", "ViewedPublicRealms", null, LandGroup.CAMPAIGN );

			} else {

				this.worldMgr.useRemoteSource( this.shellApi );
				( this.worldMgr.worldSource as RemoteWorldSource ).loadGalaxy( this.onGalaxyLoaded );
				this.shellApi.track("RealmsPopup", "ViewedMyRealms", null, LandGroup.CAMPAIGN );

			} //

			this.setRealmViewMode();

		} //

		/**
		 * all inputs need to be paused so nothing is selected while new realms are being loaded.
		 */
		private function lockInput():void {

			var mScreen:MovieClip = this.screen as MovieClip;
			mScreen.ui.mouseEnabled = false;
			mScreen.ui.mouseChildren = false;

			SceneUtil.lockInput( this, true );

		} //

		private function unlockInput():void {

			var mScreen:MovieClip = this.screen as MovieClip;
			mScreen.ui.mouseEnabled = true;
			mScreen.ui.mouseChildren = true;

			SceneUtil.lockInput( this, false );

			this.inputLocks = 0;

		} //

		private function tryUnlockInput():void {

			this.inputLocks--;
			if ( this.inputLocks <= 0 ) {
				var mScreen:MovieClip = this.screen as MovieClip;
				mScreen.ui.mouseEnabled = true;
				mScreen.ui.mouseChildren = true;
				this.inputLocks = 0;
				SceneUtil.lockInput( this, false );

			} //

		} //

		/**
		 * sets the view to match the realm mode - public mode for shared realms, private for user's own realms.
		 */
		private function setRealmViewMode():void {

			if ( this.worldMgr.publicMode ) {

				//this.shellApi.logWWW( "PUBLIC MODE" );

				if ( this.curInfoPane.visible ) {
					this.curInfoPane.hide();
				}
				this.curInfoPane = this.publicInfoPane;

				this.realmViewList.selectItem( 1 );

				this.bgClip.gotoAndStop( 2 );

				this.realmCodePane.show();

				this.btnSeeMore.visible = true;

			} else {

				//this.shellApi.logWWW( "PRIVATE MODE" );

				if ( this.curInfoPane.visible ) {
					this.curInfoPane.hide();
				}
				this.curInfoPane = this.privateInfoPane;

				this.realmViewList.selectItem( 0 );

				this.bgClip.gotoAndStop( 1 );

				this.realmCodePane.hide();

				this.btnSeeMore.visible = false;

			} //

		} //

		private function onGalaxyLoaded( err:String ):void {

			if ( err != null && err != "" ) {

				this.messagePane.showMessage( "Realms Error", "Oops. There was a problem loading realms. Please try again." );

				this.unlockInput();

			} else {

				this.shellApi.logWWW( "Refreshing worlds..." );
				this.refreshWorlds();

			}

		} //

		private function showNewWorldPane(entity:Entity):void {

			this.hideUIPanes();
			this.selectedWorld = entity;

			this.worldInfoTargetY = this.worldInfoOffY;

			this.selectBiome(0);
			this.selectSizeIndex(0);
			this.newWorldPane.y = this.newWorldPaneY;
			this.newWorldPane.visible = true;

			var fldName:TextField = this.newWorldPane["fldName"];
			fldName.maxChars = 25;
			fldName.text = NameGeneratorUtil.generatePlanetName();
			super.container.stage.focus = fldName;
			fldName.setSelection( 0, fldName.text.length );

		} //

		private function showMembershipPane( frame:int, reason:String="" ):void {

			this.shellApi.track("RealmsPopup", "MembershipBlock", reason, LandGroup.CAMPAIGN );

			this.hideUIPanes();

			this.lastBlockReason = reason;

			this.membershipPane.gotoAndStop( frame );
			this.membershipPane.visible = true;
			this.membershipPane.y = this.membershipPaneY;

			this.doMembershipRecheck = true;
		}

		private function clickDeleteWorld( e:MouseEvent ):void {

			this.hideUIPanes();

			//this.deleteConfirmPane.visible = true;
			//this.deleteConfirmPane.y = this.deleteConfirmY;

			this.messagePane.showConfirm( this.DELETE_REALM_TITLE, this.DELETE_REALM_MSG, this.confirmDeleteWorld );

			this.playClickSound();

		}
		
		private function confirmDeleteWorld():void {

			AudioUtils.play( this.landGroup, SoundManager.EFFECTS_PATH + this.DELETE_REALM_SND, 1, false, SoundModifier.EFFECTS ); 
			this.deleteWorld( this.selectedWorld );
			this.unselectWorld();

		} //
		
		private function showShareConfirm( e:MouseEvent ):void {

			this.hideUIPanes();
			//this.sharePane.visible = true;
			//this.sharePane.y = sharePaneY;
			this.playClickSound();

			this.messagePane.showConfirm( this.SHARE_CONFIRM_TITLE, this.SHARE_CONFIRM_MSG, this.shareWorld );

		} //

		private function clickFlagRealm( e:MouseEvent ):void {

			this.playClickSound();
			if ( this.selectedWorld == null ) {
				return;
			}

			this.messagePane.showConfirm( this.FLAG_CONFIRM_TITLE, this.FLAG_CONFIRM_MSG, this.confirmFlagRealm );

		} //

		private function confirmFlagRealm():void {

			var source:PublicWorldSource = this.worldMgr.worldSource as PublicWorldSource;
			if ( source == null ) {
				return;
			}
			var world:World = this.selectedWorld.get( World ) as World;
			source.flagRealm( world.realmData.id );

		} //

		private function clickLikeRealm( e:MouseEvent ):void {

			if ( this.selectedWorld == null ) {
				return;
			}

			this.playClickSound();

			var source:PublicWorldSource = this.worldMgr.worldSource as PublicWorldSource;
			if ( source == null ) {
				return;
			}
			var world:World = this.selectedWorld.get( World ) as World;

			if ( this.worldMgr.hasLikedRealm( world.realmData.id ) ) {
				// already liked this realm.
				return;
			}

			source.likeRealm( world.realmData.id, this.onRealmLiked );
			this.shellApi.track("RealmsPopup", "LikedRealm", null, LandGroup.CAMPAIGN );

		} //

		private function onRealmLiked( realm:LandRealmData, success:Boolean ):void {

			if ( !success ) {
				return;
			}

			if ( (this.selectedWorld.get(World) as World).realmData.id == realm.id ) {
				// redisplay the realm likes.
				this.curInfoPane.displayRealm( realm );
				this.worldMgr.markLikedRealm( realm );
			} //

		} //

		private function clickVisitRealm( e:MouseEvent ):void {

			this.playClickSound();

			this.hideUIPanes();
			this.worldInfoTargetY = this.worldInfoOffY;

			var world:World = this.selectedWorld.get( World ) as World;
			var worldData:LandRealmData = world.realmData;

			( this.parent as LandGroup ).changeCurRealm( worldData );

			this.zoomSelectedWorld = true;
			SceneUtil.addTimedEvent( this, new TimedEvent(2, 1, this.close, true) );

		} //

		private function onRealmCodeClicked( e:MouseEvent ):void {

			var code:uint = LandRealmData.GetRealmIdFromCode( this.realmCodePane.getCurrentCode() );
			if ( code == 0 ) {
				return;
			}

			this.shellApi.track("RealmsPopup", "EnteredRealmCode", null, LandGroup.CAMPAIGN );

			// search for world already existing on screen.
			var realm:LandRealmData = this.worldMgr.galaxy.getRealmById( code );
			if ( realm != null ) {

				// realm already exists. find it and select it on screen.
				// problem: no good way to find the ENTITY of this realm...
				var worldList:NodeList = this.systemManager.getNodeList( WorldNode );
				for( var node:WorldNode = worldList.head; node; node = node.next ) {

					if ( node.world.realmData == realm ) {
						this.selectWorld( node.entity );
						break;
					} //

				} //

				return;

			} //
			

			// now load the realm and see what happens.
			var worldSource:PublicWorldSource = this.worldMgr.worldSource as PublicWorldSource;
			if ( worldSource == null ) {
				return;
			}

			this.lockInput();
			worldSource.loadRealm( code, this.onRealmLoaded );

			this.playClickSound();

		} //

		private function onViewMoreClicked( e:MouseEvent ):void {

			this.playClickSound();
			if ( !this.worldMgr.publicMode || this.worldMgr.loadSource != "remote" ) {
				return;
			}

			this.lockInput();

			this.hideUIPanes();

			// destroy existing worlds. currently the world entities are not reused.
			this.destroyAllWorlds();

			this.shellApi.track("RealmsPopup", "ViewedMoreRealms", null, LandGroup.CAMPAIGN );

			// for now, there is no paging. loading is randomized.
			( this.worldMgr.worldSource as PublicWorldSource ).loadPublicRealms( this.onGalaxyLoaded );

		} //

		private function selectWorld( entity:Entity ):void {

			var world:World = entity.get( World ) as World;
			var realmData:LandRealmData = world.realmData;

			this.selectedWorld = entity;

			this.curInfoPane.displayRealm( realmData );
			this.worldInfoTargetY = this.worldInfoOnY;
			//world.rolledOver = false;

			this.hideUIPanes();

		} //
		
		private function unselectWorld():void {

			this.selectedWorld = null;
			this.worldInfoTargetY = worldInfoOffY;

		}

		private function selectBiome( num:uint ):void {

			this.selectedBiome = num;
			this.newWorldPane[ "biomeHighlight" ].x = this.newWorldPane[ "btnBiome" + num ].x;

		}

		private function selectSizeIndex( num:uint ):void {

			this.selectedSizeIndex = num;
			this.newWorldPane[ "sizeHighlight" ].x = this.newWorldPane[ "btnSize" + num ].x;

		} //

		// Need to look at this one to make sure it's all being removed
		private function deleteWorld( realmEntity:Entity ):void {

			var realm:LandRealmData = ( realmEntity.get( World ) as World ).realmData;

			this.shellApi.track("RealmsPopup", "DeletedRealm", realm.biome, LandGroup.CAMPAIGN );
			this.worldMgr.destroyRealm( realm, this.onPlanetDeleted );

			this.removeWorldEntity( realmEntity );

			this.createBubbleEntity();

		} //

		private function removeWorldEntity( entity:Entity ):void {

			this.shellApi.logWWW( "REMOVING WORLD" );

			var display:Display = entity.get(Display);
			var uiGroup:LandUIGroup = this.landGroup.getUIGroup();
			uiGroup.inputManager.removeListeners( display.displayObject );
			uiGroup.sharedTip.removeToolTip( display.displayObject as DisplayObjectContainer );

			this.removeEntity( entity );

		} //

		private function removeBubbleEntity( entity:Entity ):void {

			this.shellApi.logWWW( "REMOVING BUBBLE" );

			var display:Display = entity.get(Display);
			var uiGroup:LandUIGroup = this.landGroup.getUIGroup();
			uiGroup.inputManager.removeListeners( display.displayObject );
			uiGroup.sharedTip.removeToolTip( display.displayObject as DisplayObjectContainer );

			this.removeEntity( entity );

		} //

		private function onPlanetDeleted( err:String ):void {
		} //

		private function recheckMembership():void {
			this.shellApi.siteProxy.retrieve( PopDataStoreRequest.memberStatusRequest() );
		}

		private function hideUIPanes():void {
			
			this.newWorldPane.visible = false;
			//this.deleteConfirmPane.visible = false;
			//this.deleteConfirmPane.y = -500;

			if ( this.messagePane.visible ) {
				this.messagePane.hide();
			}

			this.membershipPane.visible = false;
			//this.sharePane.visible = false;
			this.newWorldPane.y = -500;
			this.membershipPane.y = -500;
			//this.sharePane.y = -500;

			if (this.doMembershipRecheck) {
				this.doMembershipRecheck = false;
				this.recheckMembership();
			}
			
		} // hideUIPanes()

		override public function destroy():void {

			var uiGroup:LandUIGroup = this.landGroup.getUIGroup();

			// It would be nice to automate all these destroys - the way systems do; Not quite sure the best way to do this.
			// one way would be to make an inputManager and SharedTip just for this group.
			LandUtils.destroyTipButton( this.nw_btnConfirm, uiGroup );
			LandUtils.destroyTipButton( this.mp_btnMembership, uiGroup );
			LandUtils.destroyTipButton( this.btnSeeMore, uiGroup );

			this.realmViewList.destroy();
			this.realmCodePane.destroy();

			uiGroup.inputManager.removeListeners( this.bgClip );
			uiGroup.sharedTip.removeToolTip( this.bgClip );

			// DESTROY ALL EXISTING Worlds/ENTITIES.
			this.destroyAllWorlds();

			this.curInfoPane.destroy();
			this.messagePane.destroy();

			// biome selection buttons.
			for ( var i:int = this.biomeNames.length-1; i >= 0; i-- ) {
				LandUtils.destroyTipButton( this.newWorldPane["btnBiome" + i], uiGroup );
			}
			// world size buttons.
			for ( i = this.sizeNames.length-1; i >= 0; i-- ) {
				LandUtils.destroyTipButton( this.newWorldPane["btnSize" + i], uiGroup );
			}

			super.destroy();

		} //

	}
}
