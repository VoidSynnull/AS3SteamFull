package game.scenes.lands.shared.systems {
	
	/**
	 *
	 * An entity with a 'disintegrate' component will constantly destroy
	 * all tiles which touch it.
	 * 
	 */
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.LandGroup;
	import game.scenes.lands.shared.classes.LandGameData;
	import game.scenes.lands.shared.components.Disintegrate;
	import game.scenes.lands.shared.nodes.DisintegrateNode;
	import game.scenes.lands.shared.tileLib.classes.TileLayer;
	
	
	public class DisintegrateSystem extends System {
		
		private var nodeList:NodeList;
		
		private var blastSystem:BlastTileSystem;
		
		private var fgLayer:TileLayer;
		
		/**
		 * if there are no nodes in the system for too long, it will remove itself.
		 */
		private var autoRemoveCount:int = 0;
		
		public function DisintegrateSystem() {
			
			super();
			
		} //
		
		override public function update( time:Number ):void {
			
			var node:DisintegrateNode = this.nodeList.head;
			if ( node == null ) {
				
				if ( ++this.autoRemoveCount >= 180 ) {
					this.group.removeSystem( this, true );
				}
				return;
				
			} //
			
			this.autoRemoveCount = 0;
			
			var sp:Spatial;
			var disintegrate:Disintegrate;
			
			for( ; node; node = node.next ) {
				
				disintegrate = node.disintegrate;
				if ( disintegrate.timer++ < disintegrate.waitFrames ) {
					continue;
				}
				
				disintegrate.timer = 0;
				
				sp = node.spatial;
				
				if ( this.blastSystem != null ) {
					this.blastSystem.blastRadius( this.fgLayer, sp.x, sp.y, disintegrate.radius );
				}
				
			} // for-loop.
			
		} // update()
		
		override public function addToEngine( systemManager:Engine):void {
			
			this.nodeList = systemManager.getNodeList( DisintegrateNode );

			var gameData:LandGameData = ( this.group as LandGroup ).gameData;
			this.fgLayer = gameData.getFGLayer();
			
			// not a very good way to handle this right now.
			this.blastSystem = group.getSystem( BlastTileSystem ) as BlastTileSystem;
			
		}
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			this.blastSystem = null;
			this.nodeList = null;
			
		} //
		
	} // class
	
} // package