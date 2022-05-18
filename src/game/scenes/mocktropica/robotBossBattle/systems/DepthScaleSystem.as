package game.scenes.mocktropica.robotBossBattle.systems {

	import ash.core.Engine;
	import ash.core.Node;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.mocktropica.robotBossBattle.components.ZDepthScale;
	import game.scenes.mocktropica.robotBossBattle.nodes.ZDepthScaleNode;
	import game.systems.SystemPriorities;

	public class DepthScaleSystem extends System {

		private var scaleNodes:NodeList;

		public function DepthScaleSystem() {

			super();

			this._defaultPriority = SystemPriorities.preRender;

		} //

		override public function update( time:Number ):void {

			for( var node:ZDepthScaleNode = this.scaleNodes.head; node; node = node.next ) {

				if ( node.sleep.sleeping || node.display.visible == false ) {
					continue;
				}

				node.spatial.scaleX = node.spatial.scaleY = node.scaling.focus / ( node.scaling.focus - node.zdepth.z );

			} // end for-loop.

		} //

		private function nodeAdded( node:ZDepthScaleNode ):void {

			node.spatial.scaleX = node.spatial.scaleY = node.scaling.focus / ( node.scaling.focus - node.zdepth.z );

		} //

		override public function addToEngine( systemManager:Engine ):void {
			
			super.addToEngine( systemManager );
			
			this.scaleNodes = systemManager.getNodeList( ZDepthScaleNode );
			this.scaleNodes.nodeAdded.add( this.nodeAdded );

			for( var node:Node = this.scaleNodes.head; node; node = node.next ) {
				this.nodeAdded( node as ZDepthScaleNode );
			}
			
		} //

		override public function removeFromEngine( systemManager:Engine ) : void {
			
			//this._zNodes.nodeAdded.remove( this.zNodeAdded );
			
			//systemManager.releaseNodeList(ZDepthControlNode);
			systemManager.releaseNodeList( ZDepthScaleNode );

			//this._controlNodes = null;
			this.scaleNodes.nodeAdded.removeAll();
			this.scaleNodes = null;

			super.removeFromEngine(systemManager);
			
		} //

	} // End DepthScaleSystem
	
} // End package