package game.scenes.lands.shared.components {
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	
	public class LandHiliteComponent extends Component {

		public const RED_HILITE:int = 0xEE0000;
		public const WHITE_HILITE:int = 0xFFFFFF;

		/**
		 * displays hilite grid lines; doesnt belong here.
		 */
		public var tileGrid:Shape;

		/**
		 * the red hiliteBox that hilites the current tile, or the outline of a selected decal or template.
		 */
		public var hiliteBox:Shape;

		/**
		 *
		 * this is the rect currently hilited by the editing hilite, in tile map coordinates (offset from scene 0,0)
		 */
		public var hiliteRect:Rectangle;

		/**
		 * the current color of the hiliteBox
		 */
		public var hiliteColor:int;

		/**
		 * current square size of the tile grid - should be the size of the selected tileMap.
		 */
		public var gridSize:int;

		/**
		 * if true, the hilite automatically updates its position and hiliteRect on screen.
		 * if false, the hilite will not update automatically - as when selecting a template to save.
		 */
		public var autoUpdate:Boolean = true;

		public function LandHiliteComponent( _parent:DisplayObjectContainer, mapOffsetX:int ) {

			super();

			this.hiliteRect = new Rectangle();

			this.createEditGrid( _parent, mapOffsetX );

		} //

		public function setHiliteColor( newColor:int ):void {

			this.hiliteColor = newColor;
			this.redrawHilite();
			
		} //

		public function hideHilite():void {
			this.hiliteBox.visible = false;
		}

		public function showHilite():void {
			this.hiliteBox.visible = true;
		}

		public function redrawGrid( tileSize:int, rows:int, cols:int ):void {

			if ( this.gridSize == tileSize ) {
				return;
			}

			this.gridSize = tileSize;

			var g:Graphics = this.tileGrid.graphics;
			g.clear();
			
			var maxX:Number = cols*tileSize;
			var maxY:Number = rows*tileSize;
			
			g.lineStyle( 2, 0, 0.15 );
			g.drawRect( 0, 0, maxX, maxY );

			// vertical lines.
			for( var i:int = cols-1; i >= 1; i-- ) {

				g.moveTo( i*tileSize, 0 );
				g.lineTo( i*tileSize, maxY );

			} // for-loop.

			// vertical lines.
			for( i = rows-1; i >= 1; i-- ) {

				g.moveTo( 0, i*tileSize );
				g.lineTo( maxX, i*tileSize );

			} // for-loop.

		} // redrawGrid()

		/**
		 * draw the hilite as the rect between points p1 and p2.
		 */
		public function setRectPoints( p1:Point, p2:Point ):void {

			if ( p1.x <= p2.x ) {
				this.hiliteRect.x = p1.x;
				this.hiliteRect.right = p2.x;
			} else {
				this.hiliteRect.x = p2.x;
				this.hiliteRect.right = p1.x;
			} //
			
			if ( p1.y <= p2.y ) {
				this.hiliteRect.y = p1.y;
				this.hiliteRect.bottom = p2.y;
			} else {
				this.hiliteRect.y = p2.y;
				this.hiliteRect.bottom = p1.y;
			} //
			
		} //

		/**
		 * used to set the hilite to a square brush size.
		 */
		public function setBrushSize( base_size:int ):void {

			if ( this.hiliteRect.width == base_size && this.hiliteRect.height == base_size ) {
				return;
			}

			this.hiliteRect.width = this.hiliteRect.height = base_size;
			this.redrawHilite();

		} //

		public function redrawHilite():void {

			var g:Graphics = this.hiliteBox.graphics;
			
			g.clear();
			g.lineStyle( 2, this.hiliteColor );
			g.drawRect( 0, 0, this.hiliteRect.width, this.hiliteRect.height );
			
		} //

		/**
		 * Creates the edit grid that shows up over the tiles, along with the hilight box
		 * that hilights the tile under the mouse.
		 */
		private function createEditGrid( _parent:DisplayObjectContainer, mapOffsetX:int ):void {
			
			this.tileGrid = new Shape();
			
			// align the edit grid to the tileMap coordinate system.
			this.tileGrid.x = mapOffsetX;
			this.tileGrid.visible = false;
			
			_parent.addChild( this.tileGrid );
			
			this.hiliteBox = new Shape();
			
			_parent.addChild( this.hiliteBox );
			this.hiliteBox.visible = false;
			
		} // createEditGrid()

	} // class
	
} // package