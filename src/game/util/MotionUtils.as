package game.util
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.SpatialOffset;
	import engine.components.Tween;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.systems.TweenSystem;
	
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.CurrentHit;
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.motion.StretchSquash;
	import game.components.motion.TargetEntity;
	import game.components.motion.WaveMotion;
	import game.data.WaveMotionData;
	import game.systems.SystemPriorities;
	import game.systems.motion.StretchSquashSystem;
	import game.systems.motion.WaveMotionSystem;

	public class MotionUtils
	{
		public static function addWaveMotion(entity:Entity, waveData:WaveMotionData, group:Group = null):void
		{
			var waveMotion:WaveMotion = entity.get(WaveMotion);
				
			if(waveMotion == null)
			{
				waveMotion = new WaveMotion();
				entity.add(waveMotion);
			}
			
			waveMotion.add(waveData);
			
			if(!entity.get(SpatialAddition))
			{
				entity.add(new SpatialAddition());
			}

			if (group)
			{
				group.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			}
		}
		
		/**
		 * Adds necessary components &amp; systems for stretch &amp; squash.
		 * @param	entity
		 * @param	group
		 * @return
		 */
		public static function addStretchSquash( entity:Entity, group:Group = null ):StretchSquash
		{
			if(!entity.get(Tween))
			{
				entity.add(new Tween());
			}
			
			if(!entity.get(SpatialOffset))
			{
				entity.add(new SpatialOffset());
			}
			
			var spatial:Spatial = entity.get(Spatial)
			if(spatial == null)
			{
				spatial = new Spatial();
				entity.add(spatial);
			}
			
			var edge:Edge = entity.get(Edge);
			if(edge == null)
			{
				edge = new Edge();
				// TODO :: Probably want to have Edge do an auto setup based on current dimensions and origin point
				entity.add(edge);
			}
			
			var morph:StretchSquash = entity.get(StretchSquash);
			if(morph == null)
			{
				morph = new StretchSquash();
				entity.add(morph);
			}
			
			if (group)
			{
				group.addSystem(new StretchSquashSystem());
				group.addSystem(new TweenSystem());
			}
			
			return morph;
		}
		
		public static function zeroMotion( entity:Entity, axis:String = null ):void
		{
			var motion:Motion = entity.get(Motion);
			
			if(axis == null || axis == "x")
			{
				motion.acceleration.x = motion.velocity.x = motion.previousAcceleration.x = motion.totalVelocity.x = 0;
			}
			
			if(axis == null || axis == "y")
			{
				motion.acceleration.y = motion.velocity.y = motion.previousAcceleration.y = motion.totalVelocity.y = 0;
			}	
			///*
			if( axis == "rotation")
			{
				motion.rotationAcceleration = motion.rotationVelocity = motion.previousRotation = 0;
			}
			//*/
		}
		
		/**
		 * Moves entity to target via the use of its control target.
		 * @param    character : The entity to move
		 * @param    targetX : x to move a character to.
		 * @param    targetY : y to move a character to.
		 * @param    lockControl : Lock the characters control while moving to this target (don't allow clicks to stop the moving to target).
		 * @param    handler : A function to be called when reaching the target, signal returns Entity that reached target
		 * @param	 minTargetDist - Point holding the min x &amp; y distances necessray to trigger a target reached.
		 * @param    directionTargetX : The position to use for the characters facing direction once arriving at the point.	// TODO :: might want to refactor this, not very user friedly
		 */
		public static function moveToTarget(entity:Entity, targetX:Number, targetY:Number, lockControl:Boolean = false, handler:Function = null, minTargetDelta:Point = null):Destination //, minTargetDist:Point = null ):void
		{
			return MotionUtils.followPath( entity, new <Point>[new Point(targetX, targetY)], handler, lockControl, false, minTargetDelta ); 
		}
		
		/**
		 * Moves entity along the provided path.
		 * @param	char
		 * @param	scene
		 * @param	path
		 * @param	handler	- Function called when char reaches final path point, signal returns Entity so handler should account for it
		 * @param	cameraTarget - camera targets character
		 * @param	lockControl	- locks characters motion controls
		 * @param	faceDirection - turns char in given direction on reahing final point, valid entries are CharUtils.DIRECTION_RIGHT &amp; CharUtils.DIRECTION_RIGHT
		 * @param	minDist - Point holding the min x &amp; y distances necessray to trigger a target reached.
		 */
		//public static function followPath( character:Entity, path:Vector.<Point>, handler:Function = null, lockControl:Boolean = true, directionFace:String = "", minTargetDelta:Point = null, loop:Boolean = false, faceX:Number = NaN, faceY:Number = NaN ):void
		public static function followPath( entity:Entity, path:Vector.<Point>, handler:Function = null, lockControl:Boolean = true, loop:Boolean = false, minTargetDelta:Point = null, ignorePlatformTarget:Boolean = false ):Destination
		{
			// add motion components
			if(!entity.get(MotionControl)) 		{ entity.add(new MotionControl()); }
		
			var motionTarget:MotionTarget = entity.get(MotionTarget);
			if( !motionTarget )
			{
				motionTarget = new MotionTarget();
				entity.add( motionTarget );
			}
			
			var motion:Motion = entity.get(Motion);
			if( !motion )
			{
				motion = new Motion();
				entity.add( motion );
			}
			
			var spatial:Spatial = entity.get(Spatial);
			// reset target values to prevent old values from persisting 
			motionTarget.targetDeltaX = 0;
			motionTarget.targetDeltaY = 0;
			//Set the target X and Y to the Entity's current Spatial so the target won't be the mouse/etc. and systems can take over afterwards and set the new targets.
			motionTarget.targetX = spatial.x;
			motionTarget.targetY = spatial.y;
			
			var target:TargetEntity = entity.get( TargetEntity );
			if( target != null )
			{
				target.active = false;
			}
			
			// if lockControl true, make sure path takes precedence
			if( lockControl )
			{
				/*motionTarget.targetDeltaX = 0;
				motionTarget.targetDeltaY = 0;
				motionTarget.targetX = motion.x;
				motionTarget.targetY = motion.y;
				// deactivate targetEntity immediately, so TargetEntitySystem can't sneak in a different target position
				var target:TargetEntity = entity.get( TargetEntity );
				if( target != null )
				{
					target.active = false;
				}*/
			}
				
			// set Destination
			var destination:Destination = entity.get(Destination);
			if( !destination )
			{
				destination = new Destination();
				entity.add( destination );
			}
			// what happens if destination is already active, how do we mange clean up? - bard
			if( destination.active )	
			{ 
				destination.onInterrupted.dispatch( entity ); 
				destination.onInterrupted.removeAll();
				destination.onFinalReached.removeAll();
			}
			destination.active = true;
			destination.useType = Destination.USE_PATH;
			destination.lockControl = lockControl;
			if( handler != null )	{ destination.onFinalReached.addOnce( handler );  }

			// set Navigation
			var navigation:Navigation = entity.get(Navigation);
			if( !navigation )
			{
				navigation = new Navigation();
				entity.add( navigation );
			}
			navigation.index = NaN;
			navigation.path = path;
			navigation.loop = loop;
			if ( minTargetDelta )	{ navigation.minTargetDelta = minTargetDelta; }

			// turn off sleep while following path
			var sleep:Sleep = entity.get(Sleep);	
			if( sleep != null )
			{
				sleep.ignoreOffscreenSleep = true;
				sleep.sleeping = false;
			}
			
			return destination;
		}

		/**
		 * Causes the follower Entity to attempt to reach leader Entity.
		 * Generally used for navigational purposes.
		 * @param	leader : The entity to follow
		 * @param	follower : The entity following 
		 * @param	distance : The minimum distance the entities can be apart before the follower moves.
		 * @param   lockControl : Whether the input will be locked, when lcoekd input changes cannot interrupt following.
		 * @return 
		 */
		public static function followEntity( follower:Entity, leader:Entity, minTargetDist:Point = null, applyCameraOffset:Boolean = false, lockControl:Boolean = true ):Destination
		{
			// add motion
			if(!follower.get(Motion)) 			{ follower.add(new Motion()); }
			if(!follower.get(MotionControl)) 	{ follower.add(new MotionControl()); }
			if(!follower.get(MotionTarget)) 	{ follower.add(new MotionTarget()); }
			
			// set Destination
			var destination:Destination = follower.get(Destination);
			if( !destination )
			{
				destination = new Destination();
				follower.add( destination );
			}
			if( destination.active )	
			{ 
				destination.onFinalReached.removeAll();
				destination.onInterrupted.dispatch( follower );
				destination.onInterrupted.removeAll();
			}
			destination.active = true;
			destination.useType = Destination.USE_TARGET;
			destination.lockControl = lockControl;

			// set TargetEntity
			var targetEntity:TargetEntity = follower.get( TargetEntity );
			if ( !targetEntity )
			{
				targetEntity = new TargetEntity();
				follower.add(targetEntity);	
			}
			//targetEntity.activate = true;
			targetEntity.applyCameraOffset = applyCameraOffset;
			targetEntity.target = leader.get(Spatial);
			if ( minTargetDist ) 
			{ 
				targetEntity.minTargetDelta = new Point(minTargetDist.x, minTargetDist.y);
			}

			// turn off sleep while following 
			var sleep:Sleep = follower.get(Sleep);	
			if( sleep != null )
			{
				sleep.ignoreOffscreenSleep = true;
				sleep.sleeping = false;
			}
			
			return destination;
		}
		
		/**
		 * Causes the entity to follow the input entity.
		 * Adds a follow entity component mapped to an input entity's spatial component.
		 * The follow entity system will set the passed entity's target and acceleration flags but requires MotionControlSystem to actually move the entity.
		 * @param	entity
		 * @param	inputEntity
		 * @param	applyCameraOffset - accounts for camera, should generally be ste to true if applied within a platform scene
		 */
		public static function followInputEntity(character:Entity, inputEntity:Entity, applyCameraOffset:Boolean = true):void
		{
			// create FollowEntity whose target is the mouse/inpu
			var targetEntity:TargetEntity = character.get( TargetEntity );
			if(!targetEntity)
			{
				targetEntity = new TargetEntity();
				character.add(targetEntity);
			}
			
			targetEntity.target = inputEntity.get(Spatial);
			targetEntity.applyCameraOffset = applyCameraOffset;
			targetEntity.minTargetDelta = null;	// ignore minDistance
		}
		
		/**
		 * Get appropriate class from which position can pulled, priority goes motion & spatial
		 * @param hitNode
		 * @return 
		 */
		public static function getPositionComponent(node:Object):Object
		{
			var positionComponent:Object;
			
			if(node.motion != null)
			{
				positionComponent = node.motion;
			}
			else if(node.spatial != null)
			{
				positionComponent = node.spatial;
			}
			
			return positionComponent;
		}
		
		/**
		 * Add colliders for standard scene collisions, where bounds are equal to the scene bounds.
		 */
		public static function addColliders(entity:Entity, colliders:Vector.<Class> = null, scene:Group = null ):void
		{
				
			// if colliders not defined, use defaults
			if( colliders == null )
			{
				colliders = new <Class>[ CurrentHit, SceneCollider, PlatformCollider, BitmapCollider, WaterCollider, WallCollider ];
			}
			
			var colliderClass:Class;
			var collider:*;
			var i:int;
			for ( i = 0; i < colliders.length; i++ )
			{
				colliderClass = colliders[i];
				collider = entity.get( colliderClass );
				if ( !collider )
				{
					collider = new colliderClass();
					entity.add( collider );
				}
			}
			
			if( scene == null )
			{
				scene = entity.group;
			}
			// set motion bounds, only applied if group is a Scene
			if ( scene != null && scene is Scene  )
			{
				if( Scene(scene).sceneData )
				{
					var motionBounds:MotionBounds = entity.get( MotionBounds )
					if ( !motionBounds )
					{
						motionBounds = new MotionBounds();
						entity.add( motionBounds );
					}
					motionBounds.box = Scene(scene).sceneData.bounds;
				}
			}
		}
		
		public static function boundsToEdge(displayObject:DisplayObject, padding:Number = 0):Edge
		{
			var bounds:Rectangle = displayObject.getBounds(displayObject);
			var edge:Edge = new Edge();
			edge.unscaled.top = -(bounds.height * .5 + padding);
			edge.unscaled.bottom = bounds.height * .5 + padding;
			edge.unscaled.left = -(bounds.width * .5 + padding);
			edge.unscaled.right = bounds.width * .5 + padding;
			
			return edge;
		}
		
		/**
		 * Determine if two Entity's rectangles overlap.
		 * @param node : a node with either a Spatial or Motion component and optionally an Edge
		 * @param node2 : a node with either a Spatial or Motion component and optionally an Edge
		 * @return 'true' id overlap occurs
		 */
		public static function checkOverlap(node:Object, node2:Object, debug:Boolean = false):Boolean
		{
			var nodePosition:Object = getPositionComponent(node);
			var node2Position:Object = getPositionComponent(node2);
			var offsetRight:Number = 0;
			var offsetLeft:Number = 0;
			var offsetTop:Number = 0;
			var offsetBottom:Number = 0;
			var overlap:Boolean = false;
			
			if(node.hasOwnProperty("edge") && node.edge != null)
			{
				offsetRight = node.edge.rectangle.right;
				offsetLeft = -node.edge.rectangle.left;
				offsetTop = -node.edge.rectangle.top;
				offsetBottom = node.edge.rectangle.bottom;
			}
			
			if(node2.hasOwnProperty("edge") && node2.edge != null)
			{
				offsetRight -= node2.edge.rectangle.left;
				offsetLeft += node2.edge.rectangle.right;
				offsetTop -= node2.edge.rectangle.top;
				offsetBottom += node2.edge.rectangle.bottom;
			}
			
			if(nodePosition.x > node2Position.x - offsetLeft && 
				nodePosition.x < node2Position.x + offsetRight &&
				nodePosition.y > node2Position.y - offsetTop &&
				nodePosition.y < node2Position.y + offsetBottom)
			{
				overlap = true;
			}
			
			if(debug)
			{
				var display:Display = node.entity.get(Display);
				var canvas:Graphics = Sprite(display.container).graphics;
				canvas.clear();
				canvas.beginFill(0x00ff00, .5);
				canvas.drawRect(nodePosition.x - offsetLeft, nodePosition.y - offsetTop, offsetLeft + offsetRight, offsetTop + offsetBottom);
				canvas.beginFill(0xff0000, .5);
				canvas.drawRect(node2Position.x, node2Position.y, offsetLeft + offsetRight, offsetTop + offsetBottom);
				canvas.endFill();
			}
			
			return overlap;
		}
				
		public static function impulseToTarget(motion:Motion, targetX:Number, targetY:Number):void
		{
			var gravity:Number = MotionUtils.GRAVITY;
			var initDx:Number = targetX - motion.x;
			var initDy:Number = targetY - motion.y;
			var dx:Number = Math.abs(initDx);
			var dy:Number = -initDy;  // flip for inverted coordinate system
			var dampener:Number = 1;
			
			// determine velocity, adjust based on delta
			var vel:Number = createImpulse(dx, dy) * dampener;
			var vel2:Number = vel * vel;	// store velocity squared
			
			// calculate angle
			var root:Number = Math.sqrt( Math.abs(vel2 * vel2 - ( gravity * (gravity * dx * dx + 2 * dy * vel2) ) ) );
			var radians:Number = Math.atan( (vel2 + root)/(gravity * dx) );
			//var radians:Number = Math.atan( (vel2 - root)/(gravity * dx) ); // this will give you the lesser more direct angle, but we want the greater for an upward arc.
			
			// set x & y velocity from angle
			motion.velocity.x = Math.cos( radians ) * vel;
			motion.velocity.y = -Math.sin( radians ) * vel;
			if(initDx < 0)	// flip x velocity depending on x delta
			{
				motion.velocity.x *= -1;
			}
		}
		
		private static function createImpulse( dx:Number, dy:Number ):int
		{
			//dy += node.edge.rectangle.bottom;	// adjust so we calculate from feet
			var slope:Number = dy/dx;
			var distPercent:Number = Math.sqrt( dx * dx + dy * dy )/300;
			var dampener:Number;
			var jumpVelocity:Number = 950;
			
			if(slope < 0)
			{
				if(slope < -1)
				{ 
					dampener = .65;
				}
				else
				{
					dampener = .3 + (1 + slope) * .3 + distPercent * .2;
				}
			}
			else
			{
				dampener = .6 + Math.min(1, slope) * .2 + distPercent * .2;
			}
			
			return jumpVelocity * Math.min(1, dampener);
		}
		
		public static var GRAVITY:Number = 1700;
	}
}