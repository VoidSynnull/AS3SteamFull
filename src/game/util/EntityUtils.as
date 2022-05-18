package game.util
{	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.OwningGroup;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.systems.MotionSystem;
	import engine.systems.RenderSystem;
	
	import game.components.Timer;
	import game.components.audio.HitAudio;
	import game.components.entity.Children;
	import game.components.entity.Parent;
	import game.components.entity.Sleep;
	import game.components.entity.collider.EmitterCollider;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.TargetSpatial;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.TimelineClip;
	import game.components.ui.Button;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.scene.hit.EmitterHitData;
	import game.data.scene.hit.HitAudioData;
	import game.data.sound.SoundAction;
	import game.data.sound.SoundData;
	import game.nodes.ui.WordBalloonNode;
	import game.systems.SystemPriorities;
	import game.systems.TimerSystem;
	import game.systems.motion.PositionSmoothingSystem;
	
	public class EntityUtils
	{		
		/**
		 * Create timeline with spatial components in one function
		 */
		public static function createMovingTimelineEntity( group:Group=null, displayObject:DisplayObjectContainer=null, container:DisplayObjectContainer=null, playing:Boolean = false, frameRate:int = 32 ):Entity
		{
			var entity:Entity = TimelineUtils.convertClip(displayObject as MovieClip,group,createMovingEntity(group,displayObject,container),null,playing,frameRate);
			return entity;
		}
		/**
		 * Creates a standard Entity that can move
		 */
		public static function createMovingEntity( group:Group=null, displayObject:DisplayObjectContainer=null, container:DisplayObjectContainer=null ):Entity
		{
			var entity:Entity = EntityUtils.createSpatialEntity( group, displayObject, container );

			// add Motion
			var motion:Motion = new Motion();
			entity.add(motion);
			
			if( group )
			{
				if ( !group.getSystem( MotionSystem ) )
				{
					group.addSystem( new MotionSystem(), SystemPriorities.move );
				}
				
				if( !group.getSystem( PositionSmoothingSystem) )
				{
					group.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
				}
			}

			return entity;
		}
		
		public static function createSpatialEntity( group:Group=null, displayObject:* = null, container:DisplayObjectContainer=null, animated:Boolean=false ):Entity
		{
			var entity:Entity;
			if(!animated)
			{
				entity = EntityUtils.createDisplayEntity( group, displayObject, container );
			}
			else
			{
				entity = TimelineUtils.convertClip(displayObject as MovieClip,group,createDisplayEntity(group,displayObject,container));
			}
			
			// add Spatial
			var spatial:Spatial = new Spatial();
			if ( displayObject )
			{
				EntityUtils.syncSpatial( spatial, displayObject );
			}
			entity.add(spatial);
			
			return entity;
		}
		
		public static function createDisplayEntity( group:Group=null, displayObject:*=null, container:DisplayObjectContainer=null ):Entity
		{
			var entity:Entity = new Entity();
			
			// add Display
			var display:Display;
			if( displayObject == null )	{ displayObject = new MovieClip(); }
			if ( container )
			{
				display = new Display( displayObject, container );
			}
			else
			{
				display = new Display( displayObject );
				if ( displayObject.parent )
				{
					display.setContainer(displayObject.parent);
				}
			}
			entity.add(display);
			
			if( group )
			{
				if ( !group.getSystem( RenderSystem ) )
				{
					group.addSystem( new RenderSystem(), SystemPriorities.render );
				}
				group.addEntity( entity );
			}
			return entity;
		}
		
		/**
		 * Gets the display component an Entity is using for rendering.
		 * @param	entity : The entity to check for a display component.
		 */
		public static function getDisplay(entity:Entity):Display
		{
			if( entity )
			{
				if(entity.get(Display))
				{
					return(entity.get(Display));
				}
			}
			
			return(null);
		}
		
		/**
		 * 
		 * @param	entity
		 * @return
		 */
		public static function getDisplayObject(entity:Entity):DisplayObjectContainer
		{
			var display:* = EntityUtils.getDisplay(entity);
			if ( display )
			{
				return display.displayObject as DisplayObjectContainer;
			}
			return null;
		}
		
		/**
		 * Helper function for visibility. 
		 * @param entity
		 * @param isVisible
		 */
		public static function visible( entity:Entity, isVisible:Boolean = true, forceDisplay:Boolean = false ):void
		{
			var display:Display = entity.get(Display);
			if( display )
			{
				display.visible = isVisible;
				if( forceDisplay )
				{
					if( display.displayObject )
					{
						display.displayObject.visible = isVisible;
					}
				}
			}
		}
		
		/**
		 * Replaces an Entity's display object, updating general Component effected by the change.  
		 * @param entity
		 * @param displayObject
		 */
		public static function replaceDisplayObject( entity:Entity, displayObject:DisplayObject ):void
		{
			// refresh Display
			var display:Display = entity.get(Display);
			if( display )
			{
				display.refresh( displayObject, display.container );
			}
			// refresh TimelinClip
			var timelineClip:TimelineClip = entity.get(TimelineClip);
			if( timelineClip )
			{
				timelineClip.mc = displayObject as MovieClip;
			}
			// refresh Button
			var button:Button = entity.get(Button);
			if( button )
			{
				button.invalidate = true;
			}
			// refresh Interaction
			InteractionCreator.refresh( entity, displayObject as DisplayObjectContainer ); 
		}

		/**
		 * Helper function to get name of entity.
		 * Checks for Id component first, then falls back to entity name.
		 * @param entity
		 * @return - returns id or name of entity (in that order of priority)
		 */
		public static function getIdName(entity:Entity):String
		{
			var id:Id = entity.get(Id);
			if( id != null )
			{
				return id.id;
			}
			else
			{
				return entity.name;
			}
			return null;
		}
		
		/**
		 * Sync a spatial component with a display object's x,y,rotation, scaleX and scaleY properties.
		 * @param	spatial : The spatial component which will be synced.
		 * @param	displayObject : The display object whose properties will be synced.
		 */
		public static function syncSpatial(spatial:Spatial, displayObject:*):void
		{
			spatial.x = displayObject.x;
			spatial.y = displayObject.y;
			spatial.rotation = displayObject.rotation;
			spatial.scaleX = displayObject.scaleX;
			spatial.scaleY = displayObject.scaleY;
			spatial._invalidate = true;
		}
		
		public static function syncFromSpatial(spatial:Spatial, displayObject:*):void
		{
			if(!isNaN(spatial.x)) { displayObject.x = spatial.x; }
			if(!isNaN(spatial.y)) { displayObject.y = spatial.y; }
			if(!isNaN(spatial.rotation)) { displayObject.rotation = spatial.rotation; }
			if(!isNaN(spatial.scaleX)) { displayObject.scaleX = spatial.scaleX }
			if(!isNaN(spatial.scaleY)) { displayObject.scaleY = spatial.scaleY; }
		}
		
		/**
		 * Sets the spatial coordinates
		 * @param	entity
		 * @param	x
		 * @param	y
		 */
		public static function position( entity:Entity, x:int, y:int, rotation:Number = NaN ):void
		{
			var spatial:Spatial = entity.get(Spatial);
			if(spatial)
			{
				spatial.x = x;
				spatial.y = y;
				if(!isNaN(rotation))
					spatial.rotation = rotation;
			}
		}
		
		public static function getPosition( entity:Entity ):Point
		{
			if( entity != null )
			{
				var spatial:Spatial = entity.get(Spatial);
				if(spatial)
				{
					return new Point( spatial.x, spatial.y );
				}
			}
			return null;
		}
		
		public static function setScale( entity:Entity, scale:Number ):void
		{			
			var edge:Edge = entity.get(Edge);
			var spatial:Spatial = entity.get(Spatial);
			
			if( spatial )
			{
				if( edge && spatial.scale != 0  )
				{
		
					var top:Number = edge.rectangle.top / spatial.scale;
					var bottom:Number = edge.rectangle.bottom / spatial.scale;
					var left:Number = edge.rectangle.left / spatial.scale;
					var right:Number = edge.rectangle.right / spatial.scale;
					var bottomDelta:Number = bottom * scale - edge.rectangle.bottom;
					
					edge.rectangle.top = top * scale;
					edge.rectangle.bottom = bottom * scale;
					edge.rectangle.left = left * scale;
					edge.rectangle.right = right * scale;
				}
				spatial.scale = scale;
			}
		}
		
		public static function setScaleFromComponents( edge:Edge, spatial:Spatial, scale:Number ):void
		{			
			if( spatial )
			{
				if( edge && spatial.scale != 0  )
				{
					var top:Number = edge.rectangle.top / spatial.scale;
					var bottom:Number = edge.rectangle.bottom / spatial.scale;
					var left:Number = edge.rectangle.left / spatial.scale;
					var right:Number = edge.rectangle.right / spatial.scale;
					var bottomDelta:Number = bottom * scale - edge.rectangle.bottom;
					
					edge.rectangle.top = top * scale;
					edge.rectangle.bottom = bottom * scale;
					edge.rectangle.left = left * scale;
					edge.rectangle.right = right * scale;
				}
				spatial.scale = scale;
			}
		}
		
		/**
		 * Copies <code>x</code>, <code>y</code> and <code>rotation</code> values
		 * from a source <code>Entity</code>'s <code>Spatial</code> component to a dest <code>Entity</code>'s <code>Spatial</code> component.
		 * Useful when you need a layering of <code>Entities</code> at a particular position.
		 * 
		 * @param	refEntity	The source Entity
		 * @param	applyEntity	The dest Entity
		 * @return	the modified <code>Spatial</code> component or <code>null</code> if either <code>Entity</code> argument lacks a <code>Spatial</code> component.
		 */
		public static function positionByEntity( applyEntity:Entity, refEntity:Entity, applyScale:Boolean = false, applyRotation:Boolean = true ):Spatial
		{
			var refSpatial:Spatial = refEntity.get(Spatial);
			var applySpatial:Spatial = applyEntity.get(Spatial);
			if( refSpatial && applySpatial )
			{
				var rotation:Number= refSpatial.rotation;
				applySpatial.x = refSpatial.x;
				applySpatial.y = refSpatial.y;
				if(applyRotation)	{applySpatial.rotation = rotation;}
				if( applyScale )	{ EntityUtils.setScale( applyEntity, refSpatial.scale ); }
				return applySpatial;
			}
			return null;
		}
		
		/**
		 * Creates a TargetSpatial from an Entity's Spatial
		 * @param	entity
		 * @return
		 */
		public static function createTargetSpatial( entity:Entity ):TargetSpatial
		{
			var spatial:Spatial = entity.get(Spatial);
			if ( spatial )
			{
				return new TargetSpatial( entity.get(Spatial) );
			}
			return null;
		}
		
		/**
		 * Makes an Entity's Spatial follow another's Entity's Spatial.
		 * @param follower
		 * @param target
		 * @param rate	- rate following, a rate of 1 causes follower's spatial to map directly to the target's
		 * @param offset
		 * @param applyCameraOffset
		 * @param properties
		 * @return 
		 * 
		 */
		public static function followTarget( follower:Entity, target:Entity, rate:Number = 1, offset:Point = null, applyCameraOffset:Boolean = false, properties:Vector.<String> = null ):FollowTarget
		{
			var targetSpatial:Spatial = target.get(Spatial);
			if( !targetSpatial )
			{
				trace( "Error :: followTarget : target entity must have a Spatial component." );
				return null;
			}
			
			if ( !follower.has( Spatial ) ) { follower.add( new Spatial() ); }
	
			var followTarget:FollowTarget = follower.get( FollowTarget );
			if ( !followTarget )
			{
				followTarget = new FollowTarget();
				follower.add(followTarget);	
			}
			
			if ( offset )
			{
				followTarget.offset = offset;
			}
			
			followTarget.applyCameraOffset = applyCameraOffset;
			followTarget.target = targetSpatial;
			followTarget.rate = rate;
			
			// set properties that follower will follow, if none are included default to x & y
			if ( properties == null )
			{
				properties = new < String > ["x", "y"];
			}
			followTarget.properties = properties;
			
			// turn off sleep while following 
			var sleep:Sleep = follower.get(Sleep);
			if ( !sleep )
			{
				sleep = new Sleep()
				follower.add( sleep );
			}
			sleep.ignoreOffscreenSleep = true;
			sleep.sleeping = false;
			
			return followTarget;		
		}
		
		/**
		 * Stops a follower from following another Entity
		 * @param	follower : The entity following 
		 */
		public static function stopFollowTarget(follower:Entity):void
		{
			follower.remove(FollowTarget);
			
			var sleep:Sleep = follower.get(Sleep);
			if(sleep != null)
			{
				sleep.ignoreOffscreenSleep = false;
			}
		}
		
		/**
		 * Adds handler to clicked.
		 * Adds an Interaction component if entity does not already have one.
		 * @param	entity
		 * @param	handler
		 * @param	once
		 */
		public static function onPress( entity:Entity, handler:Function, once:Boolean = true ):Interaction
		{
			var interaction:Interaction = entity.get(Interaction);
			if ( !interaction )
			{
				interaction = InteractionCreator.addToEntity( entity, [InteractionCreator.DOWN] );
			}
			else
			{
				if ( !interaction.down )
				{
					var displayObject:DisplayObjectContainer = EntityUtils.getDisplayObject( entity );
					if ( displayObject )
					{
						InteractionCreator.addToComponent( displayObject, [InteractionCreator.DOWN], interaction );
					}
					else
					{
						return null;
					}
				}
			}
			
			if ( interaction )
			{
				if ( once )
				{
					interaction.down.addOnce( handler );
				}
				else
				{
					interaction.down.add( handler );
				}
			}
			return interaction;
		}

		/**
		 * Freezes a entity
		 * TODO :: May find we need to pause more components in the future, add here as they are found
		 * @param	character
		 * @param	bool
		 */
		public static function freeze( entity:Entity, bool:Boolean = true ):void
		{
			// pause motion
			var motion:Motion = entity.get( Motion );
			if ( motion )
			{
				motion.pause = bool;
			}
		}
		
		/**
		 * Check if an entity is sleeping.
		 * @param	entity : The entity to check for sleeping.
		 */
		[Inline]
		public static function sleeping(entity:Entity):Boolean
		{
			if(entity.managedSleep)
			{
				return(entity.sleeping);
			}
			else
			{
				if (entity.group == null)
					return false;
				else
					return(entity.sleeping || (entity.group.paused && !entity.ignoreGroupPause));
			}
		}
		
		[Inline]
		public static function paused(entity:Entity):Boolean
		{
			if(entity.managedSleep)
			{
				return(entity.paused);
			}
			else
			{
				if (entity.group == null)
					return false;
				else
					return(entity.group.paused && !entity.ignoreGroupPause);
			}
		}
		
		/**
		 * Check if an entity has a sleep component.
		 * @param	entity : The entity to check for a sleep component.
		 */
		[Inline]
		public static function canSleep(entity:Entity):Boolean
		{			
			var sleep:Sleep = entity.get(Sleep);
			
			if(sleep == null)
			{
				var parent:Parent = entity.get(Parent);
				
				if(parent != null)
				{
					return(canSleep(parent.parent));
				}
			}
			else
			{
				return(true);
			}
			
			return(false);
		}
		
		/**
		 * changes the sleep state of an entity
		 * adds sleep component if needed
		 */
		public static function setSleep( entity:Entity, sleeping:Boolean):Sleep
		{
			var sleep:Sleep = entity.get(Sleep);
			if(sleep == null){
				
				if(entity.managedSleep)
				{
					entity.sleeping = sleeping;
					return null;
				}
				entity.add(new Sleep());
				sleep = entity.get(Sleep);
			}
			sleep.sleeping = sleeping;
			sleep.ignoreOffscreenSleep = sleeping;
			entity.ignoreGroupPause = sleeping;	
			
			return sleep;
		}
		
		/**
		 * Associate an entity with another entity.  Adding a child to a parent also maps the childs Parent component to the parent.  
		 * A parent can have any number of unique children, a child can only have one parent.
		 * @param   child : the 'child' entity to add to a 'parent' entity
		 * @param   parent : the 'parent' entity to be associated with the child.
		 * @param   [addToGroup] : If true this entity will be added to the game with its parent's group and SystemManager.
		 */
		public static function addParentChild( child:Entity, parent:Entity, addToGroup:Boolean = false ):void
		{		
			var children:Children;
			var childParent:Parent;
			var oldParentChildren:Children;
			var total:int;
			var index:int;
			
			children = parent.get(Children);
			childParent = child.get(Parent);

			// Add new Children component to the parent if it doesn't have one yet.
			if(children == null)
			{
				children = new Children();
				parent.add(children);
			}
			else
			{
				//  If the parent already has Children, ensure the new child isn't already in the list.
				for(var n:uint = 0; n < children.children.length; n++)
				{
					if(children.children[n] == child)
					{
						return;
					}
				}
			}
			
			// If the child doesn't have a Parent component, add one.
			if(childParent == null)
			{
				childParent = new Parent();
				child.add(childParent);
			}
			else
			{
				// if the child already has a parent, remove it from its parent child list before re-parenting.
				oldParentChildren = childParent.parent.get(Children);
				total = oldParentChildren.children.length;
				
				for (index = total - 1; index > -1; index--)
				{
					if(oldParentChildren.children[index] == child)
					{
						oldParentChildren.children.splice(index, 1);
					}
				}
			}
			
			// Associate the child with the parent.  A child can only have one parent.
			childParent.parent = parent;
			children.children.push(child);
			
			if(!child.get(Sleep))
			{
				child.sleeping = parent.sleeping;
				child.ignoreGroupPause = parent.ignoreGroupPause;
			}
			
			child.managedSleep = true;
			
			// Add child entity to game if specified.  It inherits its parent's group and systemManager.
			if(addToGroup)
			{
				var parentGroup:Group = getOwningGroup(parent);
				parentGroup.addEntity(child);
			}
		}
		
		/**
		 * Find a child of a parent from an id.  It will keep going through multiple 'generations' until it finds a match, unless 'checkDescendents' is false.
		 * @param parent : The base Entity to start searching from
		 * @param id : The id of the child you want to find.  You can optionally use dot notation to test a specific heirarchy.  This is useful to find an entity with 
		 *               the same id as another but different parents.
		 * 
		 * ex:
		 * 
		 * getChildById(myEntity, "body.head.face.eyes.leftEye");
		 */
		public static function getChildById(parent:Entity, id:String, checkDescendents:Boolean = true):Entity
		{
			var nextEntity:Entity;
			var childId:Id;
			
			if(id.indexOf(".") > -1)
			{
				var descendents:Array = id.split(".");
				var nextParent:Entity = parent;
				childId = parent.get(Id);
				
				if(childId.id == descendents[0])
				{
					descendents.shift();
				}
				
				for(var n:int = 0; n < descendents.length; n++)
				{
					nextEntity = getChildById(nextParent, descendents[n]);
					
					if(nextEntity != null)
					{
						nextParent = nextEntity;
					}
				}
				
				return(nextEntity);
			}
			else
			{
				var children:Children = parent.get(Children);
				var child:Entity;
				var total:int;
				var index:int;

				if(children)
				{
					total = children.children.length;
					
					for (index = total - 1; index > -1; index--)
					{
						child = children.children[index];
						childId = child.get(Id);
						
						if(childId)
						{
							if(childId.id == id)
							{
								return(child);
							}
						}
						
						if(checkDescendents)
						{
							nextEntity = getChildById(child, id, true);
							
							if(nextEntity)
							{
								return(nextEntity);
							}
						}
					}
				}
			}
			
			return(null);
		}
		
		/**
		 * Return distance between provided entities as long as they have Spatial components. 
		 * @param entity1
		 * @param entity2
		 * @return 
		 */
		public static function distanceBetween( entity1:Entity, entity2:Entity):Number
		{
			var spatial1:Spatial = entity1.get( Spatial );
			var spatial2:Spatial = entity2.get( Spatial );
			if( spatial1 && spatial2 )
			{
				return GeomUtils.dist( spatial1.x, spatial1.y, spatial2.x, spatial2.y );
			}
			return NaN;
		}
		
		/**
		 * Hide and lock a scene interaction
		 * @param entity - the entity to lock or unlock its scene interaction
		 * @param lock - true locks it, false unlocks it
		 * 
		 */		
		public static function lockSceneInteraction(entity:Entity, lock:Boolean = true):void
		{
			entity.get(SceneInteraction).disabled = lock;
			entity.get(Interaction).lock = lock;
			var children:Children = entity.get(Children);
			
			// disable mouse clicks
			var display:Display = entity.get(Display);
			if( display != null )
			{
				if( display.displayObject != null && display.displayObject is DisplayObjectContainer)
				{
					DisplayObjectContainer(display.displayObject).mouseEnabled = !lock;
					DisplayObjectContainer(display.displayObject).mouseChildren = !lock;
				}
			}
			
			if(lock)
			{
				ToolTipCreator.removeFromEntity(entity);
			}
			else
			{
				ToolTipCreator.addToEntity(entity);
			}
		}
		
		public static function removeInteraction(entity:Entity):void
		{
			entity.remove(SceneInteraction);
			entity.remove(Interaction);
			
			// disable mouse clicks
			var display:Display = entity.get(Display);
			if( display != null )
			{
				if( display.displayObject != null && display.displayObject is DisplayObjectContainer)
				{
					DisplayObjectContainer(display.displayObject).mouseEnabled = false;
					DisplayObjectContainer(display.displayObject).mouseChildren = false;
				}
			}
			
			// Remove tooltip if they have one
			ToolTipCreator.removeFromEntity(entity);
		}		
		
		public static function getOwningGroup( entity:Entity ):Group
		{
			var owningGroup:OwningGroup = entity.get(OwningGroup);
			if ( owningGroup )
			{
				if ( owningGroup.group )
				{
					return owningGroup.group;
				}
			}
			return null;
		}
		
		/**
		 * Get the parent Entity, if available.
		 * @param	entity
		 * @return
		 */
		public static function getParent( entity:Entity ):Entity
		{
			var parent:Parent = entity.get(Parent) as Parent
			if ( parent )
			{
				if ( parent.parent )
				{
					return parent.parent;
				}
			}
			return null;
		}
		
		/**
		 * Play a hit sfx using an entities hitAudio component.
		 */
		public static function playAudioAction(hitAudio:HitAudio, hitAudioData:HitAudioData, action:String = SoundAction.IMPACT):void
		{
			var soundData:SoundData;
			
			if(hitAudio && hitAudioData)
			{
				if(hitAudioData.currentActions)
				{
					soundData = hitAudioData.currentActions[action];
					
					if(soundData)
					{
						hitAudio.soundData = soundData;	
						hitAudio.active = true;
						hitAudio.action = action;
					}
				}
			}
		}
		
		/**
		 * Play a hit sfx using an entities hitAudio component.
		 */
		public static function playEmitterAction(emitterHit:EmitterCollider, emitterHitData:EmitterHitData, action:String = SoundAction.IMPACT):void
		{
			if( emitterHit && emitterHitData )
			{
				if( emitterHitData.impactClass )
				{
					emitterHit.setEmitterData( emitterHitData, action );
				//	emitterHit.active = true;
				//	emitterHit.action = action;
				}
			}
		}
		
		public static function addTimer(entity:Entity, timedEvent:TimedEvent):void
		{
			if(entity.group)
			{
				entity.group.addSystem( new TimerSystem(), SystemPriorities.update );
			}
			
			var timer:Timer = entity.get(Timer);
			
			if(timer == null)
			{
				timer = new Timer();
				entity.add(timer);
			}
			
			timer.addTimedEvent(timedEvent);
		}
		
		public static function turnOffSleep(entity:Entity):void
		{
			entity.sleeping = false;
			var sleep:Sleep = entity.get(Sleep);
			
			if(!sleep)
				sleep = new Sleep();
			
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;			
		}
		
		public static function loadAndSetToDisplay(container:DisplayObjectContainer, url:String, entity:Entity, group:DisplayGroup, callback:Function = null, removeMouseInteraction:Boolean = false):void
		{
			group.loadFileDeluxe(url, true, true, fileLoaded, container, entity, callback, removeMouseInteraction);
		}
		
		public static function fileLoaded(asset:DisplayObjectContainer, container:DisplayObjectContainer, entity:Entity, callback:Function = null, removeMouseInteraction:Boolean = false):void
		{
			var display:Display = entity.get(Display);
			
			if(display == null)
			{
				display = new Display();
				entity.add(display);
			}
			
			if(container != null)
			{
				display.setContainer( container );
			}
			
			if(display.container != null && !display.container.contains(asset))
			{
				display.container.addChild(asset);
			}
			
			display.displayObject = asset;
			
			var spatial:Spatial = entity.get(Spatial);
						
			if(spatial != null)
			{
				EntityUtils.syncFromSpatial(spatial, asset);
			}
			
			if(removeMouseInteraction)
			{
				asset.mouseChildren = false;
				asset.mouseEnabled = false;
			}
			
			if(callback != null)
			{
				callback(asset, entity);
			}
		}
		
		/**
		 * Gets the WordBalloonNode NodeList and immediately stop/removes all word balloons coming from the given entity. If
		 * no entity is specified, all currently running word balloons are stopped/removed.
		 */
		public static function removeAllWordBalloons(group:Group, entity:Entity = null):void
		{
			var nodeList:NodeList = group.systemManager.getNodeList(WordBalloonNode);
			var node:WordBalloonNode;
			var parent:Parent;
			
			for ( node = nodeList.head; node; node = node.next )
			{
				parent = node.entity.get(Parent);
				
				if(entity == null || parent.parent == entity)
				{
					node.entity.group.removeEntity(node.entity, true);
				}
			}
		}
	}
}