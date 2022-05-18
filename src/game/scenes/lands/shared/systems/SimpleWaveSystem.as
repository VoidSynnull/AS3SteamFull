package game.scenes.lands.shared.systems {

	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.components.SimpleWave;
	import game.scenes.lands.shared.nodes.SimpleWaveNode;

	public class SimpleWaveSystem extends System {

		private var waveNodes:NodeList;

		public function SimpleWaveSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			var wave:SimpleWave;
			var sin:Number;

			for( var node:SimpleWaveNode = this.waveNodes.head; node; node = node.next ) {

				if ( node.entity.sleeping ) {
					continue;
				}

				wave = node.wave;

				wave.curAngle += time*wave.omega;
				sin = Math.sin( wave.curAngle );

				if ( wave.xAmplitude != 0 ) {
					node.spatial.x = wave.origin.x + wave.xAmplitude*sin;
				}
				if ( wave.yAmplitude != 0 ) {
					node.spatial.y = wave.origin.y + wave.yAmplitude*sin;
				}

			} //

		} //
		
		/*public function updateNode( time:Number ):void {			
		} //*/

		private function nodeAdded( node:SimpleWaveNode ):void {

			if ( node.wave.origin == null ) {

				node.wave.origin = new Point( node.spatial.x, node.spatial.y );

			} //

		} //
		
		override public function addToEngine( systemManager:Engine):void {

			this.waveNodes = systemManager.getNodeList( SimpleWaveNode );
			this.waveNodes.nodeAdded.add( this.nodeAdded );

		} 

		override public function removeFromEngine( systemManager:Engine ):void {

			this.waveNodes.nodeAdded.removeAll();

		} //

	} // class

} // package