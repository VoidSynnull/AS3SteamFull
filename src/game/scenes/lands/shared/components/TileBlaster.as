package game.scenes.lands.shared.components {

	import ash.core.Component;
	
	import game.scenes.lands.shared.classes.TileSelector;
	import game.scenes.lands.shared.particles.TileBlastEffect;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;
	
	import org.osflash.signals.Signal;

	public class TileBlaster extends Component {

		/**
		 * might change this to have more blast options.
		 */
		public var blastTiles:Vector.<TileSelector>;

		/**
		 * onTileBlasted( LandTile, TileType, TileMap );
		 * basically unpacks the tile selector for convenience.
		 * 
		 */
		public var onTileBlasted:Signal;

		/**
		 * set by the TileBlastSystem. used for immediate blasts without going into a queue.
		 */
		public var blaster:TileBlastEffect;

		public function TileBlaster() {

			this.blastTiles = new Vector.<TileSelector>();
			this.onTileBlasted = new Signal( LandTile, TileType, TileMap );

		} //

		/**
		 * a small crumble effect while tiles are in the process of being destroyed,
		 * being walked on, etc.
		 */
		public function crumble( type:TileType, x:Number, y:Number ):void {
			
			this.blaster.bitmap = type.colorBitmap;
			
			this.blaster.setParticleScale( 0.4, 1 );
			this.blaster.randomBlast( 0.2, 1 );
			this.blaster.setBlastCenter( x, y );
			this.blaster.start();

		} //

		/**
		 * immediate blast tile without queue.
		 */
		public function blastTile( tile:LandTile, type:TileType, map:TileMap ):void {

			this.blaster.bitmap = type.colorBitmap;

			this.blaster.setParticleScale( 0.5, 2 );
			this.blaster.setBlastCenter( (tile.col+0.5)*map.tileSize, (tile.row+0.5)*map.tileSize );
			this.blaster.setCount( 6 );

			this.blaster.start();

			tile.type &= ~type.type;

			this.onTileBlasted.dispatch( tile, type, map );

		} //

		/**
		 * performs an immediate particle blast at the given location.
		 * tile is not destroyed.
		 */
		/*public function blastTypeAt( type:TileType, x:Number, y:Number ):void {

			this.blaster.bitmap = type.colorBitmap;

			this.blaster.setParticleScale( 0.5, 2 );
			this.blaster.setBlastCenter( x, y  );
			this.blaster.setCount( 6 );
			
			this.blaster.start();

		} //*/

		/**
		 * adds tile blast to front of the list - blast occurs even for "unbreakable" tile types.
		 */
		public function addImmediate( tile:TileSelector ):void {

			this.blastTiles.unshift( tile );

		} //

		public function addTile( tile:TileSelector ):void {

			if ( !tile.tileType.unbreakable ) {
				this.blastTiles.push( tile );
			}

		} //

	} // class

} // package