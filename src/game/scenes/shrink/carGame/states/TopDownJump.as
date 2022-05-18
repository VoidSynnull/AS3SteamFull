package game.scenes.shrink.carGame.states
{
	public class TopDownJump extends TopDownDriverState
	{
		public function TopDownJump()
		{
			super.type = TopDownDriverState.JUMP;
		}
		
		private const SCALE_INCREMENT:Number = .009;
		/**
		 * Start the state
		 */
		override public function start():void
		{
			_altTiltY = 0;
			_scaleIncrementor = .001;
			_altMagnitudeY = .1;
			node.motionMaster.maxVelocity.x = 1200;
			
			super.updateStage = jumpingMovement;
		}
		
		override public function update( time:Number ):void
		{
			super.setPreviousDisplayPositions();
			super.updateStage();
		}
		
		private function jumpingMovement():void
		{
			_altTiltY += .3;
			
			if( node.collider.collisionType == JUMP && node.collider.hitDisplay.displayObject.hitTestObject( node.display.displayObject ))
			{
				node.motionMaster.velocity.x -= 75;
				
				if( node.spatial.scaleX < 1.4 )
				{
					node.spatial.scaleX += SCALE_INCREMENT;
				}
				
				super.carDriveMovement();
//				super.setXTilt();
//				_chassis.y = previousChassisPos.y - ( _altMagnitudeY / 8 ) * Math.sin( _altTiltY );
//				_hull.y = previousHullPos.y + ( _altMagnitudeY / 8 ) * Math.sin( _altTiltY );
//				_top.y = previousTopPos.y + ( _altMagnitudeY / 2 ) * Math.sin( _altTiltY );
//				_roof.y = previousRoofPos.y + _altMagnitudeY * Math.sin( _altTiltY );
//				
//				_chassis.x = - ( magnitudeX / 8 ) * Math.sin( _tiltX );
//				_hull.x = ( magnitudeX / 8 ) * Math.sin( _tiltX );
//				_top.x = ( magnitudeX / 2 ) * Math.sin( _tiltX );
//				_roof.x = magnitudeX * Math.sin( _tiltX );
			}
			else
			{
				_magnitudeY = .10;
				_ySpeedOffset = Math.abs( Math.random() * 5 + 5 );
				
				super.setXTilt();
				_chassis.y = previousChassisPos.y - ( _altMagnitudeY / 8 ) * Math.sin( _altTiltY );
				_hull.y = previousHullPos.y + ( _altMagnitudeY / 8 ) * Math.sin( _altTiltY );
				_top.y = previousTopPos.y + ( _altMagnitudeY / 2 ) * Math.sin( _altTiltY );
				_roof.y = previousRoofPos.y + _altMagnitudeY * Math.sin( _altTiltY );
				
				_chassis.x = - ( magnitudeX / 8 ) * Math.sin( _tiltX );
				_hull.x = ( magnitudeX / 8 ) * Math.sin( _tiltX );
				_top.x = ( magnitudeX / 2 ) * Math.sin( _tiltX );
				_roof.x = magnitudeX * Math.sin( _tiltX );
				
				
				if( !_jumping )
				{
					_jumping = true;
					node.motionControl.moveToTarget = false;
					node.motionControl.lockInput = true;
				}
				
				if( node.spatial.scaleX > 1 )
				{
					_scaleIncrementor += .0002;
					node.spatial.scaleX -= _scaleIncrementor;
				}
				else
				{
					node.spatial.rotation = 0;
					_magnitudeY = .10;
					_jumping = false;
					
					node.fsmControl.setState( DRIVE );
					node.motionControl.lockInput = false;
					node.spatial.scaleX = 1;
				}
			}
			
			
			node.spatial.scaleY = node.spatial.scaleX;
		}
	}
}