package game.scenes.shrink.carGame.states
{
	public class TopDownSpin extends TopDownDriverState
	{
		public function TopDownSpin()
		{
			super.type = TopDownDriverState.SPIN;
		}
		
		override public function update( time:Number ):void {}
		/**
		 * Start the state
		 */
		override public function start():void
		{			
			node.motionControl.moveToTarget = false;
			node.motionControl.lockInput = true;
			
//			if( node.collider.hitDisplay.displayObject.hitTestObject( node.display.displayObject ))
//			{
			//	if( node.spatial.x + .5 * node.spatial.width < node.collider.hitSpatial.x )
			//	if( node.spatial.x < node.collider.hitSpatial.x )
			//	{ 
//					if( node.motionMaster )
//					{
//						node.motionMaster.velocity.x = 300;
//						node.motionMaster.previousAcceleration.x = 0;
//					}
						
					node.timeline.gotoAndPlay( "spin" );
					node.timeline.handleLabel( "hitTop", resetDrivingAnimation );
//						return;
//					}
//				}
//				
//				if( node.motion.y < node.collider.hitSpatial.y )
//				{
//					if( node.motion.velocity.y > 0 )
//					{
//						node.motion.velocity.y = -300;
//					}
//				}
//					
//				else if( node.motion.y > node.collider.hitSpatial.y )
//				{
//					if( node.motion.velocity.y < 0 )
//					{
//						node.motion.velocity.y = -300;
//					}
//				}
//				
//				
//				node.fsmControl.setState( DRIVE );
//			}
		}
		
		override protected function resetDrivingAnimation():void
		{
			node.motionControl.lockInput = false;
			if( node.motionControl.inputStateDown )
			{
				node.motionControl.moveToTarget = true;
			}
			super.resetDrivingAnimation();
		}
		
//		override public function update( time:Number ):void
//		{
//			super.updateStage();
//		}
//		
//		private function spinMovement():void
//		{
//			
//			}
//		}
	}
}