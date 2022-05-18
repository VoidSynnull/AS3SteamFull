package game.scenes.shrink.carGame.states
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.components.input.Input;
	import game.scenes.shrink.carGame.hitTypes.TopDownHitTypes;
	import game.scenes.shrink.carGame.nodes.TopDownCollisionNode;
	import game.systems.animation.FSMState;
	
	public class TopDownDriverState extends FSMState
	{
		private static const DRIVE_OFF_SPEED:Number 	= 	250;
		protected static const X:String 				= 	"X";
		private static const REBOUND:Number 			= 	200;
		private static const CURB_BOUNCE:Number			= 	150;
		
		public static const DRIVE:String 				=	"drive";
		public static const FALL:String 				=	"fall";
		public static const IN_CULVERT:String			= 	"in_culvert";
		public static const JUMP:String 				=	"jump";
		public static const SPIN:String					= 	"spin";
		
		public static const STATES:Vector.<String> 	= new <String>[ DRIVE, FALL, IN_CULVERT, JUMP, SPIN ];
		
		protected var _tiltX:Number; 	//	left/right tilt of the jeep
										//	Would tilt in the opposite direction of the turn, larger at faster speeds. (ranges from -1 to 1)
		protected var _tiltY:Number = 0; 
		protected var _altTiltY:Number;
		protected var _jumping:Boolean = false;
		protected var _inHole:Boolean = false;
		protected var _inCulvert:Boolean = false;
		protected var _spinning:Boolean = false;
		protected var _culvertPosition:Spatial;
		
		// MIGHT WANT TO MAKE THIS IT'S OWN SYSTEM FOR MOVEMENT...
		protected var _magnitudeY:Number = 0;
		protected var _altMagnitudeY:Number = 0;
		protected var _scaleIncrementor:Number = .001;
		
		protected var _ySpeedOffset:Number = 0;
		
		protected const magnitudeX:Number = 12;
		
		protected var _chassis:DisplayObject;
		protected var _hull:DisplayObject;
		protected var _top:DisplayObject;
		protected var _roof:DisplayObject;
		protected var _hit:DisplayObject;
//		protected var _windshield:DisplayObject;
		
		protected var previousChassisPos:Point;
		protected var previousHullPos:Point;
		protected var previousTopPos:Point;
		protected var previousRoofPos:Point;

		public function TopDownDriverState() {}
		
		public function init( input:Input = null ):void
		{			
			if( input )
			{
				input.inputDown.add( toggleMoveToTargetOn );
				input.inputUp.add( toggleMoveToTargetOff );
			}
			
			node.motionControl.moveToTarget = false;
			node.motionControlBase.freeMovement = false;
			node.motionControlBase.lockAxis = X;
			
			var jeep:DisplayObjectContainer = node.display.displayObject.vehicle.inJeep;
			
			_chassis = jeep.getChildByName( "chassis" );
			_hull = jeep.getChildByName( "hull" );
			_top = jeep.getChildByName( "top" );
			_roof = jeep.getChildByName( "roof" ); 
			
			setPreviousDisplayPositions();
		}
		
		/**
		 * Use getter to cast node to TopDownCollisionNode.
		 */
		public function get node():TopDownCollisionNode
		{
			return TopDownCollisionNode( super._node );
		}
		
		override public function start():void {}
		
		override public function update( time:Number ):void
		{			
			
			setPreviousDisplayPositions();
			node.spatial.scaleY = node.spatial.scaleX;
			
			// TAPER VARIABLES
			if( _magnitudeY > 0 )
			{
				_magnitudeY -= .03;
			}
			else
			{
				_magnitudeY = 0;
			}
			if( _ySpeedOffset > 0 )
			{
				_ySpeedOffset --;
			}
			else
			{
				_ySpeedOffset = 0;
			}
		}
		
		protected function carDriveMovement():void
		{
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			if( state.type != JUMP )
			{
				setXTilt();
			}
			
			_tiltY += node.motion.velocity.y * .01;
			
			_chassis.y = previousChassisPos.y - ( _magnitudeY / 8 ) * Math.sin( _tiltY );
			_hull.y = previousHullPos.y + ( _magnitudeY / 8 ) * Math.sin( _tiltY );
			_top.y = previousHullPos.y + ( _magnitudeY / 2 ) * Math.sin( _tiltY );
			_roof.y = previousRoofPos.y + _magnitudeY * Math.sin( _tiltY );
			
			_chassis.x = -( magnitudeX / 8 ) * Math.sin( _tiltX );
			_hull.x = ( magnitudeX / 8 ) * Math.sin( _tiltX );
			_top.x = ( magnitudeX / 2 ) * Math.sin( _tiltX );
			_roof.x = magnitudeX * Math.sin( _tiltX );
			
			//jeep.hull._yscale = 98 + 2*Math.cos(tY*2);
			//			jeep.inJeep.top._yscale = (100 - magY/2) + (magY/2)*Math.cos(tY*2);
			//			jeep.inJeep.roof._yscale = (100 - magY/4) + (magY/4)*Math.cos(tY*2);
			//			jeep.inJeep.roof.windshield._yscale = (100 + magY*6) + (magY*6)*Math.sin(tY);
		}
		
		protected function setXTilt():void
		{
			var deltaY:Number = Math.abs( node.motionTarget.targetY - node.spatial.y );
			_tiltX = ( node.motionTarget.targetY - node.spatial.y ) / 300;
			
			var dampening:Number;
			
			if( !node.motionControl.moveToTarget || deltaY < 40 )
			{
				_tiltX = 0;
				
				if( !node.motionControl.moveToTarget )
				{
					if( node.spatial.rotation != 0 || node.motion.velocity.y != 0 )
					{
						dampening = node.spatial.rotation / 8;
						if( Math.abs( dampening ) < .1 )
						{
							dampening = node.spatial.rotation;
						}
						
						node.spatial.rotation -= dampening;
						
						dampening = node.motion.velocity.y / 13;
						if( Math.abs( dampening ) < .1 )
						{
							dampening = node.motion.velocity.y;
						}
						node.motion.velocity.y -= dampening; 
					}
				}
			}
		
			//-45
			if( node.spatial.rotation < -30 )
			{
				node.spatial.rotation += .4;
			}
					
			else if( node.spatial.rotation > 30 )
			{
				//45
				node.spatial.rotation -= .4;
			}
			else
			{
				node.spatial.rotation += _tiltX;
			}
		}
		
		override public function check():Boolean
		{
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			
			if( state.type != FALL )
			{
				switch( node.collider.collisionType )
				{
					case TopDownHitTypes.BUMP:
						return bumpHit();
					
					case TopDownHitTypes.CULVERT:
						return culvertHit();
					
					case TopDownHitTypes.CURB: 
						return curbHit();
					
					case TopDownHitTypes.CURB_EDGE: 
						return curbEdgeHit();
					
					case TopDownHitTypes.HOLE:
						return holeHit();
					
					case TopDownHitTypes.ITEM:
						return itemHit();
					
					case TopDownHitTypes.JUMP:
						return jumpHit();
					
					case TopDownHitTypes.WALL:
						return wallHit();
				}
			}
			return false;
		}
		
		protected function bumpHit():Boolean
		{
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			if( state.type != JUMP && state.type != FALL && state.type != IN_CULVERT )
			{
				if( !_inCulvert )
				{
					if( _magnitudeY < .24 )
					{
						_magnitudeY += .08;
					}
					
					node.timeline.gotoAndPlay( "driveOff" );
					return true;
				}
			}
			
			return false;
		}
		
		// CAR IN CULVERT
		protected function culvertHit():Boolean
		{
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			if( state.type != JUMP && state.type != IN_CULVERT )
			{
				if( node.spatial.x < node.collider.hitSpatial.x )
				{
					node.fsmControl.setState( IN_CULVERT );
					return true;
				}
			}
			
			return false;
		}
		
		// CAR HIT A CURB
		protected function curbHit():Boolean
		{
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			if( state.type != FALL && state.type != IN_CULVERT )
			{
				// HIT FROM BOTTOM
				if( node.spatial.y > node.collider.hitSpatial.y + node.collider.hitEdge.rectangle.bottom )
				{
					if( state.type == JUMP && node.spatial.y > 250 && node.motion.velocity.y < 0 )
					{
						return false;
					}
					// SOME ABRITRARY BOUNCE NUMBER
					node.motion.velocity.y = CURB_BOUNCE;
					node.motion.y = node.motion.previousY + 20; //node.collider.hitMotion.y + .5 * node.collider.hitSpatial.height + node.spatial.height * .5;
					resetDirection();
					
					if( node.timeline.currentIndex == 0 )
					{
						node.motionControl.moveToTarget = false;
						node.motionControl.lockInput = true;
						_spinning = true;
						
						clearHandlers();
						node.timeline.gotoAndPlay( "hitTop" );
						node.timeline.handleLabel( "ending", regainControl );
					}
					
					node.spatial.rotation = 5;
					return true;
				}
					
			}
			
			if( _spinning )
			{
				return true;
			}
			
			return false;
		}
		
		// CAR HIT A CURB EDGE
		protected function curbEdgeHit():Boolean
		{
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			if( state.type != JUMP )
			{
				if( _ySpeedOffset < 10 )
				{
					_ySpeedOffset += 4;
				}
				if( _magnitudeY < .15 )
				{
					_magnitudeY += .08;
				}
				
				node.fsmControl.setState( SPIN );
				resetDirection();
				return true;
			}
			
			return false;
		}
		
		// CAR HIT A HOLE
		protected function holeHit():Boolean
		{
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			if( state.type != JUMP && node.spatial.x < node.collider.hitSpatial.x )
			{
				node.fsmControl.setState( FALL );
				return true;
			}

			return false;
		}
		
		// CAR HIT A JUMP
		protected function jumpHit():Boolean
		{
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			if( state.type != JUMP )
			{
				node.fsmControl.setState( TopDownDriverState.JUMP );
				return true;
			}
			
			return false;
		}
		
		// CAR HIT AN ITEM
		protected function itemHit():Boolean
		{
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			if( state.type != JUMP )
			{
				if( node.timeline.playing )
				{
					return false;
				}
		
				node.motion.velocity.y += Math.random() * 40 - 20;
				node.motionMaster.velocity.x -= 100;
				
				if( _magnitudeY < .24 )
				{
					_magnitudeY += .08;
				}
				
				if( node.motionControl.lockInput )
				{
					node.motionControl.lockInput = false;
				}
				
				clearHandlers();
				resetDirection();
				node.timeline.gotoAndPlay( "spin" );
				node.timeline.handleLabel( "hitTop", resetDrivingAnimation );
			}
			return true;
		}
		
		// CAR HIT A WALL
		private function wallHit():Boolean
		{
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			if( state.type != FALL )
			{
				if( node.spatial.x < node.collider.hitSpatial.x + node.collider.hitEdge.rectangle.left )
				{ 
					if( node.motionMaster.velocity.x < 0 )
					{
						node.motionMaster.velocity.x = REBOUND;
						node.motionMaster.previousAcceleration.x = 0;
					}
					if( _ySpeedOffset < 20 )
					{
						_ySpeedOffset += 5;
					}
					
					if( _magnitudeY < .15 )
					{
						_magnitudeY += .08;
					}
					
					node.fsmControl.setState( SPIN );
					return true;
				}
				
				if( node.spatial.y < node.collider.hitSpatial.y )//- node.collider.hitEdge.rectangle.top )
				{
					node.motion.velocity.y = -REBOUND;
					resetDirection();
				}
					
				if( node.spatial.y > node.collider.hitSpatial.y )//+ node.collider.hitEdge.rectangle.bottom )
				{
					node.motion.velocity.y = REBOUND;
					resetDirection();
				}
			}	
			
			return true;
		}
		
		// UTILITY FUNCTIONS
		protected function resetDrivingAnimation():void
		{
			node.spatial.rotation = 0;
			node.timeline.gotoAndStop( 0 );
			
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			if( state.type != DRIVE && state.type != IN_CULVERT )
			{
				node.fsmControl.setState( DRIVE );
			}
		}			
		
		protected function clearHandlers():void
		{
			// REMOVE OTHER LABEL HANDLERS LEST WE GET STUCK INVISIBLE
			while( node.timeline.labelHandlers.length > 0 )
			{
				node.timeline.labelHandlers.pop();
			}
		}
			
		protected function regainControl():void
		{
			node.motionControl.lockInput = false;
			if( node.motionControl.inputStateDown )
			{
				node.motionControl.moveToTarget = true;
			}
			_spinning = false
		}

		protected function toggleMoveToTargetOn( input:Input = null ):void
		{
			var state:TopDownDriverState = node.fsmControl.state as TopDownDriverState;
			if( state.type != JUMP && state.type != FALL && state.type != SPIN )
			{
				node.motionControl.moveToTarget = true;
			}
		}
		
		protected function toggleMoveToTargetOff( input:Input = null ):void
		{
			node.motionControl.moveToTarget = false;
		}
		
		protected function setPreviousDisplayPositions():void
		{
			previousChassisPos = new Point( _chassis.x, _chassis.y );
			previousHullPos = new Point( _hull.x, _hull.y );
			previousTopPos = new Point( _top.x, _top.y );
			previousRoofPos = new Point( _roof.x, _roof.y );
		}
		
		protected function resetDirection():void
		{
			_tiltX = 0;
			_tiltY = 0;
			
			_chassis.y = previousChassisPos.y - ( _magnitudeY / 8 ) * Math.sin( _tiltY );
			_hull.y = previousHullPos.y + ( _magnitudeY / 8 ) * Math.sin( _tiltY );
			_top.y = previousHullPos.y + ( _magnitudeY / 2 ) * Math.sin( _tiltY );
			_roof.y = previousRoofPos.y + _magnitudeY * Math.sin( _tiltY );
			
			_chassis.x = -( magnitudeX / 8 ) * Math.sin( _tiltX );
			_hull.x = ( magnitudeX / 8 ) * Math.sin( _tiltX );
			_top.x = ( magnitudeX / 2 ) * Math.sin( _tiltX );
			_roof.x = magnitudeX * Math.sin( _tiltX );
		}
	}
}