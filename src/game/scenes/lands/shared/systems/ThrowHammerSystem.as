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
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.data.motion.time.FixedTimestep;
	import game.scenes.lands.shared.nodes.ThrowHammerNode;
	import game.systems.SystemPriorities;
	
	public class ThrowHammerSystem extends System {
		
		private var nodeList:NodeList;
		
		/**
		 * if there are no nodes in the system for too long, it will remove itself.
		 */
		private var autoRemoveCount:int = 0;
		
		public function ThrowHammerSystem() {
			
			super();
			
			super._defaultPriority = SystemPriorities.move;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			
		} //
		
		override public function update( time:Number ):void {
			
			var node:ThrowHammerNode = this.nodeList.head;
			if ( node == null ) {
				
				if ( ++this.autoRemoveCount >= 180 ) {
					this.group.removeSystem( this, true );
				}
				return;
				
			} //
			
			this.autoRemoveCount = 0;
			
			var spatial:Spatial;
			var target:Spatial;
			var motion:Motion;
			
			var dx:Number;
			var dy:Number;
			var d:Number;
			
			for( ; node; node = node.next ) {
				
				spatial = node.spatial;
				target = node.target.target;
				
				dx = target.x - spatial.x;
				dy = target.y - spatial.y;
				
				d = dx*dx + dy*dy;
				
				if ( ++node.hammer.waitCount > 30 && (d < 6400) ) {
					
					if ( node.hammer.onHammerReturn ) {
						node.hammer.onHammerReturn( node.entity );
					} //
					
				} else {
					
					d = Math.sqrt(d);
					dx /= d;
					dy /= d;
					
					motion = node.motion;
					motion.velocity.x += 800*dx*time;
					motion.velocity.y += 800*dy*time;
					motion.velocity.x *= 0.98;
					motion.velocity.y *= 0.98;
					
					
				} //
				
			} // for-loop.
			
		} // update()
		
		override public function addToEngine( systemManager:Engine):void {
			
			this.nodeList = systemManager.getNodeList( ThrowHammerNode );
			
		}
		
		override public function removeFromEngine( systemManager:Engine ):void {
			
			this.nodeList = null;
			
		} //
		
	} // class
	
} // package