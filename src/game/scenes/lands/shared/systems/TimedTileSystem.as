package game.scenes.lands.shared.systems {

	/**
	 *
	 * tracks tiles that have some special 'active' quality requiring processing every frame,
	 * or at certain key points - possibly water tiles, crumbling tiles once stepped on...
	 *
	 */
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.classes.TileSelector;
	import game.scenes.lands.shared.classes.TimedTile;
	import game.scenes.lands.shared.nodes.TimedTilesNode;
	
	import org.osflash.signals.Signal;

	public class TimedTileSystem extends System {

		private var nodeList:NodeList;

		/**
		 * onTimerComplete( TimedTile )
		 */
		public var onTimerComplete:Signal;

		public function TimedTileSystem() {

			super();
			this.onTimerComplete = new Signal( TimedTile );

		} //

		override public function update( time:Number ):void {

			var node:TimedTilesNode = this.nodeList.head;
			if ( node == null || node.entity.sleeping ) {
				return;
			}

			var timedTiles:Vector.<TimedTile> = node.timedList.timedTiles;
			var timedTile:TimedTile;

			for( var i:int = timedTiles.length-1; i >= 0; i-- ) {

				timedTile = timedTiles[i];
				timedTile.timer -= time;

				var selector:TileSelector = timedTile.selector;

				if ( timedTile.timer <= 0 ) {

					timedTiles[i] = timedTiles[ timedTiles.length-1 ];
					timedTiles.pop();

					this.onTimerComplete.dispatch( timedTile );

					if ( timedTile.destroyOnComplete ) {
						selector.tileMap.clearType( selector.tile, selector.tileType.type );
					} else if ( timedTile.blastOnComplete ) {
						// blow the fecking thing up.
						node.blaster.addImmediate( selector );
					} //

				} else {

					if ( timedTile.crumble ) {
						node.blaster.crumble( selector.tileType,
							( selector.tile.col + 0.5 )*selector.tileMap.tileSize, ( selector.tile.row + 0.5 )*selector.tileMap.tileSize );
					} 

				} // end-if.

			} // for-loop.

		} // update()

		/*private function onNodeAdded( node:TimedTilesNode ):void {
		} //

		private function onNodeRemoved( node:TimedTilesNode ):void {
		} //*/

		override public function addToEngine( systemManager:Engine ):void {

			this.nodeList = systemManager.getNodeList( TimedTilesNode );
		//	this.nodeList.nodeAdded.add( this.onNodeAdded );
		//	this.nodeList.nodeRemoved.add( this.onNodeRemoved );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

		//	this.timedTiles.length = 0;

			this.onTimerComplete.removeAll();

			systemManager.releaseNodeList( TimedTilesNode );

		} //

	} // End class

} // End package