package game.scenes.virusHunter.heart.systems {

	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.heart.nodes.ArmTargetNode;
	import game.scenes.virusHunter.heart.nodes.RigidArmNode;

	/**
	 * Converts player positions into target coordinates local to the virus coordinate space.
	 */
	public class VirusTargetSystem extends System {

		private var armInfoNodes:NodeList;

		private var target:Entity;
		private var tSpatial:Spatial;
		private var sceneClip:DisplayObjectContainer;

		private var virusClip:DisplayObjectContainer;

		private var armTargetCount:int = 0;

		// The local point that the arms should target.
		private var targetPt:Point;

		public function VirusTargetSystem() {

			super();

			targetPt = new Point( 0, 0 );

		} //

		public function setTarget( targetEntity:Entity ):void {

			this.target = targetEntity;
			this.tSpatial = targetEntity.get( Spatial ) as Spatial;
			this.sceneClip = ( targetEntity.get( Display ) as Display ).displayObject.parent;

			this.update( 0 );

		} //

		public function setVirus( virus:Entity ):void {

			this.virusClip = ( virus.get(Display) as Display ).displayObject;

		} //

		override public function addToEngine( e:Engine ):void {

			super.addToEngine( e );
	
			armInfoNodes = e.getNodeList( ArmTargetNode );
			armInfoNodes.nodeAdded.add( nodeAdded );
			armInfoNodes.nodeRemoved.add( nodeRemoved );

			for( var curNode:ArmTargetNode = this.armInfoNodes.head; curNode; curNode = curNode.next ) {
				
				nodeAdded( curNode );
				
			} // end for-loop.

		} //

		override public function update( time:Number ):void {

			if ( armTargetCount == 0 || this.target == null ) {
				return;
			}

			var p:Point = new Point( this.tSpatial.x, this.tSpatial.y );
			p = this.sceneClip.localToGlobal( p );
			targetPt = this.virusClip.globalToLocal( p );			// Now we have the target coordinate in virus-space.

			for( var curNode:ArmTargetNode = this.armInfoNodes.head; curNode; curNode = curNode.next ) {

				curNode.target.targetX = targetPt.x;
				curNode.target.targetY = targetPt.y;

			} // end for-loop.

		} //

		public function nodeAdded( n:ArmTargetNode ):void {

			armTargetCount++;

			if ( target != null ) {
				n.target.targetX = targetPt.x;
				n.target.targetY = targetPt.y;
			}

		} //

		public function nodeRemoved( n:ArmTargetNode ):void {

			armTargetCount--;

		} //

		override public function removeFromEngine( engine:Engine ):void {

			armInfoNodes.nodeAdded.remove( nodeAdded );
			armInfoNodes.nodeRemoved.remove( nodeRemoved );

			super.removeFromEngine( engine );

		} //

	} // End VirusTargetSystem

} // End package