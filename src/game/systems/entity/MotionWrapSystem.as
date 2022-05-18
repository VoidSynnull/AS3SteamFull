package game.systems.entity
{
	 import ash.core.Engine;
	 import ash.core.Entity;
	 
	 import engine.components.Camera;
	 import engine.components.Motion;
	 import engine.components.Spatial;
	 import engine.components.SpatialOffset;
	 
	 import game.components.entity.Sleep;
	 import game.components.motion.LoopingSegment;
	 import game.components.motion.MotionWrap;
	 import game.components.motion.SegmentPattern;
	 import game.data.motion.time.FixedTimestep;
	 import game.nodes.motion.MotionWrapNode;
	 import game.components.entity.MotionMaster;
	 import game.systems.GameSystem;
	 import game.systems.SystemPriorities;
	 
	 import org.osflash.signals.Signal;
	 
	public class MotionWrapSystem extends GameSystem
	{
		public function MotionWrapSystem()
		{
		 	super( MotionWrapNode, updateNode, nodeAdded )
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.moveControl;
		}
		 
		override public function addToEngine( systemManager:Engine ):void
		{
			_camera = group.shellApi.camera.camera;
			_head = systemManager.getNodeList( MotionWrapNode ).head as MotionWrapNode;
			
			var player:Entity = group.shellApi.player;
			_motionMaster = player.get( MotionMaster );
			
			finalTile = new Signal();
			super.addToEngine( systemManager );
		}
		
		private function nodeAdded( node:MotionWrapNode ):void
		{
			node.motionWrap.createMotion( node );
		}
		 
		private function updateNode( node:MotionWrapNode, time:Number ):void
		{
			var motionWrap:MotionWrap = node.motionWrap;
			var motion:Motion = node.motion;
			var sleep:Sleep = node.sleep;
			var spatial:Spatial = node.spatial;
			var cameraOffset:Number = 0;
			
			
				// CHECK THAT THE MOTION IS CORRECT AGAINST THE PLAYER'S MOTION MASTER
			if( motionWrap.axis == motionWrap.X_AXIS )
			{
				if( motion.velocity.x != _motionMaster.velocity.x )
				{
					motion.velocity.x = _motionMaster.velocity.x * motionWrap.motionRate;
	//				motionWrap.reposition = true;
				}
			}
			else
			{
				if( motion.velocity.y != _motionMaster.velocity.y )
				{
					motion.velocity.y = _motionMaster.velocity.y * motionWrap.motionRate;
	//				motionWrap.reposition = true;
				}
			}
			
				// REPOSITION PASS WHICH RUNS ONCE AFTER WOKEN FROM SLEEP TO MAKE 
				//  ALIGNED LAYERS FLUSH WITH PREVIOUS TILED LAYER			
			if( motionWrap.reposition )
			{
				// REPOSITIONING FOR NON-PATTERN CONTROLLED WRAPS
				if( motionWrap.axis == motionWrap.X_AXIS )
				{
					if( motion.velocity.x < 0 )
					{
						if( motionWrap.previousMotion )
						{
						 	spatial.x = motionWrap.previousMotion.x + motionWrap.previousSpatial.width + .25 * motionWrap.previousMotion.acceleration.x;
							spatial.y = motionWrap.previousSpatial.y;
						}
					}
					
					else
					{
						// TO DO :: REACHED THIS POINT WHEN HITTING A WALL IN TOP DOWN DRIVER SCENE
						trace( "trying to use a +x on reposition" );
					}
				}
				
				else
				{
					if( motion.velocity.y < 0 )
					{
						trace( "negative y reposition" );
					}
					else
					{
						if( motionWrap.previousMotion )
						{
							spatial.x = motionWrap.previousSpatial.x;//motionWrap.previousMotion.x + motionWrap.previousSpatial.width + .25 * motionWrap.previousMotion.acceleration.x;
							spatial.y = motionWrap.previousMotion.y - spatial.height + motionWrap.previousMotion.acceleration.y;
						}
						trace( "positive y reposition" );
					}
				}
				// REPOSITIONING FOR PATTERN CONTROLLED WRAPS
				if( node.loopingSegment )
				{
					var loopingSegment:LoopingSegment = node.loopingSegment;
					
					if( loopingSegment.patternNumber < loopingSegment.obstaclePattern.length )
					{
						var pattern:SegmentPattern = loopingSegment.staticHitPattern;
						
						// Reposition and wake all obstacles
						for( var number:uint = 0; number < pattern.obstacleSpatials.length; number ++ )
						{
							if( pattern.obstacleDisplays.length > number )
							{
								if( pattern.obstacleDisplays[ number ].alpha == 0 )
								{
									pattern.obstacleDisplays[ number ].alpha = 1;
								}
							}
							
							if( motionWrap.axis == motionWrap.X_AXIS )
							{					
								if( motion.velocity.x < 0 )
								{
									pattern.obstacleSpatials[ number ].x = spatial.x + pattern.obstaclePlacements[ number ].x;
									pattern.obstacleSpatials[ number ].y = spatial.y + pattern.obstaclePlacements[ number ].y;
								}
							}
							// TODO : Y AND +X MOTION
						}
					}
				}
				motionWrap.reposition = false;
			}
			 
			 	// ALL SUBSEQUENT PASSES WILL CHECK FOR WAKING NEXT LAYER IF IT IS LAST AND 
			 	// SLEEPING THIS LAYER IF IT GOES OVER
			else
			{
				if(( motionWrap.isLast ))// && _motionMaster.direction == "-" ) || ( motionWrap.isFirst && _motionMaster.direction == "+" ))
				{
					checkPosition( node );
				}
				 
					//	CHECK IF WE SHOULD PUT THIS LAYER TO SLEEP
				if( motionWrap.axis == motionWrap.X_AXIS )
				{
					cameraOffset = _camera.areaWidth + ( _camera.viewportWidth * .5 ) + _camera.layerOffsetX; 
					
					if( motion.velocity.x > 0 && _motionMaster.direction == "+" )
					{
						if( spatial.x > cameraOffset + spatial.width )	
						{
							setSleep( node );
						}
					}
					
					else if( motion.velocity.x < 0 && _motionMaster.direction == "-" )
					{
						if( spatial.x < -( cameraOffset + spatial.width ))
						{	
							setSleep( node );
						}
					}
			 	}
					 
				else
				{
					cameraOffset = 1.5 * _camera.viewportHeight + _camera.layerOffsetY; 
					
					if( motion.velocity.y > 0 )
					{
						if( spatial.y > cameraOffset + spatial.height )	
						{
 				// TO-DO  Make compatible for 1 layer sub-groups; just reset this guy instead of sleeping

					 		setSleep( node );
						}
					}
					else
					{
						if( spatial.y < -( cameraOffset + spatial.height ))
						{	
							setSleep( node );
						}
					}
				}
			}
		}
		 
			// DETERMINE IF WE SHOULD WAKE THE NEXT LAYER AND POSITION IT
		private function checkPosition( node:MotionWrapNode ):void
		{
			var testDiameter:Number;
			var questionedSize:Number;
			var questionedVelocity:Number; 
			
			var spatial:Spatial = node.spatial;
			var motion:Motion = node.motion;
			
			var nextMotionWrap:MotionWrap;
			var nextSleep:Sleep;
			var nextSpatial:Spatial;
			var nextMotion:Motion;
			 
			var nextNode:MotionWrapNode;
			var buffer:Number = 40;
			 
				// LAYERS WITH X-AXIS MOTION
			if( node.motionWrap.axis == node.motionWrap.X_AXIS )
			{
				testDiameter = _camera.areaWidth + buffer;
				questionedSize = spatial.width;
				questionedVelocity = motion.x + motion.acceleration.x;
				 
					// POSITIVE X-AXIS MOTION
				if( motion.velocity.x > 0 && _motionMaster.direction == "+" )
				{
					testDiameter = -buffer;
					 
					if( questionedVelocity > testDiameter )
					{
						wakeNextWrap( node, testDiameter );
					}
				}
					 
					// NEGATIVE X-AXIS MOTION
				else if( motion.velocity.x < 0 && _motionMaster.direction == "-" )
				{
					if( questionedVelocity + questionedSize < testDiameter )
					{
						wakeNextWrap( node, testDiameter );	
					}
				}
			}
					 
				// LAYERS WITH Y-AXIS MOTION
			else
			{
				testDiameter = _camera.areaHeight + buffer;
				questionedSize = spatial.height;
				questionedVelocity = motion.y  + motion.acceleration.y;
					 
					// POSITIVE Y-AXIS MOTION
				if( motion.velocity.y > 0 && _motionMaster.direction == "+" )
				{
					testDiameter = -buffer;
			//		var cameraOffset:Number = _camera.viewportHeight + ( _camera.viewportHeight * .5 ) + _camera.layerOffsetY; 
					if( questionedVelocity > testDiameter )//- cameraOffset )
					{
						wakeNextWrap( node, testDiameter );
					}
				}
					 
					// NEGATIVE Y-AXIS MOTION
				else
				{
					if( questionedVelocity + questionedSize < testDiameter )
					{
						wakeNextWrap( node, testDiameter );	
					}
				}
			}
		}
		
		private function wakeNextWrap( node:MotionWrapNode, unalignedPosition:Number = NaN ):void
		{
			var possibleChoices:Array = new Array();
			var spatial:Spatial = node.spatial;
			var motionWrap:MotionWrap = node.motionWrap;
			var motion:Motion = node.motion;
			 
			var nextNode:MotionWrapNode;
			var reposition:Number;
			var cameraOffset:Number;
			 
			// IF THERE IS NO PATTERN TO THE TILES
			if( !node.loopingSegment )
			{
				// GET A LIST OF ALL INACTIVE LAYERS IN THIS SUB-GROUP
				nextNode = _head;
				do{
					if( nextNode.motionWrap.subGroup == motionWrap.subGroup && !nextNode.motionWrap.active )
					{
						possibleChoices.push( nextNode );
					}
					nextNode = nextNode.next;
				}while( nextNode );
				 
				// IF THERE ARE ANY AVAILABLE TILES IN THIS SUB-GROUP, PICK ONE, POSITION IT AND WAKE IT
				if( possibleChoices.length > 0 )
				{
					nextNode = possibleChoices[ Math.round( Math.random() * ( possibleChoices.length - 1 ))];
					 
					// IF NEXT TILE LAYER IS SET TO HAVE FLUSH ALIGNMENT
					if( motionWrap.align )
					{
						// DETERMINE POSITIONING BASED ON AXIS-CHECK AND TILE HEIGHT/WIDTH
						if( motionWrap.axis == motionWrap.X_AXIS )//.velocity.x != 0 )
						{						
							reposition = spatial.width;
			//				if( motion.velocity.x > 0 )
			//				{
			//					reposition *= -1;
			//				}
								
			//				else
			//				{
			//					trace( "wake next layer on +x" );
			//				}
								
							nextNode.spatial.x = motion.x + reposition;
							nextNode.spatial.y = motion.y;
							nextNode.motion.velocity.x = _motionMaster.velocity.x * nextNode.motionWrap.motionRate;
						}
						else
						{
							reposition = spatial.height;
							 
							if( motion.velocity.y > 0 )
							{
								reposition *= -1;
							}
							nextNode.spatial.y = motion.y + reposition;
							
							// something about the camera is positiong them really low on the y
							nextNode.spatial.x = motion.x;
							nextNode.motion.velocity.y = _motionMaster.velocity.y * nextNode.motionWrap.motionRate;
						}
						
						// WAKE THE NEXT TILE, SET IT'S POSITION AND FLAG FOR REPOSITIONING
						nextNode.motionWrap.reposition = true;
						nextNode.motionWrap.previousMotion = motion;
						nextNode.motionWrap.previousSpatial = spatial;//motion.velocity.x;
					}
					 
					// IF WE DON'T WANT THE LAYER FLUSHED, WE CAN JUST POSITION AT THE FAR EDGE OPPOSITE IT'S MOTION
					else
					{
						if( motionWrap.axis == motionWrap.X_AXIS )
						{					
							if( motion.velocity.x < 0 )
							{
								nextNode.spatial.x = unalignedPosition + nextNode.spatial.width;// - _camera.layerOffsetX;
								nextNode.spatial.y = ( Math.random() * _camera.areaHeight ) - ( _camera.areaHeight * .5 );
							}
							else
							{
								nextNode.spatial.x = unalignedPosition - nextNode.spatial.width;// + _camera.layerOffsetX;
								nextNode.spatial.y = ( Math.random() * _camera.areaHeight ) - ( _camera.areaHeight * .5 );
							}
							
						}
						else
						{
							if( motion.velocity.y < 0 )
							{
								nextNode.spatial.y = unalignedPosition - nextNode.spatial.height;
							}
							else
							{
								cameraOffset = _camera.viewportHeight + ( _camera.viewportHeight * .5 ) + _camera.layerOffsetY; 
								nextNode.spatial.y = unalignedPosition - nextNode.spatial.height - cameraOffset;
							}
						}
					}	
					 
					// RESET ACTIVE AND ISLAST FLAGS FOR BOTH LAYERS
					motionWrap.isLast = false;
				/*
				*	motionWrap.nextMotion = nextNode.motion;
				*	motionWrap.nextSpatial = nextNode.spatial;
				*/
					nextNode.motionWrap.isLast = true;
					nextNode.motionWrap.active = true;
					nextNode.sleep.sleeping = false;
				}
			}
			
			// IF THERE IS A PATTERN THAT WE WANT THE TILES TO FOLLOW ( ASSUME FLUSH )
			else
			{
				var loopingSegment:LoopingSegment = node.loopingSegment;
				if( loopingSegment.patternNumber < loopingSegment.nextSegment.length )
				{
					var nextPatternNumber:uint = loopingSegment.nextSegment[ loopingSegment.patternNumber ].patternNumber;
					
					if( nextPatternNumber < loopingSegment.nextSegment[ loopingSegment.patternNumber ].obstaclePattern.length )
					{
						// TODO : Y AND +X MOTION
						var nextSegment:LoopingSegment = loopingSegment.nextSegment[ loopingSegment.patternNumber ];
						
						var nextSpatial:Spatial = loopingSegment.nextSpatial[ loopingSegment.patternNumber ];
						var nextMotion:Motion = loopingSegment.nextMotion[ loopingSegment.patternNumber ];
						var nextMotionWrap:MotionWrap = loopingSegment.nextWrap[ loopingSegment.patternNumber ];
						
						if( motionWrap.axis == motionWrap.X_AXIS )
						{
							if( motionWrap.velocity.x < 0 )
							{
								nextSpatial.x = node.motion.x + node.spatial.width;
							}
							else
							{
								nextSpatial.x = node.motion.x - nextSpatial.width;
							}
							
							nextSpatial.y = 0;
							
							nextMotion.velocity.x = _motionMaster.velocity.x * nextMotionWrap.motionRate;
						}
						else
						{
							if( motionWrap.velocity.y < 0 )
							{
								nextSpatial.y = node.motion.y + node.spatial.height;
							}
							else
							{
								nextSpatial.y = node.motion.y - nextSpatial.height;
							}
							
							nextSpatial.x = 0;
							
							nextMotion.velocity.y = _motionMaster.velocity.y * nextMotionWrap.motionRate;
						}
						
						var nextSleep:Sleep = loopingSegment.nextSleep[ loopingSegment.patternNumber ];
						nextSleep.sleeping = false;
						
						// Reposition and wake all dynamic obstacles
						var pattern:SegmentPattern = nextSegment.obstaclePattern[ nextPatternNumber ];
						for( var number:uint = 0; number < pattern.obstacleSpatials.length; number ++ )
						{
							if( pattern.obstacleDisplays.length > number )
							{
								if( pattern.obstacleDisplays[ number ].alpha == 0 )
								{
									pattern.obstacleDisplays[ number ].alpha = 1;
								}
							}
							
							if( motionWrap.axis == motionWrap.X_AXIS )
							{					
								if( motion.velocity.x < 0 )
								{
									pattern.obstacleSpatials[ number ].x = node.motion.x + node.spatial.width + pattern.obstaclePlacements[ number ].x;
									pattern.obstacleSpatials[ number ].y = node.motion.y + pattern.obstaclePlacements[ number ].y;
							
									pattern.obstacleSleeps[ number ].sleeping = false;
								}
								
								// TODO :: +X MOTIONS
								else
								{
									trace( "reposition static segment obstacles on +x" );
								}
							}
							
							else
							{
								// TODO :: -Y MOTIONS
								if( motion.velocity.y < 0 )
								{
									trace( "reposition static segment obstacles on -y" );
								}
								
								else
								{
									pattern.obstacleSpatials[ number ].x = node.motion.x + pattern.obstaclePlacements[ number ].x;
									pattern.obstacleSpatials[ number ].y = node.motion.y - node.spatial.height + pattern.obstaclePlacements[ number ].y;
									
									pattern.obstacleSleeps[ number ].sleeping = false;
								}
							}
						} 
						
						// Reposition and wake all static obstacles	
						pattern = nextSegment.staticHitPattern;
						for( number = 0; number < pattern.obstacleSpatials.length; number ++ )
						{
							if( pattern.obstacleDisplays.length > number )
							{
								if( pattern.obstacleDisplays[ number ].alpha == 0 )
								{
									pattern.obstacleDisplays[ number ].alpha = 1;
								}
							}
							
							if( motionWrap.axis == motionWrap.X_AXIS )
							{					
								if( motion.velocity.x < 0 )
								{
									pattern.obstacleSpatials[ number ].x = node.motion.x + node.spatial.width + pattern.obstaclePlacements[ number ].x;
									pattern.obstacleSpatials[ number ].y = node.motion.y + pattern.obstaclePlacements[ number ].y;
									
									pattern.obstacleSleeps[ number ].sleeping = false;
								}
								
								else
								{
									trace( "reposition dynamic segment obstacles on +x" );
								}
								// TODO : Y AND +X MOTION
							}
						} 
						
						loopingSegment.patternNumber ++;
						
			//			motionWrap.nextMotion = nextMotion;
			//			motionWrap.nextSpatial = nextSpatial;
						
						nextMotionWrap.reposition = true;
						nextMotionWrap.previousMotion = motion;
						nextMotionWrap.previousSpatial = spatial;
						
						motionWrap.isLast = false;
						nextMotionWrap.isLast  = true;
						nextMotionWrap.active = true;
					}
				}
				else
				{
					motionWrap.isLast = false;
					finalTile.dispatch();
				}
			}
		}
		 
		private function setSleep( node:MotionWrapNode ):void
		{
			node.motionWrap.active = false;
			node.sleep.sleeping = true;
		}
		 
		override public function removeFromEngine( systemManager:Engine ):void
		{
			systemManager.releaseNodeList( MotionWrapNode );
			_head = null;
			 
			super.removeFromEngine( systemManager );
		}
		 
		private var _camera:Camera;
		private var _head:MotionWrapNode;
		private var _motionMaster:MotionMaster;
		
		public var finalTile:Signal;
	}
}