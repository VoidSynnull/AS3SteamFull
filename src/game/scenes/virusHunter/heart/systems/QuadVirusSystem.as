package game.scenes.virusHunter.heart.systems {

	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Audio;
	import engine.managers.SoundManager;
	
	import game.scenes.virusHunter.heart.components.ColorBlink;
	import game.scenes.virusHunter.heart.components.QuadVirus;
	import game.scenes.virusHunter.heart.nodes.BodyNode;
	import game.scenes.virusHunter.heart.nodes.QuadVirusNode;
	import game.scenes.virusHunter.heart.nodes.RigidArmNode;

	public class QuadVirusSystem extends System {

		// Maximum damage before virus runs away or dies.
		static private const MAX_VIRUS_DAMAGE:Number = 30;

		// Distance from a target where virus will attempt to halt.
		// None of this even belongs here. It's all a mess.
		static private const VIRUS_SLOW_RADIUS:Number = 300;
		// Don't need to be too precise here, and trying only introduces a 'halting problem' hyuck.
		static private const VIRUS_HALT_RADIUS:Number = 36;

		private var bodyNodes:NodeList;
		private var virusNodes:NodeList;

		private var armNodes:NodeList;

		public function QuadVirusSystem() {

			super();

		} //

		override public function addToEngine( e:Engine) : void {

			bodyNodes = e.getNodeList( BodyNode );
			virusNodes = e.getNodeList( QuadVirusNode );
			armNodes = e.getNodeList( RigidArmNode );

			virusNodes.nodeAdded.add( quadNodeAdded );
			for( var node:QuadVirusNode = virusNodes.head; node; node = node.next ) {
				quadNodeAdded( node );
			}

			super.addToEngine( e );

		} //

		override public function update( time:Number ):void {

			// There can be only one.
			var virusNode:QuadVirusNode = virusNodes.head;
			if ( !virusNode ) {
				return;
			}
			var virusInfo:QuadVirus = virusNode.virusInfo;

			if ( virusInfo.targetMove ) {
				doTargetMove( virusNode, virusInfo, time );
			} else if ( !checkBodyDamage( virusNode ) ) {

				 if ( virusInfo.curState != null ) {
					virusInfo.curState.update( time );
				} // end-if.

			} //

		} //

		private function checkBodyDamage( virusNode:QuadVirusNode ):Boolean {

			// there is only one virus body.
			var bodyNode:BodyNode = bodyNodes.head;
			var info:QuadVirus = virusNode.virusInfo;

			if ( info.hittable ) {

				var blink:ColorBlink;

				if ( bodyNode.damageTarget.damage > MAX_VIRUS_DAMAGE ) {

					virusNode.motion.acceleration.x = virusNode.motion.acceleration.y = 0;
					virusNode.motion.previousAcceleration.x = virusNode.motion.previousAcceleration.y = 0;

					bodyNode.damageTarget.damage = 0;			// reset the damage for next phase.
					bodyNode.damageTarget.isHit = false;
					bodyNode.hit.isHit = false;

					info.hittable = false;
					info.curState = null;

					blink = virusNode.entity.get( ColorBlink );
					if ( blink == null ) {
						blink = new ColorBlink( 0x660000, 0.43, info.hitCooldown );
						virusNode.entity.add( blink, ColorBlink );
						blink.onComplete = null;
					}

					blink.start();

					if ( info.onVirusWounded ) {
						info.onVirusWounded();
					}

					return true;

				} else if ( bodyNode.damageTarget.isHit == true && bodyNode.hit.isHit ) {

					virusNode.entity.get( Audio ).play( SoundManager.EFFECTS_PATH + "squish_01.mp3" );

					bodyNode.damageTarget.isHit = false;
					info.hittable = false;

					blink = virusNode.entity.get( ColorBlink );
					if ( blink == null ) {
						blink = new ColorBlink( 0x660000, 0.43, info.hitCooldown );
						virusNode.entity.add( blink, ColorBlink );
						blink.onComplete = this.virusBlinkDone;
					}

					blink.start();

				} // end-if.

			} // end-if.

			return false;

		} // checkBodyDamage()

		private function virusBlinkDone( e:Entity ):void {

			var info:QuadVirus = e.get( QuadVirus );
			info.hittable = true;

			var bodyNode:BodyNode = bodyNodes.head;

			bodyNode.damageTarget.isHit = false;
			bodyNode.hit.isHit = false;

		} //

		/**
		 * ugh, just ugh.
		 */
		private function doTargetMove( node:QuadVirusNode, virus:QuadVirus, time:Number ):void {
			
			var tx:Number = virus.targetX - node.spatial.x;
			var ty:Number = virus.targetY - node.spatial.y;

			var d:Number = Math.sqrt( tx*tx + ty*ty );
			
			var vel:Point = node.motion.velocity;
			
			if ( d < VIRUS_SLOW_RADIUS ) {
				
				if ( d < VIRUS_HALT_RADIUS ) {
					
					vel.x = vel.y = 0;
					node.motion.acceleration.x = node.motion.acceleration.y = 0;
					node.motion.previousAcceleration.x = node.motion.previousAcceleration.y = 0;
					node.motion.rotationVelocity = 0;

					virus.endTargetMove();

					var bodyNode:BodyNode = bodyNodes.head;

					bodyNode.damageTarget.isHit = false;
					bodyNode.hit.isHit = false;

					return;
				} //
				
				turnTowards( node, Math.atan2( ty, tx ), time );

				vel.x -= 0.1*vel.x*time;
				vel.y -= 0.1*vel.y*time;
				
				vel.x += ( ( tx - vel.x )*time );
				vel.y += ( ( ty - vel.y )*time );
				
			} else {
				
				/**
				 * Increase velocity up to some maximum. The Motion component gives maxVelocity in terms of a point
				 * which doesn't make sense in this context. Something more ad hoc is necessary.
				 */
				
				turnTowards( node, Math.atan2( ty, tx ), time );
				
				var cos:Number = Math.cos( node.spatial.rotation*Math.PI/180 );
				var sin:Number = Math.sin( node.spatial.rotation*Math.PI/180 );

				var dot:Number = tx*cos + ty*sin;

				if ( dot > 0 ) {

					vel.x += ( 600*cos - vel.x )*0.5*time;
					vel.y += ( 600*sin - vel.y )*0.5*time;

				} else {

					vel.x -= vel.x*time;
					vel.y -= vel.y*time;

				} //

			} //

		} // doTargetMove()

		// Turn towards a direction dx,dy away.
		private function turnTowards( node:QuadVirusNode, theta:Number, time:Number ):void {
			
			var dtheta:Number = theta - node.spatial.rotation*Math.PI/180;
			if ( dtheta > Math.PI ) {
				dtheta -= 2*Math.PI;
			} else if ( dtheta < -Math.PI ) {
				dtheta += 2*Math.PI;
			}
			
			if ( Math.abs(dtheta) < 0.01 ) {
				
				node.motion.rotationVelocity = 0;
				node.spatial.rotation = theta*180/Math.PI;
				
			} else if ( Math.abs(dtheta) < 0.2 ) {
				
				node.motion.rotationVelocity += ( ( dtheta*180/Math.PI )/0.5 - node.motion.rotationVelocity );
				
			} else {
				
				if ( dtheta < 0 ) {
					node.motion.rotationVelocity -= 160*time;
				} else {
					node.motion.rotationVelocity += 160*time;
				} //
				if ( node.motion.rotationVelocity > 160 ) {
					node.motion.rotationVelocity = 160;
				} else if ( node.motion.rotationVelocity < -160 ) {
					node.motion.rotationVelocity = -160;
				} //
				
			} // end-if.
			
		} // end-turn.

		/**
		 * Remove a given entity from the given entity list.
		 */
		private function removeEntity( v:Vector.<Entity>, e:Entity ):void {

			for( var i:int = v.length-1; i >= 0; i-- ) {

				if ( v[i] == e ) {

					v[i] = v[v.length-1];
					v.pop();
					return;

				} //

			} //

		} // removeEntity()

		private function removeIndex( v:Vector.<Entity>, i:int ):void {
			
			v[i] = v[v.length-1];
			v.pop();
			
		} //

		private function quadNodeAdded( node:QuadVirusNode ):void {

			var virus:QuadVirus = node.virusInfo;

			virus.entity = node.entity;
			virus.clip = node.display.displayObject as MovieClip;
			virus.armEntities = node.children.children;

			virus.entity.add( new Audio() );

			virus.init();

		} //

		override public function removeFromEngine( e:Engine) : void {

			super.removeFromEngine( e );

			virusNodes.nodeAdded.remove( quadNodeAdded );

			bodyNodes = null;
			virusNodes = null;
			armNodes = null;

		} //

	} // End QuadVirusSystem

} // End package