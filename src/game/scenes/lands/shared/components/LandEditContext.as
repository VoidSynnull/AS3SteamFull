package game.scenes.lands.shared.components {

	import ash.core.Component;
	
	import game.scenes.lands.shared.classes.LandEditMode;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;
	
	import org.osflash.signals.Signal;

	public class LandEditContext extends Component {

		/**
		 * onEditModeChanged( mode:uint )
		 * called when the curEditMode is changed.
		 */
		public var onEditModeChanged:Signal;

		/**
		 * onTileTypeChanged( newType:TileType )
		 */
		//public var onTileTypeChanged:Signal;

		/**
		 * Layer being painted/edited in edit/paint mode.
		 */
		public var curLayer:TileLayer;
		/**
		 * tile type being painted in edit/paint mode.
		 */
		public var curTileType:TileType;
		/*public function get curTileType():TileType {
			return this._curTileType;
		}
		public function set curTileType( type:TileType ):void {

			if ( type == this._curTileType ) {
				return;
			}
			this._curTileType = type;
			this.onTileTypeChanged.dispatch( type );

		} //*/

		/**
		 * only (currently) used for decals. if true, indicates the decal being placed should be flipped horizontally.
		 */
		public var flipped:Boolean;

		/**
		 * the current tile map is a bit confusing because it pulls too many duties.
		 * 
		 * in edit mode, this is the tileMap of the tileType being painted/edited on screen.
		 * in mining mode, this is the tileMap of the tileType that has mouse focus for destroying tiles.
		 */
		public var curTileMap:TileMap;

		public var curTileSize:int;

		/**
		 * true when land is in the process of being created or destroyed - including mining.
		 */
		public var isPainting:Boolean;

		/**
		 * save whether the brush is large so that when a tile size changes, you know
		 * whether to set the brush to 2x or 1x the tile size.
		 * Need to get rid of this mechanic really. I don't like it.
		 */
		public var useLargeBrush:Boolean = false;

		/**
		 * true if in edit mode but deleting tiles.
		 */
		public var toggleDelete:Boolean;

		/**
		 *
		 * this is the rect currently hilited by the editing hilite, in tile map coordinates (offset from 0,0)
		 * MOVED TO LandHiliteComponent
		 */
		//public var hiliteRect:Rectangle;

		/**
		 * lack of a better place to put this at the moment. How long to delay character movement due
		 * to destroying tiles. there has to be SOME delay, or else the player will instantly
		 * to move/jump to a tile after it's been destroyed.
		 */
		public var charMoveDelay:uint = 0;


		private var _curEditMode:uint;
		[Inline]
		final public function get curEditMode():uint {
			return this._curEditMode;
		}

		[Inline]
		final public function set curEditMode( newMode:uint ):void {

			if ( newMode == this._curEditMode ) {
				return;
			}

			this._curEditMode = newMode;
			this.onEditModeChanged.dispatch( newMode );

		} //

		public function LandEditContext() {

			//this.onTileTypeChanged = new Signal( TileType );
			this.onEditModeChanged = new Signal( uint );
			this.curEditMode = LandEditMode.PLAY;

		} //

		/**
		 * use a typeSelector to set the curTileType and curTileMap.
		 */
		/*public function setTypeSelector( sel:TypeSelector ):void {

			if ( this.curLayer ) {

				this.curTileType = sel.tileType;

				// get the tileMap with the given tileSet.
				this.setCurTileMap( this.curLayer.getMapWithSet( sel.tileSet ) );

			} //

		} //*/

		public function setCurLayer( layer:TileLayer ):void {

			this.curLayer = layer;

			// get the closest tile map to the previous one.
			if ( this.curTileMap != null ) {

				this.curTileMap = this.curLayer.getMapWithSet( this.curTileMap.tileSet );
				if ( this.curTileMap == null ) {
					this.curTileType = null;
				}

			} //

		} //

		/**
		 * change the tileMap without actually the current tile type.
		 * This doesn't update the curTileSet used for editing, which can be done separately,
		 * or the tileMap can just be changed to change which tileMap gets erased.
		 */
		public function setCurTileMap( tileMap:TileMap ):void {

			this.curTileSize = tileMap.tileSize;
			this.curTileMap = tileMap;

		} //

		public function getCurBrushSize():int {

			if ( this.useLargeBrush ) {
				return 2*this.curTileSize;
			} else {
				return this.curTileSize;
			}

		}

	} // class

} // package
