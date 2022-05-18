package game.scenes.lands.shared.monsters.systems {

	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.monsters.components.Spider;
	import game.scenes.lands.shared.monsters.nodes.SpiderNode;
	import game.scenes.lands.shared.tileLib.LandTile;
	import game.scenes.lands.shared.tileLib.TileMap;


	public class SpiderSystem extends System {

		private var spiderNodes:NodeList;

		private var gameData:LandGameData;
		private var treeMap:TileMap;

		private var webTile:uint = 0x800000;

		public function SpiderSystem( landGroup:LandGroup ) {

			super();

			landGroup.onBiomeChanged.add( this.biomeChanged );

			this.gameData = landGroup.gameData;
			this.treeMap = gameData.tileMaps[ "trees" ];

		} //

		/**
		 * for now, for testing, combine almost all spider functions here. later some sub-components will deal with motion
		 * and dying.
		 */
		override public function update( time:Number ):void {

			var tile:LandTile;
			var spider:Spider;
			var spatial:Spatial;

			for ( var node:SpiderNode = this.spiderNodes.head; node; node = node.next ) {

				if ( node.entity.sleeping ) {
					continue;
				}

				spider = node.spider;
				spatial = node.spatial;

				var r:int = spatial.y / this.treeMap.tileSize;
				if ( r >= this.treeMap.rows ) {
					this.systemManager.removeEntity( node.entity );
					continue;
				}

				var c:int = ( spatial.x - this.gameData.mapOffsetX ) / this.treeMap.tileSize;

				tile = this.treeMap.getTile( r, c );

				if ( spider.falling > 20 ) {

					if ( tile.type & this.webTile ) {
						spider.falling = 0;
						node.entity.remove( Motion );
					} else {
						continue;
					}

				} else if ( !( tile.type & this.webTile ) ) {

					// check if tile is still web.
					// fall down, maybe die.
					if ( ++spider.falling > 20 ) {			// the counter prevents falling mistakes from being a tiny bit off the web.
						var motion:Motion = new Motion();
						motion.acceleration.y = 500;
						node.entity.add( motion, Motion );
						continue;
					}

				} //

				// find new tile to aim at.
				if ( !spider.moving ) {

					if ( Math.random() < 0.02 ) {

						// try to find a new location.
						var nx:Number = spatial.x - 32 + 64*Math.random();
						var ny:Number = spatial.y - 32 + 64*Math.random();

						tile = this.treeMap.getTileAt( nx - this.gameData.mapOffsetX, ny );
						if ( tile.type & this.webTile ) {

							spider.setDest( nx, ny );

						} else {
						//	trace( "can't move" );
						}

					} //

				} else {

					var dx:Number = spider.targetX - spatial.x;
					var dy:Number = spider.targetY - spatial.y;
					
					var d:Number = Math.sqrt( dx*dx + dy*dy );
					if ( d < 4 ) {
						spider.moving = false;
						spatial.x = spider.targetX;
						spatial.y = spider.targetY;
						continue;
					}

					var dtheta:Number = (180/Math.PI)*Math.atan2( dy, dx ) - spatial.rotation;
					if ( dtheta > 180 ) {
						dtheta -= 360;
					} else if ( dtheta < -180 ) {
						dtheta += 360;
					} //
					
					spatial.rotation += dtheta/8;

					// only move forward if the spider is roughly facing the target direction.
					if ( Math.abs(dtheta) < 20 ) {

						spatial.x += dx/d;
						spatial.y += dy/d;

					} //


				} //

			} // for-loop.

		} //

		/**
		 * refresh the tile map when the biome changes.
		 * this is because the old tile map would have been deleted.
		 */
		public function biomeChanged():void {

			this.treeMap = this.gameData.tileMaps["trees"];

		} //

		
		private function nodeAdded( node:SpiderNode ):void {
		} //

		override public function addToEngine( systemManager:Engine):void {

			this.spiderNodes = systemManager.getNodeList( SpiderNode );
			//this.spiderNodes.nodeAdded.add( this.nodeAdded );

		} 
		
		override public function removeFromEngine( systemManager:Engine ):void {

			//this.spiderNodes.nodeAdded.removeAll();
			this.spiderNodes = null;

		} //

	} // class

} // package