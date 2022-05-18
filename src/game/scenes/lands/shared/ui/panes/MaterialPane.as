package game.scenes.lands.shared.ui.panes {

	/**
	 * this class controls the material selection pane of the LandEditMenu.
	 * 
	 * this pane has 3 sections: terrain tiles, building tiles, and decals.
	 * later it will also have template selections.
	 * 
	 * it also has a scrollbar.
	 * 
	 * note that the clip in the ui is actually "materialPanel" right now.
	 * 
	 */

	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.TypeSelector;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;
	import game.scenes.lands.shared.ui.TileTypeButton;

	public class MaterialPane extends LandPane {

		/**
		 * this is a scrollbar. it's a thing.
		 */
		private var scrollBar:ScrollBarPane;

		/**
		 * subpanes with the buttons for each type.
		 */
		private var terrainPane:TileButtonPane;
		private var buildingPane:TileButtonPane;
		private var decalPane:TileButtonPane;

		/**
		 * pane currently visible.
		 */
		private var currentPane:TileButtonPane;

		/**
		 * onSelectTile( TypeSelector )
		 */
		private var onTypeSelected:Function;

		/**
		 * the rectangle of the area where the tiles should be visible - also indicates
		 * where the tiles should be placed onscreen.
		 */
		//private var viewRect:Rectangle;

		/**
		 * contains all the sub-tile panes. need this to get scrolling to work right.
		 */
		private var viewPane:Sprite;

		private var btnFlipDecal:MovieClip;

		/**
		 * dispatch when pane opens. this is absolutely useless except for campaigns which
		 * need to know when the pane is opened. nothing else uses it.
		 */
		public var onOpenPane:Function;

		/**
		 * pointless callback just for ad plugins.
		 */
		public var onCategoryClicked:Function;

		/**
		 * selectFunc is the function called when a tile type is selected in the pane.
		 */
		public function MaterialPane( pane:MovieClip, group:LandUIGroup, closeFunc:Function=null ) {

			super( pane, group );

			this.myPane.mouseEnabled = false;

			// stop on first frame.
			pane.gotoAndStop( 1 );

			this.makeViewPane();
			this.initButtons( closeFunc );
			this.initTilePanes();

		} //

		/**
		 * set the function called when a tile type is selected.
		 */
		public function setSelectFunc( selectFunc:Function ):void {
			this.onTypeSelected = selectFunc;
		} //

		/**
		 * all the individual tile button panes are in a single view pane so they can be scrolled.
		 */
		private function makeViewPane():void {

			var viewClip:SimpleButton = this.clipPane.viewRect;
			viewClip.visible = false;
			viewClip.mouseEnabled = false;

			this.viewPane = new Sprite();
			this.myPane.addChild( this.viewPane );
			this.viewPane.x = viewClip.x;
			this.viewPane.y = viewClip.y;
			this.viewPane.scrollRect = new Rectangle( 0, 0, viewClip.width, viewClip.height );

			this.viewPane.mouseEnabled = false;

		} //

		private function initButtons( closeFunc:Function ):void {

			this.scrollBar = new ScrollBarPane( this.clipPane.scrollBar, this.myGroup, this.viewPane.scrollRect );
			this.scrollBar.hide();

			var btn:MovieClip = this.clipPane.btnTerrain;
			this.makeButton( btn, this.selectPaneClicked );

			btn = this.clipPane.btnBuilding;
			this.makeButton( btn, this.selectPaneClicked );

			btn = this.clipPane.btnDecal;
			this.makeButton( btn, this.selectPaneClicked );

			this.btnFlipDecal = btn = this.clipPane.btnFlipDecal;
			this.makeButton( btn, this.flipDecalsClicked );
			btn.gotoAndStop( 1 );
			btn.visible = false;

			btn = this.clipPane.btnClose;
			if ( closeFunc ) {
				this.makeButton( btn, closeFunc );
			} else {
				this.makeButton( btn, this.closeClick );
			}

		} //

		private function makeSpritePane():Sprite {

			var s:Sprite = new Sprite();
			this.viewPane.addChild( s );
			//this.myPane.addChild( s );

			s.x = 0;//this.viewRect.x;
			s.y = 0;//this.viewRect.y;

			return s;

		} //

		private function initTilePanes():void {

			// might move this.. somewhere..anywhere.
			TileTypeButton.LockBitmap = this.myGroup.lockBitmap;

			var pane:Sprite = this.makeSpritePane();
			this.terrainPane = new TileButtonPane( pane, this.myGroup, this.tileSelected, 52 );

			pane = this.makeSpritePane();
			this.buildingPane = new TileButtonPane( pane, this.myGroup, this.tileSelected, 52 );

			pane = this.makeSpritePane();
			this.decalPane = new TileButtonPane( pane, this.myGroup, this.tileSelected, 80 );

			this.currentPane = this.terrainPane;
			this.scrollBar.setScrollTarget( this.currentPane.pane );

		} //

		public function resetTileButtons():void {

			var paneWidth:int = this.viewPane.scrollRect.width;

			this.terrainPane.makeTileButtons( "natural", paneWidth );
			this.buildingPane.makeTileButtons( "building", paneWidth );
			this.decalPane.makeTileButtons( "decal", paneWidth );

		} //

		private function tileSelected( typeSel:TypeSelector, icon:BitmapData, flipped:Boolean=false ):void {

			this.myGroup.shellApi.track( "Clicked", typeSel.tileType.name, null, LandGroup.CAMPAIGN );

			var tileType:TileType = typeSel.tileType;
			if ( !tileType ) {
				return;
			}

			if ( this.onTypeSelected ) {
				this.onTypeSelected( typeSel, icon, flipped );
			}

		} //

		override public function show():void {

			this.scrollBar.show();
			super.show();
			this.currentPane.show();

			if ( this.onOpenPane ) {
				this.onOpenPane();
			}

		} //

		override public function hide():void {

			this.scrollBar.hide();
			this.currentPane.hide();
			super.hide();

		} //

		private function flipDecalsClicked( e:MouseEvent ):void {

			if ( this.btnFlipDecal.currentFrame == 1 ) {

				this.btnFlipDecal.gotoAndStop( 2 );

			} else {

				this.btnFlipDecal.gotoAndStop( 1 );

			} //
			this.decalPane.flipTiles();

		} //

		private function selectPaneClicked( e:MouseEvent ):void {

			var btn:MovieClip = e.target as MovieClip;
			var nextPane:TileButtonPane;

			if ( btn == this.clipPane.btnTerrain ) {

				this.btnFlipDecal.visible = false;
				nextPane = this.terrainPane;
				this.clipPane.gotoAndStop( 1 );

			} else if ( btn == this.clipPane.btnBuilding ) {

				this.btnFlipDecal.visible = false;
				nextPane = this.buildingPane;
				this.clipPane.gotoAndStop( 2 );

			} else if ( btn == this.clipPane.btnDecal ) {

				this.btnFlipDecal.visible = true;
				nextPane = this.decalPane;
				this.clipPane.gotoAndStop( 3 );

			} //

			if ( nextPane && nextPane != this.currentPane ) {

				this.currentPane.hide();

				nextPane.show();
				this.scrollBar.setScrollTarget( nextPane.pane );
				this.currentPane = nextPane;

				if ( onCategoryClicked ) {
					onCategoryClicked();
				}

			} //

		} //

		/**
		 * remove all options on the menus when a biome has changed.
		 */
		public function removeAllTiles():void {

			this.terrainPane.removeAllButtons();
			this.buildingPane.removeAllButtons();
			this.decalPane.removeAllButtons();

		} //

		override public function destroy():void {

			this.buildingPane.destroy();
			this.terrainPane.destroy();
			this.decalPane.destroy();

			this.scrollBar.destroy();
			this.scrollBar = null;

			this.buildingPane = null;
			this.terrainPane = null;
			this.decalPane = null;

			super.destroy();

		} //

	} // class

} // package