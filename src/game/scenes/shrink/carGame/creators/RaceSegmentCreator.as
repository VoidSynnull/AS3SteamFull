package game.scenes.shrink.carGame.creators
{
	import com.greensock.easing.Elastic;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.entity.Sleep;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Looper;
	import game.components.motion.LoopingSegment;
	import game.components.motion.MotionWrap;
	import game.components.motion.SegmentPattern;
	import game.creators.scene.HitCreator;
	import game.data.display.BitmapWrapper;
	import game.managers.EntityPool;
	import game.scene.template.AudioGroup;
	import game.scenes.shrink.carGame.hitData.ObstacleData;
	import game.scenes.shrink.carGame.hitData.SegmentData;
	import game.scenes.shrink.carGame.hitTypes.TopDownHitTypes;
	import game.scenes.shrink.carGame.parsers.SegmentParser;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	
	import org.flintparticles.common.displayObjects.Rect;

	public class RaceSegmentCreator extends Group
	{
		private var _bitmapWrappers:Vector.<BitmapWrapper>;
		private var obstacleBitmaps:Dictionary = new Dictionary();
		private var segmentByBackground:Dictionary = new Dictionary();		
		private var _callbackFunction:Function = null;

		private var _usedObstacles:Dictionary 	= 	new Dictionary();
		private var OBSTACLE_NUMBER:Number 		= 	10;
		private var HIT:String 					= 	"Hit";
		private var VISUAL:String				= 	"Visual";
		
		private var _audioGroup:AudioGroup;
		private var _group:Group;
		
		// TESTING THIS OUT- IDEALLY, I WILL BE ABLE TO TAKE THEM AFTER CREATION AND ADD MOTION
		public var _pool:EntityPool;
		
		public function RaceSegmentCreator()
		{
			super();
			_bitmapWrappers = new Vector.<BitmapWrapper>;
		}
 
		override public function destroy():void
		{
			if( _bitmapWrappers )
			{
				for(var n:int = 0; n < _bitmapWrappers.length; n++)
				{
					BitmapWrapper(_bitmapWrappers[n]).destroy();
				}
				
				_bitmapWrappers.length = 0;
				_bitmapWrappers = null;
			}
		}
		
		/**
		 * Parses <code>XML</code> into segments to be used for top down racer scenes.
		 *  
		 * @param scene - owning <code>Group</code>.
		 * @param xml - <code>XML</code> that contains segment data about the obstacles.
		 * @param container - <code>DisplayObjectContainer</code> that the segments are contained in.
		 * @param entityPool - <code>EntityPool</code> maintaining all bitmapped obstacle entities.
		 * */
		public function createSegments( group:Group, xml:XML, container:DisplayObjectContainer, audioGroup:AudioGroup, callbackFunction:Function = null ):void//Vector.<Class>
		{
			var bitmapWrapper:BitmapWrapper;
			var motion:Motion;
			var segments:XMLList;
			var segmentData:SegmentData;
			var segmentEntity:Entity;
			var spatial:Spatial;
			var display:Display;
			var segment:XML;
			var nextSegment:XML;
			var nextSegmentData:SegmentData;
			var nextSegmentEntity:Entity;
			var clip:DisplayObjectContainer;
			var motionWrap:MotionWrap;
			var isFirst:Boolean = true;
			
			_audioGroup = audioGroup;
			
			if( xml )
			{
				_pool = new EntityPool();
				_group = group;
				segments = xml.children();
				
				for( var number:uint = 0; number < segments.length(); number ++ )
				{
					segment = segments[ number ];
					segmentData = SegmentParser.parse( segment );
					
					segmentEntity = segmentByBackground[ segmentData.backgroundClip ];
					if( !segmentEntity )
					{
						clip = parseStaticSegmentHits( segmentData, container[ segmentData.backgroundClip ]);
						
						bitmapWrapper = DisplayUtils.convertToBitmapSprite( clip );
						segmentEntity = EntityUtils.createMovingEntity( group, bitmapWrapper.sprite, container );
						display = segmentEntity.get( Display );
						segmentEntity.add( new Id( segmentData.backgroundClip )).add( new MotionWrap( display.displayObject, true, "segments", 1, true )).add( new Sleep( true, true ));
							
						createStaticSegmentObstacles( segmentEntity, segmentData, container );
						segmentByBackground[ segmentData.backgroundClip ] = segmentEntity;	
					}
					
					declareDynamicSegmentObstacles( segmentData, container );
				}
				
				// WE NEED THE ENTITIES ALREADY CREATED SO WE CAN FINISH STORING THE 
				// SEGMENT PATTERN INFORMATION
				for( number = 0; number < segments.length(); number ++ )
				{
					nextSegment = null;
					nextSegmentData = null;
					nextSegmentEntity = null;
					segment = segments[ number ];
					segmentData = SegmentParser.parse( segment );
					segmentEntity = group.getEntityById( segmentData.backgroundClip );
					
					if( number + 1 < segments.length())
					{	
						nextSegment = segments[ number + 1 ];
						nextSegmentData = SegmentParser.parse( nextSegment );
						nextSegmentEntity = group.getEntityById( nextSegmentData.backgroundClip );
					}
					
					assignDynamicSegmentObstacles( segmentEntity, nextSegmentEntity, segmentData, container, isFirst );
					
					isFirst = false;
				}
				
				_callbackFunction = callbackFunction;
				releaseTheExtras( container );
			}
		}
		
		/**
		 * Iterate through the children of the <code>DisplayObjectContainer</code> of the segment's background for collision hits.
		 * 
		 * @param segmentData - <code>SegmentData</code> to add data about the hits to.
		 * @param clip - <code>DisplayObjectContainer</code> of the segment art to iterate through.
		 * @return <code>DisplayObjectContainer</code> of the segment background art with all of the hit <code>MovieClips</code> removed.
		 */
		private function parseStaticSegmentHits( segmentData:SegmentData, clip:DisplayObjectContainer ):DisplayObjectContainer
		{
			var obstacleClip:MovieClip;
			var indexOfHit:int;
			var indexOfVisual:int;
			
			var obstacleData:ObstacleData;
			var clipName:String;
			var hitsToRemove:Vector.<MovieClip> = new Vector.<MovieClip>;
			
			for( var number:uint = 0; number < clip.numChildren; number ++ )
			{
				clipName = clip.getChildAt( number ).name;
				indexOfHit = clipName.indexOf( HIT );
				indexOfVisual = clipName.indexOf( VISUAL );
				
				if( indexOfHit > -1 || indexOfVisual > -1 )
				{ 
					obstacleClip = clip.getChildAt( number ) as MovieClip;
					
					if( !segmentData.hitObstacles )
					{
						segmentData.hitObstacles = new Vector.<ObstacleData>;
					}
					
					obstacleData = new ObstacleData();
					obstacleData.bounds = new Rectangle( obstacleClip.x, obstacleClip.y, obstacleClip.width, obstacleClip.height );
					obstacleData.x = obstacleClip.x;
					obstacleData.y = obstacleClip.y;
					
					obstacleData.type = indexOfHit > -1 ? clipName.substr( 0, indexOfHit ) : clipName.substr( 0, indexOfVisual );
					obstacleData.clipName = clipName;
					
					segmentData.hitObstacles.push( obstacleData );
					hitsToRemove.push( obstacleClip );

					if( indexOfVisual > -1 )
					{
						obstacleData.wrapper = DisplayUtils.convertToBitmapSprite( clip.getChildAt( number ), null, NaN, false );
					}
				}
			}
			
			while( hitsToRemove.length > 0 )
			{
				obstacleClip = hitsToRemove.pop();	
				clip.removeChild( obstacleClip );
			}
			
			return( clip );
		}
		
		
		/**
		 * Create the hit <code>Entities</code> defined by the <code>ObstacleData</code>.
		 * 
		 * @param scene - owning <code>Group</code>.
		 * @param segmentEntity - <code>Entity</code> of the segment's background.
		 * @param container - <code>DisplayObjectContainer</code> that the segments are contained in.
		 */
		private function createStaticSegmentObstacles( segmentEntity:Entity, segmentData:SegmentData, container:DisplayObjectContainer ):void
		{
			var obstacleData:ObstacleData;
			var obstacleEntity:Entity;
		
			var loopingSegment:LoopingSegment = new LoopingSegment();
			var staticSegmentPattern:SegmentPattern = new SegmentPattern();
			
			if( segmentData.hitObstacles )
			{
				for( var number:uint = 0; number < segmentData.hitObstacles.length; number ++ )
				{
					obstacleData = segmentData.hitObstacles[ number ];
					obstacleEntity = getStaticHitType( obstacleData, container );
						
					if( obstacleData.type == TopDownHitTypes.FOREGROUND )
					{
						staticSegmentPattern.obstacleDisplays.push( obstacleEntity.get( Display ));
					}
					staticSegmentPattern.obstaclePlacements.push( new Point( obstacleData.x, obstacleData.y ));
					staticSegmentPattern.obstacleSpatials.push( obstacleEntity.get( Spatial ));
					staticSegmentPattern.obstacleSleeps.push( obstacleEntity.get( Sleep ));
//					staticSegmentPattern.obstacleLoopers.push( obstacleEntity.get( Looper ));
				}
			}
			loopingSegment.staticHitPattern = staticSegmentPattern;
			segmentEntity.add( loopingSegment );
		}

		private function getStaticHitType( obstacleData:ObstacleData, container:DisplayObjectContainer ):Entity
		{
			var edge:Edge;
			var entity:Entity = new Entity();
			var hitComponent:*;
			var color:uint;
			var display:Display;
			var alwaysOn:Boolean = false;
			var foregroundElement:Boolean = false;
			var creator:HitCreator = new HitCreator();
		
			switch( obstacleData.type )
			{
				case TopDownHitTypes.FOREGROUND:
					foregroundElement = true;
					break;
				
				case TopDownHitTypes.CURB:
					alwaysOn = true;
					break;
				
				case TopDownHitTypes.CURB_EDGE:
					alwaysOn = true;
					break;
				
				case TopDownHitTypes.WALL:
					alwaysOn = true;
					break;
				
				default:
					break;
			}
			
			if( foregroundElement )
			{
				display = new Display( obstacleData.wrapper.sprite, container );
			}
			else
			{
				display = new Display( new Rect( obstacleData.bounds.width, obstacleData.bounds.height, color ), container );
				display.alpha = 0;
			}
			
			edge = new Edge();
			edge.unscaled = display.displayObject.getBounds( display.displayObject );
			
			entity.add( display )
				.add( edge )
				.add( new Id( obstacleData.type ))
				.add( new Looper( NaN, NaN, true, alwaysOn, obstacleData.type ))
				.add( new Motion())
				.add( new Sleep( true, true ))
				.add( new Spatial( -display.displayObject.width, 0 ));
			
			if( hitComponent != null )
			{
				entity.add( hitComponent );
			}
			
			creator.addHitSoundsToEntity( entity, _audioGroup.audioData, _group.shellApi, obstacleData.type );
			_group.addEntity( entity );
			return entity;
		}
		
		/**	
		 * Create and maintain a <code>Dictionary</code> of bitmap data corresponding to obstacles with unique display.
		 * 
		 * @param segmentData - <code>SegmentData</code> containing obstacles that will be added to each segment.
		 * @param container - <code>DisplayObjectContainer</code> that the segments are contained in.
		 */
		private function declareDynamicSegmentObstacles( segmentData:SegmentData, container:DisplayObjectContainer ):void
		{
			var clip:MovieClip;
			//var loopingSegment:LoopingSegment = segmentEntity.get( LoopingSegment );
			var bitmapWrapper:BitmapWrapper;
			var entity:Entity;
			var visualEntity:Entity;
			var obstacleData:ObstacleData;
			var number:uint;
			
			if( segmentData.obstacles )
			{
				for( number = 0; number < segmentData.obstacles.length; number ++ )
				{
					obstacleData = segmentData.obstacles[ number ];
					entity = _pool.request( obstacleData.clipName );
					
					if( !entity )
					{
						clip = container[ obstacleData.clipName ] as MovieClip;
						
						if( clip.hit )
						{
							clip.hit.alpha = 0;
							bitmapWrapper = DisplayUtils.convertToBitmapSprite( clip.hit, null, NaN, false );
							bitmapWrapper.sprite.name = obstacleData.clipName + HIT;
							
							obstacleBitmaps[ obstacleData.clipName + HIT ] = bitmapWrapper.sprite.name;
							
							_pool.setSize( obstacleData.clipName + HIT, OBSTACLE_NUMBER );
							entity = createDynamicObstacle( obstacleData.type, obstacleData.clipName + HIT, bitmapWrapper.sprite, container );
							Display( entity.get( Display )).alpha = 0;
	
							bitmapWrapper = DisplayUtils.convertToBitmapSprite( clip, null, NaN, false );
							bitmapWrapper.sprite.name = obstacleData.clipName;
							obstacleBitmaps[ obstacleData.clipName ] = bitmapWrapper.sprite.name;
							
							_pool.setSize( obstacleData.clipName, OBSTACLE_NUMBER );
							visualEntity = createDynamicObstacle( obstacleData.type, obstacleData.clipName, bitmapWrapper.sprite, container, entity );
							
							_pool.release( entity, obstacleData.clipName + HIT );
							_pool.release( visualEntity, obstacleData.clipName );
						}
							
						else
						{
							bitmapWrapper = DisplayUtils.convertToBitmapSprite( clip, null, NaN, false );
							bitmapWrapper.sprite.name = obstacleData.clipName;
							obstacleBitmaps[ obstacleData.clipName ] = bitmapWrapper.sprite.name;
								
							_pool.setSize( obstacleData.clipName, OBSTACLE_NUMBER );
							entity = createDynamicObstacle( obstacleData.type, obstacleData.clipName, bitmapWrapper.sprite, container, null);
							
							_pool.release( entity, obstacleData.clipName );
						}
					}
					else
					{
						_pool.release( entity, obstacleData.clipName );
					}
				}
			}
		}
		
		private function createDynamicObstacle( type:String, name:String, displayObject:DisplayObjectContainer, container:DisplayObjectContainer, target:Entity = null ):Entity
		{
			var alwaysOn:Boolean;
			var creator:HitCreator = new HitCreator();
			var display:Display;
			var edge:Edge;
			var entity:Entity;
			var spatial:Spatial;
			
			if( !target )
			{
				entity = EntityUtils.createMovingEntity( _group, displayObject, container );
				display = entity.get( Display );
				display.alpha = 0;
				
				spatial = entity.get( Spatial );
				//spatial.x = -spatial.width * 2;
				spatial.y = -spatial.height * 2;
				
				edge = new Edge();
				edge.unscaled = displayObject.getBounds( displayObject );
						
				alwaysOn = false;
				if( type == TopDownHitTypes.WALL )
				{
					alwaysOn = true;
				}
				
				entity.add( edge )
					.add( new Looper( NaN, NaN, true, alwaysOn, type ))
					.add( new Sleep( true, true ))
					.add( new Id( type ));
			
				creator.addHitSoundsToEntity( entity, _audioGroup.audioData, _group.shellApi, name );
			}
			
			else
			{
				entity = EntityUtils.createMovingEntity( _group, displayObject, container );
				entity.add( new FollowTarget( target.get( Spatial ))).add( new Id( name ));
				
				Looper( target.get( Looper )).visualEntity = entity;
			}
			
			return entity;
		}
	
		public function makeLooperObstacle( type:String, displayObject:DisplayObjectContainer, container:DisplayObjectContainer ):Entity
		{
			var alwaysOn:Boolean;
			var bitmapWrapper:BitmapWrapper;
			var creator:HitCreator = new HitCreator();
			var display:Display;
			var edge:Edge;
			var entity:Entity;
			var hitEntity:Entity;
			var spatial:Spatial;
			
			if( displayObject[ "hit" ])
			{
				// HIT ENTITY
				hitEntity = EntityUtils.createMovingEntity( _group, displayObject[ "hit" ], container );
				display = hitEntity.get( Display );
				display.alpha = 0;
				
				spatial = hitEntity.get( Spatial );
				spatial.x = -spatial.width * 2;
				spatial.y = -spatial.height * 2;
				
				edge = new Edge();
				edge.unscaled = displayObject.getBounds( displayObject );
				
				alwaysOn = false;
				if( type == TopDownHitTypes.WALL )
				{
					alwaysOn = true;
				}
				
				hitEntity.add( edge )
						.add( new Looper( NaN, NaN, true, alwaysOn, type ))
						.add( new Sleep( true, true ))
						.add( new Id( type ));
				
				creator.addHitSoundsToEntity( hitEntity, _audioGroup.audioData, _group.shellApi, displayObject.name + HIT );
			
				// VISUAL ENTITY
				bitmapWrapper = DisplayUtils.convertToBitmapSprite( displayObject, null, NaN, false );
				_bitmapWrappers.push( bitmapWrapper );
				bitmapWrapper.sprite.name = displayObject.name;
				
				entity = EntityUtils.createMovingEntity( _group, displayObject, container );
				
				var followTarget:FollowTarget = new FollowTarget( spatial );
				followTarget.properties.push( "rotation" );
				
				entity.add( followTarget ).add( new Id( displayObject.name + "Visual" ));
				
				return hitEntity;
			}
			
			return null;
		}
		/**
		 * Using the entity pool and dictionary of bitmaps, we will create extra entities as we need, maxing out at a specific number based on performance.
		 * 
		 * @param segmentEntity - <code>Entity</code> of the current segment we want to populate with dynamic obstacles.
		 * @param nextSegmentEntity - <code>Entity</code> for the next segment so the system knows what to call next.
		 * @param segmentData - <code>SegmentData</code> of dynamic obstacles for this segment on this iteration.
		 * @param container - <code>DisplayObjectContainer</code> that the segments are contained in.
		 * @param isFirst - <code>Boolean</code> flag to determine if obstacles should be asleep or not.
		 */
		private function assignDynamicSegmentObstacles( segmentEntity:Entity, nextSegmentEntity:Entity, segmentData:SegmentData, container:DisplayObjectContainer, isFirst:Boolean ):void
		{
			var bitmapWrapper:BitmapWrapper;
			var number:Number;
			var loopingSegment:LoopingSegment = segmentEntity.get( LoopingSegment );
			var obstacleData:ObstacleData;
			var segmentPattern:SegmentPattern = new SegmentPattern();
		
			var entity:Entity;
			
			var hitEntity:Entity;
			var visualEntity:Entity;
			
			var clip:MovieClip;
			var sleep:Sleep;
			
			if( segmentData.obstacles )
			{
				for( number = 0; number < segmentData.obstacles.length; number ++ )
				{
					entity = null;
					hitEntity = null;
					visualEntity = null;
					clip = null;
					
					obstacleData = segmentData.obstacles[ number ];
					clip = container[ obstacleData.clipName ] as MovieClip;
					
					if( obstacleBitmaps[ obstacleData.clipName + HIT ])
					{
						hitEntity = _pool.request( obstacleData.clipName + HIT );
						if( !hitEntity )
						{
							clip.hit.alpha = 1;
							bitmapWrapper = DisplayUtils.convertToBitmapSprite( clip.hit, null, NaN, false );
							bitmapWrapper.sprite.name = obstacleData.clipName + HIT;
							
							hitEntity = createDynamicObstacle( obstacleData.type, obstacleData.clipName + HIT, bitmapWrapper.sprite, container );
							clip.hit.alpha = 0;
						}
						
						visualEntity = _pool.request( obstacleData.clipName );
						if( !visualEntity )
						{
							bitmapWrapper = DisplayUtils.convertToBitmapSprite( clip, null, NaN, false );
							bitmapWrapper.sprite.name = obstacleData.clipName;
							
							visualEntity = createDynamicObstacle( obstacleData.type, obstacleData.clipName, bitmapWrapper.sprite, container, hitEntity );
						}
						
						if( !isFirst )
						{
							Display( visualEntity.get( Display )).alpha = 0;
						}
					}
					
					else
					{
						entity = _pool.request( obstacleData.clipName )
						if( !entity )
						{
							bitmapWrapper = DisplayUtils.convertToBitmapSprite( clip, null, NaN, false );
							bitmapWrapper.sprite.name = obstacleData.clipName;
							
							entity = createDynamicObstacle( obstacleData.type, obstacleData.clipName, clip, container );//, null, true );
						}
						
						if( !isFirst )
						{
							Display( entity.get( Display )).alpha = 0;
						}
					}
					
					if( !entity )
					{
						sleep = hitEntity.get( Sleep );
						if( !sleep )
						{
							trace( "hitEntity missing sleep component" );
						}
						segmentPattern.obstacleSleeps.push( hitEntity.get( Sleep ));
						segmentPattern.obstacleSpatials.push( hitEntity.get( Spatial ));
						segmentPattern.obstacleLoopers.push( hitEntity.get( Looper ));
						segmentPattern.obstacleDisplays.push( visualEntity.get( Display ));
					}
					
					else
					{
						sleep = entity.get( Sleep );
						if( !sleep )
						{
							trace( "entity missing sleep component" );
						}
						segmentPattern.obstacleSleeps.push( entity.get( Sleep ));
						segmentPattern.obstacleSpatials.push( entity.get( Spatial ));
//						segmentPattern.obstacleLoopers.push( entity.get( Looper ));
						segmentPattern.obstacleDisplays.push( entity.get( Display ));
					}
					
					segmentPattern.obstaclePlacements.push( new Point( obstacleData.x, obstacleData.y ));
					
					// MANAGE THE ENTITIES, DICTIONARIES AND ENTITY POOLS SO WE WILL ALWAYS HAVE ENOUGH OBSTACLE ENTITIES DURING THE GAME
					if( hitEntity )
					{					
						if( !_usedObstacles[ obstacleData.clipName + HIT ])
						{
							_usedObstacles[ obstacleData.clipName + HIT ] = new <Entity>[ hitEntity ];
						}
						else
						{
							if( _usedObstacles[ obstacleData.clipName + HIT ].length >= OBSTACLE_NUMBER )
							{
								while( _usedObstacles[ obstacleData.clipName + HIT ].length > 0 )
								{
									_pool.release( _usedObstacles[ obstacleData.clipName + HIT ].pop(), obstacleData.clipName + HIT );
								}
							}
							else
							{
								_usedObstacles[ obstacleData.clipName + HIT ].push( hitEntity );
							}
						}
				
						if( !_usedObstacles[ obstacleData.clipName ])
						{
							_usedObstacles[ obstacleData.clipName ] = new <Entity>[ visualEntity ];
						}
						else
						{
							if( _usedObstacles[ obstacleData.clipName ].length >= OBSTACLE_NUMBER )
							{
								while( _usedObstacles[ obstacleData.clipName ].length > 0 )
								{
									_pool.release( _usedObstacles[ obstacleData.clipName ].pop(), obstacleData.clipName );
								}
							}
							else
							{
								_usedObstacles[ obstacleData.clipName ].push( visualEntity );
							}
						}
					}
					
					else
					{
						if( !_usedObstacles[ obstacleData.clipName ])
						{
							_usedObstacles[ obstacleData.clipName ] = new <Entity>[ entity ];
						}
						else
						{
							if( _usedObstacles[ obstacleData.clipName ].length >= OBSTACLE_NUMBER )
							{
								while( _usedObstacles[ obstacleData.clipName ].length > 0 )
								{
									_pool.release( _usedObstacles[ obstacleData.clipName ].pop(), obstacleData.clipName );
								}
							}
							else
							{
								_usedObstacles[ obstacleData.clipName ].push( entity );
							}
						}
					}
				}
			}
			// If there is a next segment, record pertinant information.
			// The game is over when we reach a segment without a next segment.
			// If there is a next segment, record pertinant information.
			// The game is over when we reach a segment without a next segment.
			if( nextSegmentEntity )
			{
				loopingSegment.nextWrap.push( nextSegmentEntity.get( MotionWrap ));
				loopingSegment.nextSleep.push( nextSegmentEntity.get( Sleep ));
				loopingSegment.nextSegment.push( nextSegmentEntity.get( LoopingSegment ));
				loopingSegment.nextSpatial.push( nextSegmentEntity.get( Spatial ));
				loopingSegment.nextMotion.push( nextSegmentEntity.get( Motion ));
			}
			
			loopingSegment.obstaclePattern.push( segmentPattern );
		}
		
		/**
		 * Clean-up function.
		 * 
		* @param container - <code>DisplayObjectContainer</code> that the segments are contained in which we want to empty.
		  */
		private function releaseTheExtras( container:DisplayObjectContainer ):void
		{
			var vector:Vector.<Entity>;
			var bitmapWrapper:BitmapWrapper;
			var sprite:Sprite;
			var type:String;
			
			for each( type in obstacleBitmaps )
			{
				vector = _usedObstacles[ type ];
				while( vector.length > 0 )
				{
					_pool.release( vector.pop(), type );
				}
				
				if( type.indexOf( HIT ) < 0 )
				{				
					var clip:MovieClip = container[ type ];
					container.removeChild( container[ type ]);
				}
			}
			
			if( _callbackFunction )
			{
				_callbackFunction();
			}
		}
	}
}