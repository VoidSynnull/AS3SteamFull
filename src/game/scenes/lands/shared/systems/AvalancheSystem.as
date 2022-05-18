package game.scenes.lands.shared.systems {

	/**
	 *
	 * testing out a little effect...
	 *
	 */

	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.System;
	
	import game.scene.template.PlatformerGameScene;
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandBlob;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class AvalancheSystem extends System {

		private var blobs:Vector.<LandBlob>;

		private var tileMap:TileMap;
		private var tileLayer:TileLayer;
		private var gameData:LandGameData;
		private var mapOffsetX:int;

		private var container:DisplayObjectContainer;

		private var createCount:int;
		private var sourceX:int;
		private var sourceY:int;

		public function AvalancheSystem( landGroup:LandGroup ) {

			super();

			landGroup.onBiomeChanged.add( this.biomeChanged );
			landGroup.onLeaveScene.add( this.removeAll );

			this.gameData = landGroup.gameData;
			this.tileMap = this.gameData.getTerrainMap();
			this.mapOffsetX = this.gameData.mapOffsetX;

			this.tileLayer = this.gameData.getFGLayer();

		} //

		override public function update( time:Number ):void {

			if ( this.createCount > 0 && Math.random() < 0.2 ) {
				this.createBlob();
			} else if ( this.blobs == null || this.blobs.length == 0 ) {
				return;
			}

			var blob:LandBlob;
			var s:Shape;

			var nx:Number;
			var ny:Number;

			var tile:LandTile;

			for( var i:int = this.blobs.length-1; i >= 0; i-- ) {

				blob = blobs[i];
				s = blob.shape;

				nx = s.x + blob.vx*time;
				ny = s.y + blob.vy*time;

				tile = this.tileMap.getTileAt( nx - this.mapOffsetX, ny );

				if ( tile == null || tile.type == 0 ) {

					if ( ny > 3000 ) {

						this.container.removeChild( s );
						blob.shape = null;
						blob.type = null;
						
						this.blobs[i] = this.blobs[ this.blobs.length-1 ];
						this.blobs.pop();

					} else {

						s.x = nx;
						s.y = ny;

						blob.vy += 500*time;

					} //

				} else {

					// something is in the way of the blob. set it to where it is now.
					tile = this.tileMap.getTileAt( s.x - this.mapOffsetX, s.y );

					if ( tile != null ) {

						// this won't allow mixed types to overlay.
						tile.type = blob.type.type;

						var size:Number = this.tileMap.tileSize;
						this.tileLayer.renderArea( new Rectangle( tile.col*size, tile.row*size, size, size ) );

					} //

					this.container.removeChild( s );
					blob.shape = null;
					blob.type = null;

					this.blobs[i] = this.blobs[ this.blobs.length-1 ];
					this.blobs.pop();

				} //

			} // for-loop.

		} //

		/**
		 * get the new tile map after the biome changes.
		 */
		public function biomeChanged():void {

			this.tileMap = gameData.tileMaps["terrain"];

		} //

		public function removeAll():void {

			var blob:LandBlob;
			for( var i:int = this.blobs.length-1; i >= 0; i-- ) {

				blob = this.blobs[i];
				this.container.removeChild( blob.shape );
				blob.shape = null;
				blob.type = null;

			} //

			this.blobs.length = 0;

		} //

		private function createBlob():void {

			var types:Vector.<TileType> = this.tileMap.tileSet.tileTypes;

			var blob:LandBlob = new LandBlob( types[ Math.floor( Math.random()*types.length ) ], this.tileMap.tileSet, this.tileMap.tileSize );
			blob.shape.x = this.sourceX - 128 + 256*Math.random();
			blob.shape.y = this.sourceY;

			blob.vx = -100 + 200*Math.random();
			blob.vy = 256;

			this.container.addChild( blob.shape );

			this.blobs.push( blob );

			this.createCount--;

		} //

		public function beginAvalanche( x:int, y:int ):void {

			this.sourceX = x;
			this.sourceY = y;

			this.createCount = 12;

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.blobs = new Vector.<LandBlob>();

			this.container = ( ( this.group as LandGroup ).parent as PlatformerGameScene ).hitContainer;

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			this.blobs.length = 0;

		} //

	} // End class

} // End package