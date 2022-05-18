package game.scenes.lands.shared.classes {

	import flash.display.Graphics;
	import flash.display.Shape;
	
	import game.scenes.lands.shared.tileLib.tileSets.TileSet;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class LandBlob {

		public var blobSize:int;

		public var shape:Shape;
		public var type:TileType;

		public var vx:Number;
		public var vy:Number;

		public function LandBlob( tileType:TileType, tileSet:TileSet, size:int ) {

			this.type = tileType;

			this.blobSize = size;

			this.shape = new Shape();
			this.drawBlob( this.shape, tileType, tileSet.setType );

		} //

		private function drawBlob( s:Shape, tileType:TileType, setType:String ):void {

			var g:Graphics = s.graphics;

			if ( tileType.viewBitmapFill == null ) {
				return;
			}

			// draw an outline.
			g.lineStyle( 1.5, 0, 0.5 );
			g.beginBitmapFill( tileType.viewBitmapFill );

			if ( setType == "natural" ) {
				g.drawCircle( this.blobSize/2, this.blobSize/2, this.blobSize/2-2 );
			} else {
				g.drawRect( 1, 1, this.blobSize-2, this.blobSize-2 );
			} //

			// draw the background onto the clip bitmap.
			g.endFill();

		} //

	} // class

} // package