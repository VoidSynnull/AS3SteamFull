package game.scenes.shrink.carGame.states
{
	public class TopDownFall extends TopDownDriverState
	{
		private var fallen:Boolean;
		private var reset:Boolean;
		
		public function TopDownFall()
		{
			super.type = TopDownDriverState.FALL;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			_altTiltY = 0;
			_altMagnitudeY = .1;
			_inHole = false;
			fallen = false;
			reset = false;
			
			node.motionControl.moveToTarget = false;
			node.motionControl.lockInput = true;
			clearHandlers();
				
			_inHole = true;
			
			node.motionMaster.acceleration.x = 0;
			node.motionMaster.velocity.x = 0;
			
			node.motion.velocity.x = node.collider.hitSpatial.x + node.collider.hitEdge.rectangle.left + .5 * node.collider.hitEdge.rectangle.width - node.spatial.x;
			node.motion.velocity.y = node.collider.hitSpatial.y + node.collider.hitEdge.rectangle.top - node.spatial.y;
			
			super.updateStage = fallingMovement;
			
			resetDirection();
		}
		
		override public function update( time:Number ):void
		{
			super.updateStage();
		}
		
		// FALLING LOGIC
		private function fallingMovement():void
		{
				// FALLING INTO PIT
			if( node.display.alpha > 0 && !fallen )
			{
				node.spatial.rotation += 35;
				
				node.display.alpha -= .05;
				node.spatial.scaleX -= .05;
			}
				
			else
			{
					// PAN THE SCENE BACK TO BEFORE YOU HIT THE PIT
				if( _inHole )
				{
					_inHole = false;
					fallen = true;
					
					node.spatial.rotation = 0;
					
					node.motion.velocity.x = 0;
					node.motion.velocity.y = 0;
					
					node.motionMaster.acceleration.x = -500;
					node.motionMaster.velocity.x = 1000;
					
					if( node.spatial.y + 500 < node.motionBounds.box.bottom )
					{
						node.spatial.y += node.collider.hitSpatial.height * .5 + 100;
					}
					else
					{
						node.spatial.y -= ( node.collider.hitSpatial.height * .5 + 100 );
					} 
				}
					// STOP MOTION, SPIN THE JEEP AND START MOTION AFTER THE ANIMATION COMPLETES
				else
				{
					if( node.motionMaster.velocity.x < 0 && !reset )
					{
						node.motionMaster.zeroMotion();
						
						node.spatial.rotation = 0;
						node.spatial.x = 300;
						node.spatial.scaleX = 1;
						reset = true;
					}
					
					else if( reset )
					{
						if( node.display.alpha < 1 )
						{
							node.display.alpha += .05;
						}
						else if( !node.timeline.playing )
						{					
							_magnitudeY = 20;
							node.display.alpha = 1;
							
							node.timeline.play();
							node.timeline.handleLabel( "ending", spinEnded );
						}
					}
				}
			}
			
			node.spatial.scaleY = node.spatial.scaleX;
		} 
		
		// RETURN CONTROL, ACCELERATION AND RESET THE CAR
		private function spinEnded():void
		{
			node.motionControl.lockInput = false;
			node.motionMaster.acceleration.x = -100;
			resetDrivingAnimation();
		}
	}
}