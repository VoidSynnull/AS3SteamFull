package game.scenes.lands.shared.systems {

	/**
	 * tracks the tile currently hit by the player, if any.
	 * the system does not trigger any special hits - it only tracks the information in the HitTileComponent.
	 */
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.components.HitTileComponent;
	import game.scenes.lands.shared.nodes.LandColliderNode;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	import game.scenes.lands.shared.tileLib.tileTypes.TileType;

	public class LandHitSystem extends System {

		private var colliderNodes:NodeList;

		// tileMap offset from hit bitmap.
		private var tileOffsetX:int;

		/**
		 * currently only the foreground layer allows hits.
		 */
		private var hitLayer:TileLayer;

		public function LandHitSystem( hitLayer:TileLayer ) {

			super();

			this.hitLayer = hitLayer;

			this.tileOffsetX = hitLayer.getRenderContext().mapOffsetX;

		} //

		override public function update( time:Number ):void {

			var hitColor:uint;
			var hitTile:HitTileComponent;

			var tileMaps:Vector.<TileMap> = this.hitLayer.getMaps();
			if ( tileMaps == null ) {
				return;
			}

			for( var node:LandColliderNode = this.colliderNodes.head; node; node = node.next ) {

				if ( node.entity.sleeping ) {
					continue;
				}

				// before we even start, might want to check if the thing has even moved since last frame?

				hitColor = node.bitmapCollider.platformColor;				
				hitTile = node.hitTile;

				if ( hitColor == 0 ) {
					// it appears from the other systems, that this is synonymous with no-hit.
					hitTile.setTile( null, null, null );
					hitTile.hitChanged = false;

					continue;
				}

				// go through the tile maps and find a tile with a matching hit color
				// could make a different system that tracks the current tile at a given spatial?
				var tmap:TileMap;

				// need to first offset the hit by the tileMap offset.
				var tileX:Number = node.bitmapCollider.platformHitX - this.tileOffsetX;
				// add to the y-value since tile hits typically extend above the tile itself.
				var tileY:Number = node.bitmapCollider.platformHitY + node.edge.rectangle.bottom + 6;

				var tile:LandTile;

				// the high->low direction of this search is important because the highest tileMaps are drawn last, and so their
				// hits should be considered first.
				for( var i:int = tileMaps.length-1; i >= 0; i-- ) {

					tmap = tileMaps[i];
					if ( tmap.drawHits == false ) {
						continue;
					}

					tile = tmap.getTileAt( tileX, tileY );
					/*if ( tile != null && tile.type == 0 ) {
						//try the one below since tile hits stick out above their grid.
						// UPDATE: this breaks some traps and doesn't seem to be a big deal anyway.
						tile = tmap.getTile( tile.row+1, tile.col );
					}*/

					if ( tile != null && tile.type != 0 ) {

						var tileType:TileType = tmap.getType( tile );
						if ( tile == hitTile.tile && tileType == hitTile.tileType ) {

							// tile and type have not changed. no signal. note that a signal will be sent if the tileType
							// on the current tile has changed.
							hitTile.hitChanged = false;

						} else if ( tileType.hitGroundColor != 0 ) {

							// FOUND TILE AND TYPE MATCHING THE PLATFORM HIT.
							hitTile.setTile( tile, tmap, tileType );
							hitTile.hitChanged = true;
							break;

						} //

					} // ( tile != null && tile.type != 0 )

				} // end tileMap for-loop.

			} // end land-collider for-loop.

		} //

		/*private function onNodeAdded( node:LandColliderNode ):void {
		} //

		private function onNodeRemoved( node:LandColliderNode ):void {
		} //*/

		override public function addToEngine( systemManager:Engine ):void {

			this.colliderNodes = systemManager.getNodeList( LandColliderNode );

		} //
		
		override public function removeFromEngine( systemManager:Engine ):void {

			systemManager.releaseNodeList( LandColliderNode );

		} //

	} // End class

} // End package