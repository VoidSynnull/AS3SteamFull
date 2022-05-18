package game.scenes.lands.shared.tileLib.tileTypes {

	import flash.display.IBitmapDrawable;
	import flash.utils.Dictionary;

	/**
	 * TerrainTileTypes need a lot of data that tells how tiles of this type are drawn onto the screen.
	 * This includes the bitmap fill to use, if any, outline stroke sizes, outline stroke colors,
	 * hit strokes sizes, and hilite information.
	 * 
	 */
	public class TerrainTileType extends TileType {
		
		/**
		 * How steep a land incline has to be before it becomes a wall.
		 */
		public const WallSlope:Number = Math.tan( 64*Math.PI/180 );

		/**
		 * new method of storing details.
		 */
		public var details:Dictionary;

		/**
		 * Thickness of hilite drop shadow.
		 * move these to a subclass that's only created if hilite exists.
		 */
		public var hiliteSize:int = 24;
		public var hiliteAngle:int = 90;
		public var hiliteAlpha:Number = 0.09;

		public var useHilite:Boolean = false;

		public function TerrainTileType() {
		} //

		override public function get image():IBitmapDrawable {

			return this.viewBitmapFill;

		}

		override public function destroy():void {

			super.destroy();

			this.details = null;

		} //

	} // class

} // package