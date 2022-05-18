package game.scenes.mocktropica.robotBossBattle.systems {

	import com.greensock.TweenLite;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.mocktropica.robotBossBattle.nodes.RobotMissileNode;
	import game.scenes.mocktropica.robotBossBattle.nodes.RobotPlayerNode;

	public class RobotMissileSystem extends System {

		private var missileNodes:NodeList;

		private var playerList:NodeList;
		private var playerNode:RobotPlayerNode;			// there's only going to be one player.

		/**
		 * used to tween a blink thingy when player gets hit.
		 */
		private var tween:TweenLite;

		private var leftMissile:Entity;
		private var rightMissile:Entity;
		private var boulder:Entity;

		public function RobotMissileSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			for( var node:RobotMissileNode = this.missileNodes.head; node; node = node.next ) {

				if ( node.sleep.sleeping ) {
					continue;
				}
				this.updateNode( node, time );

			} // end for-loop.

		} //

		private function updateNode( node:RobotMissileNode, time:Number ):void {

			if ( node.zdepth.z < -20 ) {

				node.sleep.sleeping = true;
				node.display.visible = false;

				return;

			} // end-if.

			// try to hit the player.
			if ( Math.abs( node.zdepth.z ) <= 10 && this.playerNode.life.hittable && this.testPlayerHit( node ) ) {
				if(node.missile.isMissile){
					group.shellApi.triggerEvent("fist_hit_player");	
				}
				else{
					group.shellApi.triggerEvent("rock_hit_player");	
				}
				
				this.playerNode.life.hit( 10 );

				this.hideMissile( node );

				this.playerNode.display.visible = true;
				this.tween.play();

			} // end-if.

		} // updateNode()

		/**
		 * because the zdepth is close enough, just need to check the bounds against the player.
		 */
		private function testPlayerHit( missileNode:RobotMissileNode ):Boolean {

			var dx:Number = missileNode.spatial.x - this.playerNode.spatial.x;
			var dy:Number = missileNode.spatial.y - this.playerNode.spatial.y;

			if ( Math.abs( missileNode.spatial.x - this.playerNode.spatial.x ) < this.playerNode.hit.halfWidth &&
				Math.abs( missileNode.spatial.y - this.playerNode.spatial.y ) < this.playerNode.hit.halfHeight ) {

				return true;

			} //

			return false;

		} // testPlayerHit()

		private function hideMissile( node:RobotMissileNode ):void {

			node.sleep.sleeping = true;
			node.display.visible = false;

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.missileNodes = systemManager.getNodeList( RobotMissileNode );

			/*for( var node:RobotMissileNode = this.missileNodes.head; node; node = node.next ) {
				this.missileAdded( node );
			} //*/

			this.playerList = systemManager.getNodeList( RobotPlayerNode );
			this.playerList.nodeAdded.add( this.playerAdded );
			for( var pNode:RobotPlayerNode = this.playerList.head as RobotPlayerNode; pNode; pNode = pNode.next ) {
				this.playerAdded( pNode );
			} //

		} // addToEngine()

		private function playerAdded( pNode:RobotPlayerNode ):void {

			// only one player. this is now it.
			this.playerNode = pNode;
			this.playerList.nodeAdded.removeAll();		// don't need this listener any more.

			this.tween = new TweenLite( this.playerNode.display, 0.25, { alpha:0.5, onComplete:this.reverseTween, onReverseComplete:reverseDone } );
			this.tween.pause();

		} // playerAdded()

		private function reverseDone():void {

			this.playerNode.display.visible = false;
			this.playerNode.display.alpha = 0;
		} //

		/**
		 * reverse the stupid blink tween.
		 */
		private function reverseTween():void {
			this.tween.reverse();
		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			this.tween.kill();
			this.tween = null;

			this.missileNodes.nodeAdded.removeAll();
			this.missileNodes = null;

			this.playerList.nodeAdded.removeAll();
			this.playerList = null;

		} //

	} // End RobotMissileSystem

} // End package