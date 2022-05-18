package game.scenes.lands.shared.plugins {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.character.Skin;
	import game.components.motion.TargetSpatial;
	import game.components.timeline.Timeline;
	import game.data.animation.entity.character.Attack;
	import game.data.animation.entity.character.Salute;
	import game.data.sound.SoundModifier;
	import game.managers.ads.AdManagerBrowser;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.classes.ObjectIconPair;
	import game.scenes.lands.shared.components.Disintegrate;
	import game.scenes.lands.shared.components.InputManager;
	import game.scenes.lands.shared.components.LightningStrike;
	import game.scenes.lands.shared.components.SharedToolTip;
	import game.scenes.lands.shared.components.ThrowHammer;
	import game.scenes.lands.shared.systems.BlastTileSystem;
	import game.scenes.lands.shared.systems.DisintegrateSystem;
	import game.scenes.lands.shared.systems.LifeSystem;
	import game.scenes.lands.shared.systems.ThrowHammerSystem;
	import game.scenes.lands.shared.ui.LandMenu;
	import game.scenes.lands.shared.ui.panes.MaterialPane;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.SkinUtils;
	import game.utils.AdUtils;

	public class RealmsStarWarsPlugin extends RealmsAdPlugin {


		/**
		 * handheld saber item.
		 */
		private const SABER_ITEM:String = "limited_starwars_realms";

		//private const CLICK_URL:String = "http://ad.doubleclick.net/ddm/trackclk/N763.177633.POPTROPICA.COM/B8566434.116507105;dc_trk_aid=291594790;dc_trk_cid=58345130";

		static public const TRACK_URL:String =
			"https://ad.doubleclick.net/ddm/trackimp/N763.177633.POPTROPICA.COM/B8566434.116507105;dc_trk_aid=291594790;dc_trk_cid=58345130;ord=";

		public function RealmsStarWarsPlugin() {

			this._campaignName = "DXD2015StarWarsRebels2";
			this._uiFileName = "starwars_ui.swf";

		} //

		override public function init( group:LandGroup ):void {

			super.init( group );

			//this.uiGroup.ready.addOnce( this.onUILoaded );
			this.landGroup.ready.addOnce( this.landGroupReady );

			this.landGroup.gameData.progress.onLevelUp.add( this.onLevelUp );

		} //

		private function landGroupReady( group:Group ):void {

			( this.landGroup.getSystem( LifeSystem ) as LifeSystem ).onEntityDied.add( this.onEntityDied );

			var landMenu:LandMenu = this.uiGroup.getLandMenu();
			var menuClip:MovieClip = landMenu.pane;

			this.uiGroup.makeButton( menuClip.btnSaberSwing, this.saberSwingClicked, 2 );
			menuClip.btnSaberSwing.visible = false;

			this.uiGroup.makeButton( menuClip.btnSaberThrow, this.saberThrowClicked, 2 );
			menuClip.btnSaberThrow.visible = false;

			var modeClip:MovieClip = this.uiGroup.getModeMenu().pane as MovieClip;
			this.uiGroup.makeButton( modeClip.btnSaber, this.saberModeClicked, 2 );

			this.uiGroup.onUIModeChanged.add( this.onUIModeChanged );			
			this.uiGroup.inputManager.addEventListener( this.uiGroup.getUIClip().stage, KeyboardEvent.KEY_DOWN, this.onKeyDown );


			// material pane callback; for tracking.
			var matPane:MaterialPane = this.uiGroup.getLandMenu().getMaterialPane();
			matPane.onOpenPane = this.onMaterialPane;
			matPane.onCategoryClicked = this.onMaterialPane;

			// add the advertisement web-URL click.
			// get the material pane panel.
			var pane:MovieClip = matPane.pane as MovieClip;
			matPane.makeButton( pane.btnStarWars, this.onStarWarsURL );

			this.landGroup.onLeaveScene.add( this.trackSceneVisit );

			this.trackSceneVisit();

		} //

		private function onStarWarsURL( e:MouseEvent ):void {

			this.landGroup.shellApi.track( "ClickToSponsor", "Materials", null, this.campaignName );
			AdUtils.openSponsorURL( this.landGroup.shellApi, AdManagerBrowser( this.landGroup.shellApi.adManager ).getWrapperClickURL(), this.campaignName, "Plugin", "StarWars" );

		} //

		private function trackSceneVisit():void {

			// only track if they have the hammer - and thus the star wars interface.
			if ( this.uiGroup.getLandMenu().visible ) {
				this.landGroup.shellApi.track( "BrandedRealmsScenesPageViews", null, null, this.campaignName );
			}

		}

		public function sendTrackPixel():void {
			AdUtils.sendTrackingPixels(this.landGroup.shellApi, this._campaignName, TRACK_URL + Math.floor( int.MAX_VALUE*Math.random()) + "?" );
		}

		private function onLevelUp( newLevel:int, unlockedObjects:Vector.<ObjectIconPair> ):void {

			this.landGroup.shellApi.track( "BrandedLevelUpPageViews", null, null, this.campaignName );
			AdUtils.sendTrackingPixels(this.landGroup.shellApi, this._campaignName, TRACK_URL + Math.floor( int.MAX_VALUE*Math.random()) + "?" );

		} //

		private function onMaterialPane():void {

			this.landGroup.shellApi.track( "BrandedMaterialMenuPageViews", null, null, this.campaignName );
			AdUtils.sendTrackingPixels(this.landGroup.shellApi, this._campaignName, TRACK_URL + Math.floor( int.MAX_VALUE*Math.random()) + "?" );

		} //

		private function onEntityDied( e:Entity ):void {

			// only if player...
			if ( e == this.landGroup.getPlayer() ) {
				this.landGroup.shellApi.track( "BrandedDeathsPageViews", null, null, this.campaignName );
				AdUtils.sendTrackingPixels(this.landGroup.shellApi, this._campaignName, TRACK_URL + Math.floor( int.MAX_VALUE*Math.random()) + "?" );
			}

		} //

		/**
		 * need to get the ui clip and set buttons in several difference places:
		 * 
		 * btnSaber in the LandModeMenu puts the game in saber mode.
		 * 
		 * btnSaberSwing in the LandMenu should only be enabled when the player is in saber mode.
		 * 
		 * Other landMenu specials need to be disabled in saber mode.
		 * 
		 */
		/*public function onUILoaded( group:Group ):void {

			var landMenu:LandMenu = this.uiGroup.getLandMenu();
			var menuClip:MovieClip = landMenu.pane;

			// this is kind of messy. need a better way to set events and toolTips at the same time.
			//var inputMgr:InputManager = this.uiGroup.inputManager;
			//var toolTips:SharedToolTip = this.uiGroup.sharedTip;

			this.uiGroup.makeButton( menuClip.btnSaberSwing, this.saberSwingClicked, 2 );
			menuClip.btnSaberSwing.visible = false;

			this.uiGroup.makeButton( menuClip.btnSaberThrow, this.saberThrowClicked, 2 );
			menuClip.btnSaberThrow.visible = false;

			var modeClip:MovieClip = this.uiGroup.getModeMenu().pane as MovieClip;
			this.uiGroup.makeButton( modeClip.btnSaber, this.saberModeClicked, 2 );

			this.uiGroup.onUIModeChanged.add( this.onUIModeChanged );

			this.uiGroup.inputManager.addEventListener( this.uiGroup.getUIClip().stage, KeyboardEvent.KEY_DOWN, this.onKeyDown );

		} //*/

		private function onUIModeChanged( newMode:uint ):void {

			var landMenu:LandMenu = this.uiGroup.getLandMenu();
			var menuClip:MovieClip = landMenu.pane;

			if ( (newMode & LandEditMode.SPECIAL) != 0 ) {

				SkinUtils.setSkinPart( this.landGroup.getPlayer(), SkinUtils.ITEM, this.SABER_ITEM, false );

				// audio for entering light-saber mode.
				AudioUtils.play( this.landGroup, SoundManager.EFFECTS_PATH + "limited_lightsaber_ignite_01.mp3" );

				( this.uiGroup.getModeMenu().pane as MovieClip ).btnSaber.hilite.visible = true;

				// hide all specials except saber.
				var btn:MovieClip = menuClip.btnSaberSwing;
				btn.visible = true;

				btn = menuClip.btnSaberThrow;
				btn.visible = true;

				landMenu.hideAbilities();

				this.landGroup.shellApi.track( "EquipSaberTool", null, null, this.campaignName );

				// TURN OFF Lightning strike.
				( this.landGroup.gameEntity.get( LightningStrike ) as LightningStrike ).pause();

			} else if ( newMode == LandEditMode.MINING ) {

				( this.uiGroup.getModeMenu().pane as MovieClip ).btnSaber.hilite.visible = false;

				// real mining mode unlocks all specials except saber.
				menuClip.btnSaberSwing.visible = menuClip.btnSaberThrow.visible = false;

				// TURN ON Lightning strike.
				( this.landGroup.gameEntity.get( LightningStrike ) as LightningStrike ).unpause();

			} else {

				( this.uiGroup.getModeMenu().pane as MovieClip ).btnSaber.hilite.visible = false;

				// hide saber special just the same.
				menuClip.btnSaberSwing.visible = menuClip.btnSaberThrow.visible = false;

			} //

		} //

		private function onKeyDown( e:KeyboardEvent ):void {

			if ( e.keyCode == Keyboard.NUMBER_7 ) {

				this.uiGroup.uiMode = LandEditMode.SPECIAL;

			} else if ( e.keyCode == Keyboard.NUMBER_8 ) {

				this.doSaberSwipe();

			} else if ( e.keyCode == Keyboard.NUMBER_9 ) {

				this.doSaberThrow();

			} //

		} //

		private function saberModeClicked( e:MouseEvent ):void {

			// this will force the special light saber mode.
			this.uiGroup.uiMode = LandEditMode.SPECIAL;

		} //

		private function saberThrowClicked( e:MouseEvent ):void {

			this.doSaberThrow();

		} //

		private function saberSwingClicked( e:MouseEvent ):void {

			this.doSaberSwipe();

		} //

		/**
		 * Swipe light saber in the air.
		 */
		public function doSaberSwipe():void {

			if ( (this.uiGroup.uiMode & LandEditMode.SPECIAL)==0 ) {
				return;
			}

			this.landGroup.shellApi.track( "SwingSaberTool", null, null, this.campaignName );

			var player:Entity = this.landGroup.getPlayer();

			var movement:CharacterMovement = player.get( CharacterMovement ) as CharacterMovement;
			if ( movement == null ) {
				return;
			}
			if ( movement.state == CharacterMovement.AIR || movement.state == CharacterMovement.CLIMB || movement.state == CharacterMovement.DIVE ) {
				return;
			}

			AudioUtils.play( this.landGroup, SoundManager.EFFECTS_PATH + "limited_lightsaber_swing_0" + Math.floor( 1+3*Math.random() ) + ".mp3" );

			CharUtils.setAnim( player, Attack );
			
			var tl:Timeline = CharUtils.getTimeline( player );
			tl.handleLabel( "trigger", this.doSaberImpact );
			
			MotionUtils.zeroMotion( player );
			
		} //
		
		private function doSaberImpact():void {
			
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
			
			// point at tip of light saber. maybe.
			var p:Point = new Point( 0, 38 );
			p = ( display.displayObject as DisplayObjectContainer ).localToGlobal( p );
			p = this.landGroup.curScene.hitContainer.globalToLocal( p );

			var blastSys:BlastTileSystem = this.landGroup.getSystem( BlastTileSystem ) as BlastTileSystem;
			blastSys.blastRadius( this.landGroup.gameData.tileLayers["foreground"], p.x, p.y, 160 );

			AudioUtils.play( this.landGroup, SoundManager.EFFECTS_PATH + "smash_02.mp3", 1 , false, SoundModifier.EFFECTS );
			
		} //

		/**
		 * throw the hammer in the direction the player is facing.
		 */
		public function doSaberThrow():void {
			
			if ( (this.uiGroup.uiMode & LandEditMode.SPECIAL) == 0 ) {
				return;
			}

			this.landGroup.shellApi.track( "ThrowSaberTool", null, null, this.campaignName );

			var player:Entity = this.landGroup.getPlayer();

			var movement:CharacterMovement = player.get( CharacterMovement ) as CharacterMovement;
			if ( movement == null || movement.state == CharacterMovement.AIR || movement.state == CharacterMovement.CLIMB || movement.state == CharacterMovement.DIVE ) {
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
			this.landGroup.shellApi.loadFile(
				(this.landGroup.sharedAssetURL + this.SABER_ITEM + ".swf"),
				this.saberLoaded );

		} //

		/**
		 * saber loaded for throwing.
		 */
		private function saberLoaded( clip:MovieClip ):void {

			var player:Entity = this.landGroup.getPlayer();
			//var motion:Motion = player.get( Motion ) as Motion;

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

			//this.landGroup.shellApi.track( "Hammerang", null, null, LandGroup.CAMPAIGN );

			// these numbers come from the offset to the hammer top. no good way to set them right now.
			var p:Point = new Point( 0, 0 );
			p = ( itemDisplay.displayObject as DisplayObjectContainer ).localToGlobal( p );
			p = this.landGroup.curScene.hitContainer.globalToLocal( p );

			var playerSpatial:Spatial = player.get( Spatial );
			var saberMotion:Motion = new Motion();
			var spatial:Spatial = new Spatial( p.x, p.y );

			// player scale is actually backwards from what you'd expect
			if ( playerSpatial.scaleX < 0 ) {
				saberMotion.rotationVelocity = 500;
				saberMotion.velocity.x = 800;
				spatial.scaleX = -1;
			} else {
				saberMotion.rotationVelocity = -500;
				saberMotion.velocity.x = -800;
			}

			var saber:Entity = new Entity()
				.add( saberMotion, Motion )
				.add( spatial, Spatial )
				.add( new TargetSpatial( playerSpatial ), TargetSpatial )
				.add( new ThrowHammer( this.onSaberReturn ), ThrowHammer )
				.add( new Display( clip ), Display )
				.add( new Disintegrate( 80 ), Disintegrate );
			
			if ( !this.landGroup.getSystem( DisintegrateSystem ) ) {
				this.landGroup.addSystem( new DisintegrateSystem(), SystemPriorities.update );
			} //
			if ( !this.landGroup.getSystem( ThrowHammerSystem ) ) {
				this.landGroup.addSystem( new ThrowHammerSystem(), SystemPriorities.moveComplete );
			}

			this.landGroup.addEntity( saber );
			
			AudioUtils.play( this.landGroup, SoundManager.EFFECTS_PATH + "limited_lightsaber_swing_0" + Math.floor( 1+3*Math.random() ) + ".mp3" );
			AudioUtils.play( this.landGroup, SoundManager.EFFECTS_PATH + "whoosh_05.mp3", 1 , false, SoundModifier.EFFECTS );
			
		} //

		private function onSaberReturn( thrownSaber:Entity ):void {

			var item:Entity = ( this.landGroup.getPlayer().get( Skin ) as Skin ).getSkinPartEntity( "item" );
			if ( item == null ) {
				return;
			}
			var itemDisplay:Display = item.get( Display );
			if ( itemDisplay == null ) {
				return;
			}

			itemDisplay.visible = true;

			this.landGroup.removeEntity( thrownSaber, true );

		} //

		override public function destroy():void {

			var landMenu:LandMenu = this.uiGroup.getLandMenu();
			var menuClip:MovieClip = landMenu.pane;

			var inputMgr:InputManager = this.uiGroup.inputManager;
			var toolTips:SharedToolTip = this.uiGroup.sharedTip;

			// shouldn't actually need this...
			inputMgr.removeListeners( menuClip.btnSaberSwipe );

		} //

	} // class
	
} // package