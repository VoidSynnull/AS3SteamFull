package game.scenes.lands.shared.ui {
	
	/**
	 * might actually turn this class into a LandPane to streamline the buttons.. It's too minor to be a group.
	 */
	
	import com.greensock.TweenMax;
	import com.greensock.easing.Cubic;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.classes.SharedTipTarget;
	import game.scenes.lands.shared.classes.TypeSelector;
	import game.scenes.lands.shared.components.LandEditContext;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.tileLib.classes.LandProgress;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.ui.panes.LandPane;
	import game.scenes.lands.shared.ui.panes.MaterialPane;
	import game.scenes.lands.shared.util.LandUtils;
	
	public class LandMenu {

		/**
		 * space between menu bar icons.
		 */
		private const ICON_SPACING:Number = 8;

		private var helpPane:LandPane;
		
		/**
		 * pane for selecting different materials.
		 */
		private var materialPane:MaterialPane;
		public function getMaterialPane():MaterialPane { return this.materialPane; }

		/**
		 * of materials, worldMenu, biomeMenu, helpPane, only one can be visible at a time.
		 */
		private var activePane:LandPane;
		private var activeBtn:MovieClip;
		
		/**
		 * the quick bar with the current selection of tile types on it.
		 */
		private var quickBar:QuickBar;
		public function getQuickBar():QuickBar {
			return this.quickBar;
		}

		/**
		 * true if the landMenu is slid into view - false when it's been slid offscreen.
		 */
		private var onscreen:Boolean;
		private var slideTween:TweenMax;

		/**
		 * start x for place to slide out to.
		 */
		private var menuStartX:int;

		private var editContext:LandEditContext;
		
		// land editing group.
		private var myGroup:LandUIGroup;
		
		// movieclip that holds all the controls.
		private var myPane:MovieClip;
		public function get pane():MovieClip { return this.myPane; }

		private var btnMaterials:MovieClip;
		public function getMaterialsBtn():MovieClip { return this.btnMaterials; }
		
		private var btnBrushSize:MovieClip;
		private var btnLayer:MovieClip;
		
		private var btnHelp:MovieClip;

		private var btnPound:MovieClip;
		private var btnHammerang:MovieClip;
		private var btnSuperJump:MovieClip;

		/**
		 * Vector of all the buttons so you can enable/disable them all in the system.
		 *
		 * buttons are kept in the array in the order they should appear onscreen from right to left
		 * so they can be repositioned based on which are currently visible. (active)
		 *
		 */
		private var myButtons:Vector.<Sprite>;
		
		public function LandMenu( paneClip:MovieClip ) {
			
			this.myPane = paneClip;
			this.menuStartX = this.myPane.x;
			
			this.myButtons = new Vector.<Sprite>();
			
		} //

		/**
		 * passing the uiClip here is a bad legacy problem. should work on removing it.
		 */
		public function init( g:LandUIGroup, landGameData:LandGameData, uiClip:MovieClip ):void {

			this.myGroup = g;
			this.editContext = g.getEditContext();

			this.initMenuButtons();

			this.quickBar = new QuickBar( this.myPane.bar, this.myGroup, null );

			this.myGroup.onUIModeChanged.add( this.onModeChanged );

			this.initMenuPanes( g, uiClip );

			// select the foreground layer.
			this.setCurrentLayer( landGameData.getFGLayer()  );

			this.onscreen = true;
			this.visible = false;

		} //
		
		private function initMenuPanes( group:LandUIGroup, uiClip:MovieClip ):void {
			
			var pane:MovieClip = uiClip.materialsPane;
			this.materialPane = new MaterialPane( pane, group, this.closePaneClicked );
			this.materialPane.setSelectFunc( this.onTileSelected );
			
			pane = uiClip.helpPane;
			pane.visible = false;
			this.helpPane = new LandPane( pane, group );
			this.helpPane.makeButton( pane.btnClose, this.closePaneClicked );
			
			// TO-DO: remove this clip.
			uiClip.removeChild( uiClip.fileMenu );
			//this.fileMenu = new LandFileMenu( uiClip.fileMenu, group, this.closeActivePane );
			
		} //

		/**
		 * basic menu buttons.
		 */
		private function initMenuButtons():void {

			
			this.btnHelp = this.myPane.btnHelp;
			LandUtils.makeUIBtn( this.btnHelp, this.myGroup, this.helpClicked );
			this.addUIButton( this.btnHelp );

			this.initLayerButton();
			this.initBrushButton();

			this.btnMaterials = this.myPane.btnMaterials;
			LandUtils.makeUIBtn( this.btnMaterials, this.myGroup, this.onMaterialsClicked );
			this.addUIButton( this.btnMaterials );

			this.btnPound = this.myPane.btnPound;
			LandUtils.makeUIBtn( this.btnPound, this.myGroup, this.onPoundClicked );
			this.addUIButton( this.btnPound );

			this.btnHammerang = this.myPane.btnHammerang;
			LandUtils.makeUIBtn( this.btnHammerang, this.myGroup, this.onHammerangClicked );
			this.addUIButton( this.btnHammerang );
			
			this.btnSuperJump = this.myPane.btnSuperJump;
			LandUtils.makeUIBtn( this.btnSuperJump, this.myGroup, this.onSuperJumpClicked );
			this.addUIButton( this.btnSuperJump );

		} //

		private function onHammerangClicked( e:MouseEvent ):void {

			this.myGroup.doHammerang();

		} //

		private function onPoundClicked( e:MouseEvent ):void {

			this.myGroup.doHammerSmash();

		} //
		
		private function onSuperJumpClicked( e:MouseEvent ):void {

			this.myGroup.doHammerJump();

		} //

		public function updateMenuBar( curMode:int ):void {

			this.onModeChanged( curMode );

		} //

		/**
		 * different buttons are visible for each UI-mode. Special modes because of plugins
		 * will have to be partially handled by the plugin itself.
		 */
		private function onModeChanged( uiMode:uint ):void {

			if ( uiMode == LandEditMode.EDIT ) {

				this.doEditMode();
				
			} else if ( uiMode == LandEditMode.MINING ) {

				this.doMineMode();

			} else if ( (uiMode & LandEditMode.SPECIAL) != 0 ) {
				
				// whatever plugin or feature caused the special mode to occur should hide and show the appropriate buttons.
				this.closeActivePane();
				
			} else if ( uiMode == LandEditMode.PLAY ) {

				this.doPlayMode();

			} else {
				
				this.closeActivePane();
				
				// play mode.
				this.quickBar.hide();
				this.btnMaterials.visible = false;
				this.btnLayer.visible = false;
				this.btnBrushSize.visible = false;

				this.hideAbilities();
				
			} //

			this.repositionButtons();

		} //

		private function doEditMode():void {

			this.quickBar.show();
			this.btnMaterials.visible = true;
			this.btnLayer.visible = true;
			this.btnBrushSize.visible = true;
			
			this.btnSuperJump.visible = this.btnHammerang.visible = this.btnPound.visible = false;

		} //

		private function doMineMode():void {

			this.closeActivePane();
			
			this.quickBar.hide();
			this.btnMaterials.visible = false;
			this.btnLayer.visible = true;
			this.btnBrushSize.visible = false;
			
			var progress:LandProgress = this.myGroup.gameData.progress;
			if ( progress.hasSuperJump() ) {
				
				this.btnSuperJump.visible = this.btnHammerang.visible = this.btnPound.visible = true;
				
			} else if ( progress.hasHammerang() ) {
				
				this.btnHammerang.visible = this.btnPound.visible = true;
				
			} else if ( progress.hasHammerPound() ) {
				
				this.btnPound.visible = true;
				
			} //

		} //

		private function doPlayMode():void {

			var progress:LandProgress = this.myGroup.gameData.progress;
			this.btnHammerang.visible = this.btnPound.visible = false;
			if ( progress.hasSuperJump() ) {
				this.btnSuperJump.visible = true;
			} else {
				this.btnSuperJump.visible = false;
			}
			
			this.closeActivePane();

			// play mode.
			this.quickBar.hide();
			this.btnMaterials.visible = false;
			this.btnLayer.visible = false;
			this.btnBrushSize.visible = false;

		} //

		private function repositionButtons():void {

			var btn:Sprite = this.myButtons[0];
			
			if ( btn == null ) {
				return;
			}

			var len:int = this.myButtons.length;
			var curX:Number = btn.x + btn.width/2;

			for( var i:int = 0; i < len; i++ ) {
				
				btn = this.myButtons[i];
				if ( btn.visible ) {
					// all these width/2 variables get added because the icon sprites are centered.
					curX -= btn.width/2;
					btn.x = curX;
					curX -= ( btn.width/2 + this.ICON_SPACING );
				}
				
			} //
			
			// controls where the quickBar ( materials selection ) slides out from.
			// notice adding back in ICON_SPACING because of the over-shoot.
			this.quickBar.setBarStart( curX + this.ICON_SPACING  );
			
		} //

		public function hideAbilities():void {
			
			this.btnSuperJump.visible = this.btnHammerang.visible = this.btnPound.visible = false;
			
		} //

		public function reset():void {

			this.quickBar.removeAll();
			this.materialPane.removeAllTiles();

		} //
		
		/**
		 * if the land menu is onscreen, it begins to slide offscreen,
		 * if offscreen it starts to slide onscreen.
		 */
		public function toggleSlider():void {
			
			if ( this.slideTween != null ) {
				this.slideTween.kill();
			}
			
			if ( this.onscreen ) {
				
				this.slideTween = TweenMax.to( this.myPane, 0.5, { x:this.menuStartX + this.myPane.width + 20, onComplete:this.sliderDone, ease:Cubic.easeIn } );
				
			} else {
				
				this.slideTween = TweenMax.to( this.myPane, 0.5, { x:this.menuStartX, onComplete:this.sliderDone, ease:Cubic.easeOut } );
				
			} //
			this.onscreen = !this.onscreen;
			
		} //
		
		private function sliderDone():void {
			
			this.slideTween = null;
			
		} //
		
		public function closeActivePane():void {
			
			if ( this.activePane ) {
				
				this.activePane.hide();
				this.activeBtn.hilite.visible = false;
				
				this.activeBtn = null;
				this.activePane = null;
				
			} //
			
		} //
		
		/**
		 * 
		 * open the given pane if it's not open, and hide it if it's already active.
		 * 
		 * btn is the button that opened the pane. this should be hilited while the pane remains open.
		 */
		private function togglePane( pane:LandPane, btn:MovieClip ):void {
			
			if ( this.activePane == pane ) {
				
				pane.hide();
				btn.hilite.visible = false;
				this.activePane = null;
				this.activeBtn = null;
				
			} else {
				
				if ( this.activePane != null ) {
					this.activePane.hide();
					this.activeBtn.hilite.visible = false;
				}
				
				this.activeBtn = btn;
				btn.hilite.visible = true;
				this.activePane = pane;
				pane.show();
				
			} //
			
		} //

		/**
		 * material selected from the material pane.
		 * close the material pane.
		 */
		private function onTileSelected( selector:TypeSelector, icon:BitmapData, flipped:Boolean ):void {
			
			this.quickBar.addTypeSelector( selector, icon, flipped );
			this.togglePane( this.materialPane, this.btnMaterials );
			
		} //

		public function showMaterialPane():void {

			if ( !this.materialPane.visible ) {
				this.toggleMaterialPane();
			}

		} //

		public function toggleMaterialPane():void {

			if ( !this.materialPane.visible ) {
				this.myGroup.shellApi.track( "Clicked", "Materials", null, LandGroup.CAMPAIGN );
			}

			this.myGroup.hideHintArrow();
			this.togglePane( this.materialPane, this.btnMaterials );
			
		} //

		private function helpClicked( e:MouseEvent ):void {

			if ( !this.helpPane.visible ) {
				this.myGroup.shellApi.track( "Clicked", "HelpMenu", null, LandGroup.CAMPAIGN );
			}
			this.togglePane( this.helpPane, this.btnHelp );
			
		} //
		
		/**
		 * function for the close buttons of any of the panes.
		 */
		public function closePaneClicked( e:MouseEvent ):void {
			this.closeActivePane();
		} //
		
		/**
		 * button to toggle the materials pane clicked.
		 */
		private function onMaterialsClicked( e:MouseEvent ):void {
			this.myGroup.hideHintArrow();
			this.togglePane( this.materialPane, this.btnMaterials );
		} //
		
		protected function initBrushButton():void {
			
			var btn:MovieClip = this.btnBrushSize = this.myPane.btnBrushSize;
			
			var sub:MovieClip = btn.btnSmallBrush;
			sub.hilite.mouseEnabled = sub.hilite.mouseChildren = false;
			sub.hilite.visible = true;
			
			sub = btn.btnLargeBrush;
			sub.hilite.mouseEnabled = sub.hilite.mouseChildren = false;
			sub.hilite.visible = false;
			
			LandUtils.makeUIBtn( btn, this.myGroup, this.brushSizeClicked );
			this.addUIButton( btn, true );
			
		} //
		
		private function brushSizeClicked( e:MouseEvent ):void {
			
			if ( e.target == this.btnBrushSize.btnLargeBrush ) {
				
				this.myGroup.shellApi.track( "Clicked", "LargeBrush", null, LandGroup.CAMPAIGN );
				this.btnBrushSize.btnLargeBrush.hilite.visible = true;
				this.btnBrushSize.btnSmallBrush.hilite.visible = false;
				
				this.myGroup.setLargeBrush( true );
				
			} else if ( e.target == this.btnBrushSize.btnSmallBrush ) {
				
				this.myGroup.shellApi.track( "Clicked", "SmallBrush", null, LandGroup.CAMPAIGN );
				this.btnBrushSize.btnLargeBrush.hilite.visible = false;
				this.btnBrushSize.btnSmallBrush.hilite.visible = true;
				
				this.myGroup.setLargeBrush( false );
				
			} //
			
		} //
		
		protected function initLayerButton():void {

			var btn:MovieClip = this.btnLayer = this.myPane.btnLayer;

			var sub:MovieClip = btn.btnFg;
			sub.hilite.mouseEnabled = sub.hilite.mouseChildren = false;
			sub.hilite.visible = true;

			sub = btn.btnBg;
			sub.hilite.mouseEnabled = sub.hilite.mouseChildren = false;
			sub.hilite.visible = false;

			LandUtils.makeUIBtn( btn, this.myGroup, this.layerClicked );
			this.addUIButton( btn, true );

		} //

		private function layerClicked( e:MouseEvent ):void {

			if ( e.target == this.btnLayer.btnFg ) {

				this.myGroup.shellApi.track( "Clicked", "Foreground", null, LandGroup.CAMPAIGN );

				this.btnLayer.btnFg.hilite.visible = true;
				this.btnLayer.btnBg.hilite.visible = false;

				this.myGroup.setCurLayer( "foreground" );

				this.editContext.setCurLayer( this.myGroup.landGroup.gameData.getFGLayer() );
				
			} else if ( e.target == this.btnLayer.btnBg ) {
				
				this.myGroup.shellApi.track( "Clicked", "Background", null, LandGroup.CAMPAIGN );
				
				this.btnLayer.btnFg.hilite.visible = false;
				this.btnLayer.btnBg.hilite.visible = true;
				
				this.myGroup.setCurLayer( "background" );
				
			} //
			
		} //
		
		/**
		 * make the game select the layer thats hilited in the land menu.
		 */
		public function pickSelectedLayer():void {
			
			if ( this.btnLayer.btnFg.hilite.visible ) {
				this.myGroup.setCurLayer( "foreground" );
			} else {
				this.myGroup.setCurLayer( "background" );
			} //
			
		} //
		
		// whatever. sort of the default layer setting. kind of a bad place for this.
		protected function setCurrentLayer( layer:TileLayer ):void {
			
			if ( this.editContext.curLayer == layer ) {			// nothing changed.
				return;
			}
			
			if ( layer.name == "foreground" ) {
				this.btnLayer.btnFg.hilite.visible = true;
				this.btnLayer.btnBg.hilite.visible = false;
			} else {
				this.btnLayer.btnBg.hilite.visible = true;
				this.btnLayer.btnFg.hilite.visible = false;
			} //
			
			this.editContext.curLayer = layer;
			
		} //

		/**
		 * destroy actually removes the button from the pane as well.
		 */
		private function removeButton( clip:MovieClip, destroy:Boolean=true ):void {

			for( var i:int = this.myButtons.length-1; i >= 0; i-- ) {

				if ( this.myButtons[i] == clip ) {

					this.myButtons[i] = this.myButtons[ this.myButtons.length-1 ];
					this.myButtons.pop();
					break;

				} //

			} // end for-loop.
			
			this.myGroup.inputManager.removeListeners( clip );
			this.myGroup.sharedTip.removeToolTip( clip );
			
			if ( clip.parent ) {
				clip.parent.removeChild( clip );
			}
			
		} //
		
		private function addUIButton( clip:MovieClip, mouseChildren:Boolean=false ):void {
			
			clip.mouseChildren = mouseChildren;
			
			if ( clip.hilite ) {
				clip.hilite.mouseEnabled = clip.hilite.mouseChildren = false;
				clip.hilite.visible = false;
			}
			
			var tipTarget:SharedTipTarget = this.myGroup.sharedTip.addClipTip( clip );
			tipTarget.rollOverFrame = 2;
			
			this.myButtons.push( clip );
			
		} //
		
		public function get visible():Boolean {
			return this.myPane.visible;
		}
		
		public function set visible( b:Boolean ):void {
			
			this.myPane.visible = b;
			
			if ( b ) {
				
				// enable the pane clicks to take background clicks.
				this.myPane.mouseChildren = this.myPane.mouseEnabled = true;
				
			} else {
				
				this.myPane.mouseChildren = this.myPane.mouseEnabled = false;
				
			} //
			
		} // set visible()
		
		public function destroy():void {

			this.myButtons.length = 0;
			if ( this.slideTween ) {
				this.slideTween.kill();
				this.slideTween = null;
			}
			
		} // destroy()
		
	} // class
	
} // package