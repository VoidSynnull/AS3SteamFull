package game.scenes.lands.shared.plugins {
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.systems.LandEditSystem;
	import game.scenes.lands.shared.ui.LandMenu;
	import game.util.ColorUtil;
	import game.utils.AdUtils;
	
	public class InsideOutPlugin extends RealmsAdPlugin {
		
		//private const CLICK_URL:String = "http://ad.doubleclick.net/ddm/trackclk/N763.177633.POPTROPICA.COM/B8566434.116507105;dc_trk_aid=291594790;dc_trk_cid=58345130";
		
		static public const TRACK_URL:String =
			"https://ad.doubleclick.net/ddm/trackimp/N763.177633.POPTROPICA.COM/B8566434.116507105;dc_trk_aid=291594790;dc_trk_cid=58345130;ord=";
		
		public function InsideOutPlugin() {
			
			this._campaignName = "InsideOut";
			this._uiFileName = "inside_out_ui.swf";
			
		} //
		
		/**
		 * save player's color transform so it can be restored after inside out menu closes.
		 */
		private var saveTrans:ColorTransform;
		private var colorMenu:InsideOutMenu;
		
		override public function init( group:LandGroup ):void {
			
			super.init( group );
			
			//this.uiGroup.ready.addOnce( this.onUILoaded );
			this.landGroup.ready.addOnce( this.landGroupReady );
			
		} //
		
		private function landGroupReady( group:Group ):void {
			
			var modeClip:MovieClip = this.uiGroup.getModeMenu().pane as MovieClip;
			this.uiGroup.makeButton( modeClip.btnColors, this.onColorMode, 2 );
			
			// load the inside out menu for selecting the current inside out draw-mode.
			group.shellApi.loadFile( this.landGroup.pluginAssetURL + "inside_out_menu.swf", this.onMenuLoaded );
			
			this.uiGroup.onUIModeChanged.add( this.onUIModeChanged );			
			
			
			this.landGroup.onLeaveScene.add( this.trackSceneVisit );
			
			this.trackSceneVisit();
			
		} //
		
		private function onColorMode( e:MouseEvent ):void {
			
			this.uiGroup.uiMode = ( LandEditMode.EDIT | LandEditMode.SPECIAL );
			this.colorMenu.show();
			
		} //
		
		private function onMenuLoaded( clip:MovieClip ):void {
			
			this.landGroup.curScene.overlayContainer.addChild( clip );
			this.colorMenu = new InsideOutMenu( clip, this.uiGroup, this );
			
			this.colorMenu.init();
			
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
		
		private function onUIModeChanged( newMode:uint ):void {
			
			var landMenu:LandMenu = this.uiGroup.getLandMenu();
			var menuClip:MovieClip = landMenu.pane;
			
			if ( (newMode & LandEditMode.SPECIAL) != 0 ) {
				
				//SkinUtils.setSkinPart( this.landGroup.getPlayer(), SkinUtils.ITEM, this.SABER_ITEM, false );
				
				// audio for entering light-saber mode.
				//AudioUtils.play( this.landGroup, SoundManager.EFFECTS_PATH + "limited_lightsaber_ignite_01.mp3" );
				
			} else {
				
				// HIDE THE InsideOutMenu
				this.colorMenu.hide();
				if ( this.saveTrans != null ) {
					this.RemoveTint();
				}
				
			} //
			
		} // onUIModeChanged()
		
		public function SetCurrentColor( color:int ):void {
			
			var landSys:LandEditSystem = this.landGroup.getSystem( LandEditSystem ) as LandEditSystem;
			landSys.EditEffect.setGlitterColors( [ color ] );
			
			var e:Entity = this.landGroup.getPlayer();
			var mc:MovieClip = ( e.get(Display ) as Display ).displayObject as MovieClip;
			if ( this.saveTrans == null ) {
				this.saveTrans = mc.transform.colorTransform;
			}
			
			ColorUtil.tint( ( e.get( Display ) as Display ).displayObject, color, 55 );
			
		} //
		
		private function RemoveTint():void {
			
			if ( this.saveTrans == null ) {
				return;
			}
			
			var e:Entity = this.landGroup.getPlayer();
			( ( e.get( Display ) as Display ).displayObject as MovieClip ).transform.colorTransform = this.saveTrans;
			
		} //
		
		override public function destroy():void {
			
			this.colorMenu.destroy();
			
		} //
		
		/*private function TintPlayer( color:int ):void {
		
		var e:Entity = this.landGroup.getPlayer();
		var mc:MovieClip = ( e.get(Display ) as Display ).displayObject as MovieClip;
		if ( this.saveTrans == null ) {
		this.saveTrans = mc.transform.colorTransform;
		}
		
		ColorUtil.tint( ( e.get( Display ) as Display ).displayObject, color, 0.8 );
		
		} //*/
		
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
		
		
		
	} // class
	
} // package