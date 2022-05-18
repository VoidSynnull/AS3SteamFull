package game.creators.scene
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.components.entity.Sleep;
	import game.components.motion.Looper;
	import game.components.motion.LoopingSegment;
	import game.components.motion.MotionWrap;
	import game.components.motion.SegmentPattern;
	import game.data.scene.CameraLayerData;
	import game.data.scene.hit.HitData;
	import game.data.scene.hit.LooperHitData;
	import game.managers.ScreenManager;
	import game.components.entity.MotionMaster;
	import game.util.DataUtils;
	import flash.display.MovieClip;

	public class MotionLayerCreator
	{
		private var tileControl:Vector.<Object>;
		
		public function MotionLayerCreator(){}

			// ADD LOOPING LOGIC TO MOVING LAYERS
		public function addLayerMotion( scene:Scene, motionMaster:MotionMaster, layer:Entity, layerData:CameraLayerData, isFirst:Boolean = false ):void
		{
			var boundsCheck:Number;
			var display:Display = layer.get( Display );
			var groupNumber:Number = -1;
			var layerObject:Object;			// SubGroup , awake , width/height , entity
			var motionWrap:MotionWrap;
			var number:uint;
			var placement:Point;
			var segmentPattern:SegmentPattern;
			var sleep:Sleep;
			var spatial:Spatial;

				// USE PLAYERS MOTION MASTER TO CONTROL THE SPEED OF THE WHOLE SCENE
			if( motionMaster.velocity || motionMaster.acceleration )
			{
				motionWrap = layer.get( MotionWrap );
				if( !motionWrap )
				{
					motionWrap = new MotionWrap( display.displayObject, layerData.align, layerData.subGroup, layerData.motionRate, layerData.autoStart );
					layer.add( motionWrap ).add( new Motion());
				}
				
				motionWrap.velocity = new Point( motionMaster.velocity.x * layerData.motionRate, motionMaster.velocity.y * layerData.motionRate );
				motionWrap.maxVelocity = new Point( motionMaster.minVelocity.x * layerData.motionRate, motionMaster.minVelocity.y * layerData.motionRate );
				motionWrap.maxVelocity = new Point( motionMaster.maxVelocity.x * layerData.motionRate, motionMaster.maxVelocity.y * layerData.motionRate );
				motionWrap.acceleration = new Point( motionMaster.acceleration.x * layerData.motionRate, motionMaster.acceleration.y * layerData.motionRate );
		
				sleep = layer.get( Sleep );
				if( !sleep )
				{
					sleep = new Sleep( true, true );
					layer.add( sleep );
				}
					// IF WE DO NOT HAVE A LIST OF SUBGROUPS, CREATE THEM AND PAY ATTENTION TO WIDTH FOR ALIGNMENT
				if( !tileControl )
				{
					tileControl = new Vector.<Object>;
				}
				
					// FIND THE SUBGROUP IF ONE ALREADY EXISTS
				for( number = 0; number < tileControl.length; number++ )
				{
					layerObject = tileControl[ number ];
					if( motionWrap.subGroup == layerObject[ 0 ])
					{
						groupNumber = number;
					}
				}
				
					// IF THIS IS THE FIRST INSTANCE OF THIS SUBGROUP 
					// WAKE THIS LAYER AND FIND OUT IF IT IS OVER THE WIDTH LIMIT
				spatial = layer.get( Spatial );
				if( groupNumber < 0 )
				{
					motionWrap.active = true;
					sleep.sleeping = false;
					
					if( motionWrap.velocity.x != 0 )
					{
						boundsCheck = scene.sceneData.bounds.right;
						
						if( display.displayObject.width > boundsCheck )
						{
							tileControl.push([ motionWrap.subGroup, true, display.displayObject.width, layer ]);
							motionWrap.isLast = true;
						}
						else
						{
							tileControl.push([ motionWrap.subGroup, false, display.displayObject.width, layer ]);
						}	
					}
						
					else
					{							
						boundsCheck = scene.sceneData.bounds.bottom;
						
						if( motionWrap.velocity.y > 0 )
						{
							spatial.y = scene.shellApi.camera.viewportHeight - spatial.height;
						}
						
						if( display.displayObject.height > boundsCheck )
						{
							tileControl.push([ motionWrap.subGroup, true, display.displayObject.height, layer ]);
							motionWrap.isLast = true;
						}
						else
						{
							tileControl.push([ motionWrap.subGroup, false, display.displayObject.height, layer ]);
						}	
					}
				}
					
					// IF NOT THE FIRST INSTANCE OF THIS SUBGROUP
					// DETERMINE IF ON-SCREEN AND HANDLE SLEEP ACCORDINGLY
				else
				{
					layerObject = tileControl[ groupNumber ];
					
					if( motionWrap.velocity.x != 0 )
					{
						boundsCheck = scene.sceneData.bounds.right;
						
						checkWrapWake( layer, display.displayObject.width, boundsCheck, layerObject );
					}
						
					else
					{
						boundsCheck = scene.sceneData.bounds.bottom;
						
						checkWrapWake( layer, display.displayObject.height, boundsCheck, layerObject );
					}
				}
			}
			
				
				// IF WE DID NOT HAVE AN END TO THE SUB-GROUP, MAKE THE LAST LAYER IN THE GROUP THE END
				// NEED THIS TO DETERMINE WHICH LAYER TO CHECK FOR WAKING FURTHER LAYERS IN THE GROUP
			if( tileControl )
			{
				for( groupNumber = 0; groupNumber < tileControl.length; groupNumber ++ )
				{
					layerObject = tileControl[ groupNumber ];
					
					if( !layerObject[ 1 ])
					{
						layer = layerObject[ 3 ];
						motionWrap = layer.get( MotionWrap );
						sleep = layer.get( Sleep );
						
						motionWrap.active = true;
						sleep.sleeping = false;
						motionWrap.isLast = true;
						
						layerObject[ 1 ] = true;
					}
				}
			}
			
			var loopingSegment:LoopingSegment = layer.get( LoopingSegment );
			if( loopingSegment )
			{
				if( isFirst )
				{
					segmentPattern = loopingSegment.staticHitPattern;
					
					if( segmentPattern.obstacleSleeps.length > 0 )
					{
						for( number = 0; number < segmentPattern.obstacleSleeps.length; number ++ )
						{
							sleep = segmentPattern.obstacleSleeps[ number ];
							spatial = segmentPattern.obstacleSpatials[ number ];
							placement = segmentPattern.obstaclePlacements[ number ];
							
							spatial.x = placement.x;
							spatial.y = placement.y;
							sleep.sleeping = false;
						}
					}
					
					if( loopingSegment.obstaclePattern.length > 0 )
					{
						segmentPattern = loopingSegment.obstaclePattern[ 0 ];
						
						if( segmentPattern.obstacleSleeps.length > 0 )
						{
							for( number = 0; number < segmentPattern.obstacleSleeps.length; number ++ )
							{
								sleep = segmentPattern.obstacleSleeps[ number ];
								spatial = segmentPattern.obstacleSpatials[ number ];
								placement = segmentPattern.obstaclePlacements[ number ];
								
								spatial.x = placement.x;
								spatial.y = placement.y;
								sleep.sleeping = false;
							}
						}
					}
				}
				
			//	else
			//	{
			//		segmentPattern = loopingSegment.staticHitPattern;
			//		for( number = 0; number < segmentPattern.obstacleSleeps.length; number ++ )
			//		{
			//			sleep = segmentPattern.obstacleSleeps[ number ];
			//			spatial = segmentPattern.obstacleSpatials[ number ];
			//			placement = segmentPattern.obstaclePlacements[ number ];
			//			
			//			spatial.x = placement.x;
			//			spatial.y = placement.y;
			//			sleep.sleeping = true;
			//		}
			//		
			//		segmentPattern = loopingSegment.obstaclePattern[ 0 ];
			//		for( number = 0; number < segmentPattern.obstacleSleeps.length; number ++ )
			//		{
			//			sleep = segmentPattern.obstacleSleeps[ number ];
			//			spatial = segmentPattern.obstacleSpatials[ number ];
			//			placement = segmentPattern.obstaclePlacements[ number ];
			//			
			//			spatial.x = placement.x;
			//			spatial.y = placement.y;
			//			sleep.sleeping = true;
			//		}
			//	}
			}
			
			motionWrap.isFirst = isFirst;
		}
		
			// POSITION LAYERS BASED ON OTHER LAYERS IN THIS SUBGROUP
		private function checkWrapWake( layer:Entity, length:Number, boundsCheck:Number, layerObject:Object ):void
		{
			var spatial:Spatial = layer.get( Spatial );
			var motion:Motion = layer.get( Motion );
			var motionWrap:MotionWrap = layer.get( MotionWrap );
			var sleep:Sleep = layer.get( Sleep );
//			var negative:Boolean = false;
			
			if( motionWrap.align )
			{
				if( motionWrap.velocity.x != 0 )
				{
					if( motionWrap.velocity.x < 0 ) 
					{
						spatial.x = layerObject[ 2 ];
					}
					else
					{
						spatial.x = -spatial.width;
					}
				}
				else
				{
					if( motionWrap.velocity.y < 0 ) 
					{
						spatial.y = layerObject[ 2 ];
					}
					else
					{
						spatial.y = -layerObject[ 2 ];
					}
				}
//				if( motionWrap.velocity.y < 0 || motionWrap.velocity.x < 0 )
//				{
//					layerObject[ 2 ] += length;
//				}
//				else
//				{
					layerObject[ 2 ] += length;
//				}
			}
			else
			{
				var unalignedLength:Number = ScreenManager.GAME_WIDTH * .5;
				spatial.x = unalignedLength;
				spatial.y = Math.random() * ScreenManager.GAME_HEIGHT;
				
				layerObject[ 2 ] += unalignedLength;
			}
			
			layerObject[ 3 ] = layer;
			if( layerObject[ 2 ] < boundsCheck )
			{
				motionWrap.active = true;
				sleep.sleeping = false;
			}
			else if( !layerObject[ 1 ])
			{
				motionWrap.active = true;
				sleep.sleeping = false;
				motionWrap.isLast = true;
				
				layerObject[ 1 ] = true;
			}
		}
		
			// ADD LOOPING LOGIC TO THE HITS
		public function addLoopingHitMotion( scene:Scene, motionMaster:MotionMaster, hit:Entity, looperHitData:LooperHitData = null ):void
		{
			var id:Id = hit.get( Id );
			var looper:Looper = hit.get( Looper );
			var spatial:Spatial = hit.get( Spatial );
			if( !looperHitData )
			{
				var hitData:HitData = hit.get( HitData );
				looperHitData = hitData.components[ "looper" ];
			}
			
			looper.acceleration = new Point( motionMaster.acceleration.x, motionMaster.acceleration.y );
			looper.velocity = new Point( motionMaster.velocity.x, motionMaster.velocity.y );
			looper.minVelocity = new Point( motionMaster.minVelocity.x, motionMaster.minVelocity.y );
			looper.maxVelocity = new Point( motionMaster.maxVelocity.x, motionMaster.maxVelocity.y );
			looper.visualHeight = looperHitData.visualHeight;
			looper.visualWidth = looperHitData.visualWidth;
			looper.event = looperHitData.event;
			looper.isLast = looperHitData.lastObject;
		}
		
		public function createMotionMaster( scene:Scene, sourceData:XML, progressClip:MovieClip = null):MotionMaster
		{
			var motionMaster:MotionMaster;
			
			if( sourceData )
			{
				motionMaster = new MotionMaster();
				// DETERMINE DIRECTION
				motionMaster.direction = DataUtils.getString( sourceData.direction );
				motionMaster.axis = DataUtils.getString( sourceData.axis );
				
				var modifier:Number = motionMaster.direction == "+" ? 1 : -1;
				
				// DETERMINE AXIS
				if( motionMaster.axis == "x" )
				{
					motionMaster.velocity = new Point( DataUtils.useNumber( sourceData.velocity, 0 ) * modifier, 0 );
					motionMaster.minVelocity = new Point( DataUtils.useNumber( sourceData.minVelocity, 0 ), 0 ); 
					motionMaster.maxVelocity = new Point( DataUtils.useNumber( sourceData.maxVelocity, 0 ), 0 ); 
					motionMaster.acceleration = new Point( DataUtils.useNumber( sourceData.acceleration, 0 ) * modifier, 0 ); 					
				}
				else
				{
					motionMaster.velocity = new Point( 0, DataUtils.useNumber( sourceData.velocity, 0 ) * modifier );
					motionMaster.minVelocity = new Point( 0, DataUtils.useNumber( sourceData.minVelocity, 0 )); 
					motionMaster.maxVelocity = new Point( 0, DataUtils.useNumber( sourceData.maxVelocity, 0 )); 
					motionMaster.acceleration = new Point( 0, DataUtils.useNumber( sourceData.acceleration, 0 ) * modifier ); 
				}
				
				motionMaster.goalDistance = DataUtils.useNumber( sourceData.goalDistance, NaN );
				motionMaster.bgOffset = DataUtils.useNumber( sourceData.bgOffset, 0 );
				
				// setup progress bar
				if (progressClip)
				{
					motionMaster.progressDisplay = progressClip;
					motionMaster.progressLength = motionMaster.axis == "x"? progressClip.width:progressClip.height;
				}
			}
			
			return motionMaster;
		}
	}
}