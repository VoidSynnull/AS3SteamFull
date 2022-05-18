package game.scenes.lands.lab1 {
	
	import com.greensock.easing.Sine;
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.Group;
	
	import game.components.entity.Dialog;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.comm.PopResponse;
	import game.managers.ads.AdManagerBrowser;
	import game.proxy.DataStoreRequest;
	import game.proxy.browser.DataStoreProxyPopBrowser;
	import game.scene.template.CameraGroup;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.lands.LandsEvents;
	import game.scenes.lands.shared.IntroPopup;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.monsters.RealmsNpcBuilder;
	import game.scenes.lands.shared.popups.RealmsPopupVideo;
	import game.ui.hud.Hud;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.TweenUtils;
	
	public class Lab1 extends PlatformerGameScene {
		
		protected var landGroup:LandGroup;
		private var _events:LandsEvents;
		private var master:Entity;
		private var fade:ScreenEffects;
		//private var loadedWithHammer:Boolean;
		
		public function Lab1() {
			
			super();
			
		} //

		/**
		 * used to grant poptanium from the console.
		 */
		public function poptanium( amount:int=50 ):void {

			if ( this.landGroup ) {
				this.landGroup.getPoptanium( amount );
			}

		} //

		/**
		 * used to grant experience from the console.
		 */
		public function experience( amount:int=50 ):void {

			if ( this.landGroup ) {
				this.landGroup.getExperience( amount );
			}

		} //

		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {
			
			super.groupPrefix = "scenes/lands/lab1/";
			
			var cameraGroup:CameraGroup = new CameraGroup();
			cameraGroup.allowLayerGrid = false;
			super.addChildGroup(cameraGroup);
			
			super.init( container );

		} //

		// initiate asset load of scene specific assets.
		override public function load():void {
			_events = super.events as LandsEvents;
			
			super.load();
			
		} //
		
		// all assets ready
		override public function loaded():void {
			//changing to an as3 popup so we don't have to go to as2 anymore
			//if player is not registered, send to RedirectToRegistration as2 scene
			if (shellApi.profileManager.active.isGuest) {
				// Since the player is going to register now, the login name is going to change
				// when they come back, their existing game state is stored under their old name.
				// So we stash their old login name in the transit token until we can transfer
				// their game state to the new profile
				return;
			}

			if( !shellApi.checkEvent(_events.SAW_INTRO_VIDEO) ) {
				fade = new ScreenEffects(overlayContainer, shellApi.camera.viewportWidth, shellApi.camera.viewportHeight);
				fade.fadeToBlack(0);
				this.pause(false);
			}

			this.landGroup = new LandGroup( this );
			this.addChildGroup( this.landGroup );

			// triggers after the init callback - once database or server data has loaded.
			this.landGroup.ready.addOnce( this.landLoaded );

			// example of ad plugin
			//this.landGroup.init( this.landInitComplete, Vector.<RealmsAdPlugin>( [new InsideOutPlugin()] ) );
			this.landGroup.init( this.landInitComplete );

			// hide Realms button in hud since you are already in Realms
			var hud:Hud = this.getGroupById(Hud.GROUP_ID) as Hud;
			hud.hideButton(Hud.REALMS);
		}
		
		private function onRealmsStatus(response:PopResponse):void {
			trace("Lab1::onRealmsStatus(): response", response.toString());
			//block non members until public launch, or if servers are down
			var featureIsAvailable:Boolean	= true;
			var canAccess:Boolean			= true;
			if (response.data) {
				if (response.data.hasOwnProperty('feature_status')) {
					featureIsAvailable			= ('off'		!= response.data.feature_status);
					var membersOnly:Boolean		= ('members'	== response.data.feature_status);
					var thereWasAnError:Boolean	= ('?'			== response.data.feature_status);
					if (thereWasAnError) {
					}
					canAccess = membersOnly ? (shellApi.profileManager.active.isMember) : featureIsAvailable;
				}
			}
			if (!canAccess) {
				super.loaded();
				showIntroPopup();
				return;
			}

			this.landGroup.loadFromDatabase();

		} // loaded()
		
		/**
		 * if inProgress is true, then the land initialized returning from an ad
		 * and is just continuing a game in progress.
		 */
		private function landInitComplete( inProgress:Boolean ):void {
			
			if ( inProgress ) {
				return;
			}


			if ( !AppConfig.debug ) {

				shellApi.siteProxy.retrieve( DataStoreRequest.featureStatusRequest("realms"), this.onRealmsStatus); 

			} else {

				this.landGroup.loadFromDatabase();
				//this.landGroup.loadServerWorld( "start_world.xml" );
				//this.landGroup.playLocally( "lunar" );

			} //
			
			/*if ( this.shellApi.checkHasItem( "hammer" ) ) {
				this.landGroup.loadFromDatabase();
				//this.landGroup.playLocally();
			} else {
				this.landGroup.loadFromDatabase();
				//this.landGroup.loadServerWorld( "start_world.xml" );
			}*/
			
		} //
		
		private function landLoaded( group:Group ):void {
			
			super.loaded();
			
			super.shellApi.eventTriggered.add( this.eventTriggered );
			
			if( shellApi.checkEvent(_events.SAW_INTRO_VIDEO) ) {
				this.landGroup.setBiomeAmbientSound();
			} else {
					showIntroVideo();
			}
			
		} //
		
		private function eventTriggered( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void {
			
			//change this to trigger AFTER talking to Master Creator
			if ( event == "gotItem_hammer" ) {

				if( !shellApi.checkEvent(_events.SAW_MASTER_GHOST )) {
					
					SceneUtil.lockInput(this, true);					
					//shellApi.triggerEvent("show_master");
	
					var builder:RealmsNpcBuilder = new RealmsNpcBuilder( this );
					builder.loadMasterBuilder( this.onMasterBuilderLoaded );

				}	
				this.landGroup.enableEditing();
				( this.landGroup.gameEntity.get( Audio ) as Audio ).play( "music/important_item.mp3" );

			}
			else if ( event == "see_scene_edge" ) {
				player.get(Dialog).sayById("seeSceneEdge");
			}
			else if ( event == "see_temple" ) {
				player.get(Dialog).sayById("seeTemple");
				//( this.landGroup.gameEntity.get( Audio ) as Audio ).play( "music/ancient_cavern.mp3" );
			}
			else if ( event == "fall_in_pit" ) {
				player.get(Dialog).sayById("fallInPit");
				//( this.landGroup.gameEntity.get( Audio ) as Audio ).play( "ambient/dark_low_ambient.mp3" );
			}
			else if ( event == "see_anvil" ) {

				if ( this.shellApi.checkHasItem( "hammer" ) ) {
					player.get(Dialog).sayById("seeAnvil");
				}

			}
			else if ( event == "see_house" ) {
				if ( !this.shellApi.checkEvent(_events.REACHED_TREASURE) ) {
					player.get(Dialog).sayById("seeHouse");
					this.landGroup.getUIGroup().showCreateHint();
				}
			}
			else if ( event == "reach_treasure" ) {
				if ( !this.shellApi.checkEvent(_events.REACHED_TREASURE) ) {
					this.shellApi.completeEvent(_events.REACHED_TREASURE);
				}
			}
			else if ( event == "realms_hint" ) {
				if ( !this.shellApi.checkEvent(_events.GOT_REALMS_HINT) ) {
					player.get(Dialog).sayById("realmsHint");
					//this.shellApi.completeEvent(_events.GOT_REALMS_HINT);
					this.landGroup.getUIGroup().showRealmsHint();
				}
			}else if ( event == "master_fade_out" ) {
				SceneUtil.lockInput(this, true);
				TweenUtils.globalTo(this, master.get(Display), 2, {alpha:0}, "masterFadeIn", .5);
				SceneUtil.addTimedEvent(this, new TimedEvent(4, 1, this.completeMaster, true));
			}else if ( event == "firstLineOver" ) {
				SceneUtil.lockInput(this, false);
			}
			
		} //
		
		private function setupMaster( master:Entity ):void {

			var display:Display = EntityUtils.getDisplay( master );
			var phantomGlow:GlowFilter = new GlowFilter( 0x9CC6DC, 1, 10, 10, 2, 1 );
			display.displayObject.filters = [ phantomGlow ];
			display.alpha = 0;
			master.add( new Tween() );

		} //

		private function onMasterBuilderLoaded( e:Entity ):void {

			//trace( "MASTER BUILDER LOADED ");
			this.master = e;

			this.shellApi.completeEvent( this._events.SAW_MASTER_GHOST );

			var sp:Spatial = e.get( Spatial );

			//var pSpatial:Spatial = this.player.get(Spatial);
			//sp.x = pSpatial.x;
			//sp.y = pSpatial.y - 120;

			sp.x = 2200;
			sp.y = 2005;

			ToolTipCreator.addToEntity(e);

			// add some glow filters and stuff.
			this.setupMaster( e );

			// in case the master is offscreen when he enters. only using for testing right now?
			//( e.get( Sleep ) as Sleep ).ignoreOffscreenSleep = true;

			// load master dialog
			this.shellApi.loadFile( this.landGroup.islandDataURL + "master_dialog.xml", this.masterDialogLoaded );

			this.landGroup.onLeaveScene.addOnce( this.removeMaster );

			//e.get(Tween).to(e.get(Display), 2, { alpha:.6, delay: 0.5, ease:Sine.easeInOut, onComplete: this.sayMasterFirstLine} );

		} //

		private function masterDialogLoaded( dialogXML:XML ):void {

			//trace( "MASTER DIALOG LOADED " );
			var dialogGroup:CharacterDialogGroup = this.getGroupById( CharacterDialogGroup.GROUP_ID ) as CharacterDialogGroup;
			dialogGroup.addAllDialog( dialogXML, true );

			// that should have done it.
			this.master.get(Tween).to( this.master.get(Display), 2, { alpha:.6, delay: 0.5, ease:Sine.easeInOut, onComplete: this.sayMasterFirstLine} );

		} //

		private function sayMasterFirstLine():void {
			
			var dialog:Dialog = master.get( Dialog );
			if ( dialog == null ) {
				//trace( "NO DIALOG!!" );
				SceneUtil.lockInput( this, false );
			} else {
				//trace( "DIALOG FOUND" );
				dialog.sayById( "theHammer" );
			}
			
			//master.get(Dialog).sayById("theHammer");
			
		} //

		private function completeMaster():void {
			
			SceneUtil.lockInput(this, false);
			
			this.landGroup.getUIGroup().showHammerHint();
			this.player.get(Dialog).sayById("hammerDialog");
			
			this.shellApi.completeEvent(_events.FINISHED_MASTER_GHOST);
			
			removeMaster();
			
		} //
		
		private function removeMaster():void {
			
			this.removeEntity( this.getEntityById( "masterBuilder" ));
			
		} //
		
		private function showIntroVideo():void
		{
			// RLH: load main street wrapper for intro video
			if(this.shellApi.adManager && this.shellApi.adManager is AdManagerBrowser)
			{
				AdManagerBrowser( this.shellApi.adManager ).handleWrapper(false);
			}
			
			var popup:RealmsPopupVideo ;
			
			popup = super.addChildGroup(new RealmsPopupVideo(super.overlayContainer)) as RealmsPopupVideo;
			popup.id = "realmsPopupVideo";
			
			//popup.ready.addOnce(handleStartedVideo);			
			popup.removed.addOnce(finishedIntroVideo);
			
		}
		
		private function finishedIntroVideo(popup:RealmsPopupVideo):void {
			fade.fadeFromBlack(1);
			this.unpause();
			this.landGroup.setBiomeAmbientSound();
			shellApi.completeEvent(_events.SAW_INTRO_VIDEO );
		}
		
		private function showIntroPopup():void
		{
			var introPopup:IntroPopup = new IntroPopup(overlayContainer);
			addChildGroup(introPopup);
		}
		
	} // class
	
} // package