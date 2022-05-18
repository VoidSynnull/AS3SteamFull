package game.scenes.mocktropica.robotBossBattle.systems {

	import flash.display.Bitmap;
	import flash.display.Sprite;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.mocktropica.robotBossBattle.components.HitBox3D;
	import game.scenes.mocktropica.robotBossBattle.components.RobotBoss;
	import game.scenes.mocktropica.robotBossBattle.nodes.CoinShotNode;
	import game.scenes.mocktropica.robotBossBattle.nodes.RobotEnemyNode;

	public class CoinShotSystem extends System {

		private var coinList:NodeList;
		private var enemyList:NodeList;

		public function CoinShotSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			for( var node:CoinShotNode = this.coinList.head; node; node = node.next ) {

				this.spinCoin( node, time );

				if ( node.spatial.scaleX < 0.1 ) {

					this.group.removeEntity( node.entity, true );

				} else if ( node.coin.falling ) {

					node.motion.acceleration.y += 2000;

					if ( node.zdepth.z < 0 || node.spatial.y > 1000 ) {
						this.group.removeEntity( node.entity, true );
					} //

				} else {

					
					// try to hit the robot.
					for( var enode:RobotEnemyNode = this.enemyList.head; enode; enode = enode.next ) {

						// obnoxious hit test. we still test the hit even if the robot isn't hittable
						// so the coins can bounce off.
						if ( this.testRobotHit( enode, node ) ) {
							group.shellApi.triggerEvent("hit_boss");
							//trace( "HIT THE SDTUPID ROBOT HIYT HI THIT" );
							if ( enode.life.hittable ) {
								enode.life.hit();

								if ( enode.blink ) {
									enode.blink.start();
								}

							} //
							enode.motion.velocity.z += 0.02*node.motion.velocity.z;
							// change direction and fall.
							node.motion.velocity.z = 1;
							node.coin.falling = true;
							break;
	
						} // end-if.
						
					} // end for-loop.

				} // end-if.

			} // end for-loop.

		} //

		private function testRobotHit( enode:RobotEnemyNode, coinNode:CoinShotNode ):Boolean {

			var hit:HitBox3D = enode.hit;
			var scale:Number = enode.spatial.scaleX;
			
			//I don't know best way to check if it's the boss and not an achievement, so using this -Jordan
			if (enode.entity.get(RobotBoss)) {
				if ( Math.abs( coinNode.spatial.x - enode.spatial.x ) < scale*hit.halfWidth &&
					Math.abs( coinNode.spatial.y - enode.spatial.y ) < scale*hit.halfHeight &&
					Math.abs( coinNode.zdepth.z - enode.zdepth.z ) < hit.halfDepth ) {
					return true;
				}
			}
			else { //if it's an achievemnt then do a more leniant z depth test (just if it's greater than)
				if ( Math.abs( coinNode.spatial.x - enode.spatial.x ) < scale*hit.halfWidth &&
					Math.abs( coinNode.spatial.y - enode.spatial.y ) < scale*hit.halfHeight &&
					coinNode.zdepth.z > enode.zdepth.z - hit.halfDepth ) {
					return true;
				}
			}
			
			return false;
			
		} // testRobotHit()
		
		private function spinCoin( node:CoinShotNode, time:Number ):void {

			var coinBitmap:Bitmap = ( node.display.displayObject as Sprite ).getChildAt( 0 ) as Bitmap;

			node.coin.timer += time*6;
			var cos:Number = Math.cos( node.coin.timer );

			if ( cos >= 0 ) {

				coinBitmap.scaleY = 0.16 + 0.84*cos;
				coinBitmap.y = -coinBitmap.height/2;

			} else {

				coinBitmap.scaleY = -0.16 + 0.84*cos;
				// bitmap needs to be re-aligned because it has to be centered.
				coinBitmap.y = coinBitmap.height/2;

			} // end-if.
			
		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			this.coinList = null;
			this.enemyList = null;

		} //

		override public function addToEngine( systemManager:Engine ):void {

			this.coinList = systemManager.getNodeList( CoinShotNode );
			this.enemyList = systemManager.getNodeList( RobotEnemyNode );

		} //

	} // End CoinShotSystem
	
} // End package