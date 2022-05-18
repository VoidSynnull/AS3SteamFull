package game.scenes.carnival.shared.ferrisWheel.systems {
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.carnival.shared.ferrisWheel.components.StickToEntity;
	import game.scenes.carnival.shared.ferrisWheel.nodes.StickToEntityNode;
	import game.util.EntityUtils;

	public class StickToEntitySystem extends System {

		private const DEG_PER_RAD:Number = 180 / Math.PI;
		private const RAD_PER_DEG:Number = Math.PI/180;

		private var nodeList:NodeList;

		private var colliders:NodeList;

		public function StickToEntitySystem() {

			super();

		} //

		override public function update( time:Number ):void {

			var spatial:Spatial;
			var stickTo:Spatial;
			var cos:Number;
			var sin:Number;

			var stick:StickToEntity;

			for( var node:StickToEntityNode = this.nodeList.head; node; node = node.next ) {

				if ( EntityUtils.sleeping(node.entity) ) {
					continue;
				}

				spatial = node.spatial;
				stick = node.stick;
				stickTo = stick.entitySpatial;

				cos = Math.cos( stickTo.rotation*this.RAD_PER_DEG );
				sin = Math.sin( stickTo.rotation*this.RAD_PER_DEG );

				spatial.x = stickTo.x + stick.offsetX * cos - stick.offsetY * sin;
				spatial.y = stickTo.y + stick.offsetX * sin + stick.offsetY * cos;
				spatial.rotation = stickTo.rotation;

			} // for-loop

		} // update()

		override public function addToEngine( systemManager:Engine ):void {

			this.nodeList = systemManager.getNodeList( StickToEntityNode );

			for( var node:StickToEntityNode = this.nodeList.head; node; node = node.next ) {
				this.nodeAdded( node );
			} //

			this.nodeList.nodeAdded.add( this.nodeAdded );
			this.nodeList.nodeRemoved.add( this.nodeRemoved );
	
		} //

		override public function removeFromEngine( systemManager:Engine ):void {
			
			systemManager.releaseNodeList( StickToEntityNode );
			this.nodeList = null;

		} //

		private function nodeAdded( node:StickToEntityNode ):void {

			/*
			dx = swing.platformSpatial.x - spatial.x;
			dy = swing.platformSpatial.y - spatial.y;
			
			var cos:Number = Math.cos( spatial.rotation * this.RAD_PER_DEG );
			var sin:Number = Math.sin( spatial.rotation * this.RAD_PER_DEG );
			
			swing.platformOffset = new Point( dx*cos + dy*sin, dy*cos - dx*sin );
			*/

		} //

		private function nodeRemoved( node:StickToEntityNode ):void {

			node.stick.entity = null;
			node.stick.entitySpatial = null;

		} //

	} // End StickToEntitySystem

} // End package