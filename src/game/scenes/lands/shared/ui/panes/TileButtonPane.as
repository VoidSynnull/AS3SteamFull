package game.scenes.lands.shared.ui.panes {

	/**
	 * 
	 * represents a pane of buttons in rows, cols from which tile types can be selected
	 * possibly in the future - templates as well.
	 * 
	 */

	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import engine.util.Command;
	
	import game.scenes.lands.shared.classes.ObjectIconPair;
	import game.scenes.lands.shared.classes.TypeSelector;
	import game.scenes.lands.shared.groups.LandUIGroup;
	import game.scenes.lands.shared.tileLib.classes.LandProgress;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.ClipTileType;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;
	import game.scenes.lands.shared.ui.TileTypeButton;

	public class TileButtonPane extends LandPane {

		/**
		 * padding between buttons.
		 */
		private const PADDING:int = 6;

		/**
		 * tileClickFunc( typeSelector:TypeSelector, btnIcon:BitmapData, isFlipped:Boolean )
		 * icon needs to be passed so the bitmap data isn't duplicated. in future store this in the tiletype itself?
		 */
		private var tileClickFunc:Function;

		private var _buttonSize:int;

		private var _curSelectedIndex:int;

		private var progress:LandProgress;

		public function TileButtonPane( pane:Sprite, group:LandUIGroup, onTileClick:Function, buttonSize:int ) {

			super( pane, group );

			this.progress = this.myGroup.gameData.progress;

			this.tileClickFunc = onTileClick;
			this._buttonSize = buttonSize;

			this.progress.onLevelUp.add( this.onLevelUp );
			this.progress.onLevelChanged.add( this.onLevelChanged );

		} //

		/**public function onScrollViewChanged( viewRect:Rectangle ):void {
		}**/

		public function flipTiles():void {
			
			var btn:DisplayObjectContainer;
			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				btn = this.buttons[i];
				btn.scaleX = -btn.scaleX;
				if ( btn.scaleX < 0 ) {
					btn.x += btn.width;
				} else {
					btn.x -= btn.width;
				}

			} // for-loop

		} //

		/**
		 * remove all buttons - used when the biomes change and the available tile types are different.
		 */
		public function removeAllButtons():void {

			var btn:TileTypeButton;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				btn = this.buttons[i] as TileTypeButton;
				if ( btn && btn.parent ) {

					this.sharedToolTip.removeToolTip( btn );
					this.inputManager.removeListeners( btn );
					btn.parent.removeChild( btn );

					btn.destroy();

				} //

			} // for-loop.

			this.buttons.length = 0;

		} //

		/**
		 * The player's level just jumped to new value, maybe higher or lower,
		 * possibly because of a game or database load. all the buttons have to be checked for
		 * their new state.
		 */
		private function onLevelChanged( newLevel:int ):void {

			// we could do complicated checks here, but just redraw everything to be absolutely sure.
			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				this.tryDrawButton( this.buttons[i] as TileTypeButton, newLevel );

			} // for-loop.

		} //

		/**
		 * unlocked types provided are ignored because it doesn't make the loop below any easier.
		 */
		private function onLevelUp( newLevel:int, unlocked:Vector.<ObjectIconPair> ):void {

			var btn:TileTypeButton;
			var selector:TypeSelector;

			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				btn = this.buttons[i] as TileTypeButton;
				selector = btn.typeSelector;

				if ( selector == null ) {

					trace( "TileButtonPane: unknown selector." );

				} else if ( selector.tileType.level < newLevel ) {

					// tiles are sorted in-order so once the tile levels are lower than the current level,
					// all the remaining buttons are up to date.
					break;

				} else {

					this.tryDrawButton( btn, newLevel );

				} //

			} // for-loop.

		} //

		/**
		 * Initialize all the tile type buttons that this button pane will display.
		 * setType gives the name of the set type (natural, building, etc ) that this pane displays
		 * other tile sets are ignored.
		 */
		public function makeTileButtons( setType:String, row_width:int ):void {

			// land and terrain tiles might be distributed over several sets...
			var btnX:Number = 0;
			var btnY:Number = 0;

			var sets:Dictionary = this.myGroup.gameData.tileSets;

			var btn:Sprite;
			var curSel:TypeSelector;

			var tileSelectors:Vector.<TypeSelector> = new Vector.<TypeSelector>();

			// loop through the tileTypes in each set, making a button for each tile type.
			// before the buttons are made however, the types have to be sorted by required level.
			// this first loop does that.
			for each ( var tset:TileSet in sets ) {

				if ( tset.setType == setType ) {
					this.addTypeSelectors( tileSelectors, tset );
				}

			} // end tileSet loop.

			// now place the tile type buttons on the pane.
			var len:int = tileSelectors.length;
			for( var i:int = 0; i < len; i++ ) {

				curSel = tileSelectors[i];

				btn = this.makeTypeButton( curSel, btnX, btnY );

				btnX += ( this._buttonSize + this.PADDING );
				if (btnX + this._buttonSize > row_width ) {
					btnX = 0;
					btnY += ( this._buttonSize + this.PADDING );
				}

			} // end for-loop.

		} // makeTileButtons()

		/**
		 * adds TypeSelectors for every tileType in the given tileSet to the selector list.
		 * The selector list is the list used to create buttons for every tileType.
		 * the list has to be formed before the buttons are created so they can be sorted by tileType level.
		 * 
		 * sorting is done with TypeSelector instead of tileTypes because the parent-set information needs to be preserved.
		 */
		private function addTypeSelectors( tiles:Vector.<TypeSelector>, tileSet:TileSet ):void {

			var addTiles:Vector.<TileType> = tileSet.tileTypes;

			var insertTile:TileType;

			var insertSel:TypeSelector;
			var nextSel:TypeSelector;

			// place where tile insertion starts - tiles max (which grows with each insert)
			var baseInsert:int = tiles.length;
			tiles.length += addTiles.length;

			for( var k:int = addTiles.length-1; k >= 0; k-- ) {

				insertTile = addTiles[ k ];
				if ( insertTile == null || insertTile.allowEdit == false ) {
					tiles.pop();
					continue;
				}

				insertSel = new TypeSelector( insertTile, tileSet );

				for( var insertIndex:int = baseInsert; insertIndex >= 1; insertIndex-- ) {

					nextSel = tiles[ insertIndex - 1 ];
					if ( nextSel.tileType.level < insertTile.level ) {
						break;
					} else if ( nextSel.tileType.level == insertTile.level ) {

						// if same level, sort by id - for lack of a better idea.
						if ( nextSel.tileType.type < insertTile.type ) {
							break;
						}

					} //

					tiles[ insertIndex ] = nextSel;

				} //

				tiles[ insertIndex ] = insertSel;
				baseInsert++;

			} // for-loop.

		} // addTypeSelectors()

		private function tileClicked( evt:MouseEvent ):void {

			var btn:TileTypeButton = evt.target as TileTypeButton;
			if ( btn == null ) {
				return;
			}

			if ( btn.typeSelector ) {
				this.tileClickFunc( btn.typeSelector, btn.bitmap.bitmapData, (btn.scaleX < 0) );
			} //

		} //

		override public function show():void {

			super.show();

			var btn:TileTypeButton;

			// attempt to load and draw any buttons that haven't had their images loaded yet.
			for( var i:int = this.buttons.length-1; i >= 0; i-- ) {

				btn = this.buttons[i] as TileTypeButton;

				if ( !btn.iconIsCurrent ) {
					this.tryDrawButton( btn, this.progress.curLevel );
				}

			} // for-loop.

		} //

		/**
		 * Make a select tileType button for the given tile type, from the specified tile set.
		 */
		protected function makeTypeButton( typeSel:TypeSelector, x:Number=0, y:Number=0 ):Sprite {

			var btn:TileTypeButton = new TileTypeButton( this._buttonSize, typeSel );

			btn.x = x;
			btn.y = y;
			this.myPane.addChild( btn );					// all buttons start invisible.			
			this.makeButton( btn, this.tileClicked );		// set up the events.

			if ( typeSel.tileType.image != null ) {
				btn.redrawButton( this.progress.curLevel );
			}

			return btn;

		} //

		protected function tryDrawButton( btn:TileTypeButton, level:int ):void {

			if ( !btn.tryRedrawButton( this.progress.curLevel ) ) {

				btn.addLoadIcon( this.myGroup );

				// currently only clip tile types can late-load.
				var clipType:ClipTileType = btn.typeSelector.tileType as ClipTileType;

				if ( clipType ) {
					// button tileType resources not loaded.
					this.myGroup.assetLoader.loadSingleDecal( clipType,
						Command.create( this.tileTypeLoaded, btn ) );
				}

			} //

		} //

		/**
		 * redraw a button whose tileType finished loading resources.
		 */
		protected function tileTypeLoaded( btn:TileTypeButton ):void {

			btn.removeLoadIcon();
			btn.redrawButton( this.progress.curLevel );

		} //

	} // class

} // package