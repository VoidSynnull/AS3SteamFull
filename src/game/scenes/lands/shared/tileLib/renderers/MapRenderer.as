package game.scenes.lands.shared.tileLib.renderers {

	/**
	 * MapView is the super class for displaying a TileMap. Different subclasses can display
	 * the tiles in different ways by overriding the 'render()' function.
	 * 
	 * For example: BasicTileView extends MapView to do a very basic tile display.
	 *				CurveView extends MapView to draw curvey lines around the tiles.
	 */
	
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.painters.RenderContext;
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;

	public class MapRenderer {

		protected var tileMap:TileMap;

		/**
		 * optional to set but used by many subclasses.
		 */
		protected var tileSet:TileSet;

		protected var renderContext:RenderContext;

		public var tileSize:int = 32;

		public function MapRenderer( map:TileMap, rc:RenderContext=null ) {

			this.tileMap = map;
			this.tileSize = map.tileSize;

			this.tileSet = map.tileSet;

			if ( rc ) {
				this.renderContext = rc;
			}

		} //

		/**
		 * Subclasses can override this function to change the way the land tiles are displayed.
		 */
		public function render():void {
		} //

		/**
		 * - eraseRect is the rect area that was just erased and must be redrawn.
		 * 
		 * because redrawing one tile might affect nearby tiles as well, the actual area redrawn has to extend
		 * fairly far beyond the tile itself. eraseRect is the area erased which must be filled, and drawing
		 * should extend beyond this area to make sure there are no sharp edges.
		 */
		public function renderArea( eraseRect:Rectangle ):void {
		}

		public function renderable( tile:LandTile ):Boolean {

			if ( ( this.tileSet.getTypeByCode(tile.type) == null) ) {
				return false;
			}

			return true;

		} //

		/**
		 * Sets which map of land tiles to use.
		 */
		public function setTileMap( map:TileMap ):void {

			this.tileMap = map;
			this.tileSize = map.tileSize;

		} //

		/**
		 * 
		 * temporary function till I figure a better way to do this.
		 * Render the data from a template using the given view. The tileSet, tileSize data doesn't change.
		 * 
		 */
		public function prepareTemplate( templateMap:TileMap, templateView:BitmapData ):void {

			this.tileMap = templateMap;

		} //

		public function setRenderContext( rc:RenderContext ):void {
			
			this.renderContext = rc;
			
		} //
		
		public function destroy():void {
		} //

		/**
		 * subclasses can override this function to create any display objects
		 * they need to render their type of land map.
		 */
		/*protected function initRenderViews():void {
		} //*/

	} // End TileRenderer

} // End package