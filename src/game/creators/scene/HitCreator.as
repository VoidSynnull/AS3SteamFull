package game.creators.scene
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.audio.HitAudio;
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.BitmapHit;
	import game.components.hit.Bounce;
	import game.components.hit.BounceWire;
	import game.components.hit.Ceiling;
	import game.components.hit.Climb;
	import game.components.hit.CurrentHit;
	import game.components.hit.EntityIdList;
	import game.components.hit.Hazard;
	import game.components.hit.Mover;
	import game.components.hit.Platform;
	import game.components.hit.PlatformRebound;
	import game.components.hit.Radial;
	import game.components.hit.Wall;
	import game.components.hit.Water;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Looper;
	import game.components.render.PlatformDepthCollision;
	import game.components.render.Reflective;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitAudioData;
	import game.data.scene.hit.HitData;
	import game.data.scene.hit.HitDataComponent;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MovingHitData;
	import game.data.scene.labels.LabelData;
	import game.data.sound.SoundAction;
	import game.data.sound.SoundData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.systems.SystemPriorities;
	import game.systems.hit.BounceHitSystem;
	import game.systems.hit.BounceWireSystem;
	import game.systems.hit.CeilingHitSystem;
	import game.systems.hit.ClimbHitSystem;
	import game.systems.hit.HazardHitSystem;
	import game.systems.hit.MoverHitSystem;
	import game.systems.hit.MovingHitSystem;
	import game.systems.hit.PlatformHitSystem;
	import game.systems.hit.PlatformReboundHitSystem;
	import game.systems.hit.ZoneHitSystem;
	import game.systems.render.ReflectionSystem;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;

	public class HitCreator
	{
		public function addHitsFromContainer(container:DisplayObjectContainer, allHitData:Dictionary, group:Group, soundEffects:Dictionary = null):Vector.<Class>
		{			
			var total:Number = container.numChildren;
			var hit:DisplayObjectContainer;
			var hitTypes:Vector.<Class> = new Vector.<Class>;
			var hitData:HitData;
			
			for (var n:Number = total - 1; n >= 0; n--)
			{
				hit = container.getChildAt(n) as DisplayObjectContainer;
				
				
				if (hit != null)
				{
					if(group.getEntityById(hit.name) == null)
					{
						addHit(hit, hitTypes, allHitData[hit.name], group, soundEffects);
					}
					else
					{
						trace("HitCreator :: hit already exists : "+ hit.name);
					}
				}
			}
						
			return(hitTypes);
		}
		
		public function addHitSoundsToEntity(entity:Entity, soundEffects:Dictionary, shellApi:ShellApi, id:String = null):void
		{
			if(soundEffects != null)
			{
				if( !DataUtils.validString(id) )
				{
					var idComponent:Id = entity.get(Id);
					if( idComponent )
					{
						id = idComponent.id;
					}else{
						id = entity.name;
					}
				}
				
				if( DataUtils.validString(id) )
				{
					var allHitAudio:Dictionary = soundEffects[id];
					var hitAudio:HitAudio = entity.get(HitAudio);
					var hitAudioData:HitAudioData = entity.get(HitAudioData);
					
					if(hitAudio == null){
						hitAudio= new HitAudio();
						entity.add(hitAudio);
					}
					
					if(hitAudioData == null)
					{
						hitAudioData = new HitAudioData();
						entity.add(hitAudioData);
					}
					
					if(allHitAudio != null)
					{
						hitAudioData.allEventAudio = allHitAudio;
						shellApi.setupEventTrigger(hitAudioData);
					}
				}
			}
		}
		
		public function addAudioToHit(entity:Entity, audio:*, action:String = SoundAction.IMPACT, shellApi:ShellApi = null):void
		{
			var hitAudioData:HitAudioData = entity.get(HitAudioData);
			var allHitAudio:Dictionary;
			
			if(hitAudioData == null)
			{
				hitAudioData = new HitAudioData();
				entity.add(hitAudioData);
			}
			
			if(audio is Dictionary)
			{
				allHitAudio = audio;
				hitAudioData.allEventAudio = allHitAudio;
				if(shellApi != null)
				{
					shellApi.setupEventTrigger(hitAudioData);
				}
			}
			else
			{
				var soundData:SoundData = new SoundData();
				soundData.asset = SoundManager.EFFECTS_PATH + audio;
				soundData.type = SoundModifier.EFFECTS;
				hitAudioData.currentActions[action] = soundData;
			}
		}
		
		/**
		 * Converts HitData into BitmapHitEntities, while adding sounds. 
		 * Returns Vector of Classes.
		 */
		public function addBitmapHitsFromData(allHitData:Dictionary, group:Group, soundEffects:Dictionary = null):Vector.<Class>
		{
			var hitTypes:Vector.<Class> = new Vector.<Class>;
			var entity:Entity;
			
			for each(var hitData:HitData in allHitData)
			{
				if(hitData.color)
				{
					addBitmapHit(hitTypes, hitData, group, soundEffects);
				}
			}
			
			return(hitTypes);
		}
		
		/***
		 * Creates a new entity with spatial, display, and hit components that match the <code>HitType</code>.
		 * @param clip : A display object to use with a hit area.
		 * @param type : A <code>HitType</code> which determines the behavior of the hit area.
		 * @param data : A instance of a data class to configure the hit area.  Only required for moving hits, but can be used to customize all hit types.
		 * @param group : The group to add this entity to.  Some hits like hazards and moving hits can also add a 'visible' entity that follows
		 *                   the hit area around if the instance name in the _hitContainer is specified in data.
		 * @param static : If true this entity is static and will not be updated by the RenderSystem.
		 */
		public function createHit(clip:DisplayObjectContainer, type:String, hitComponent:* = null, group:Group = null, static:Boolean = true, showHit:Boolean = false):Entity
		{
			var hit:Entity = new Entity();
			var hitTypes:Vector.<Class> = new Vector.<Class>;
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			
			var display:Display = new Display();
			display.displayObject = clip;
			display.isStatic = static;
			display.visible = (this.showHits || showHit);
			
			clip.mouseEnabled = false;
			clip.mouseChildren = false;
			
			// If a clip isn't using the default value of 'instance' than map the id to the entity.
			if(clip.name.indexOf("instance") < 0)
			{
				hit.add(new Id(clip.name));
			}
			
			hit.add(spatial);
			hit.add(new Sleep());
			hit.add(display);
			
			makeHit(hit, type, hitComponent, group);
			
			if(group)
			{
				group.addEntity(hit);
			}
			
			return(hit);
		}
		
		/***
		 * Adds only the hit components to an existing entity that match the <code>HitType</code>.
		 * @param type : A <code>HitType</code> which determines the behavior of the hit area.
		 * @param componentData : A instance of a hit componentData class to configure the hit area.  Only required for moving hits, but can be used to customize all hit types.
		 * @param group : Some hits like hazards and moving hits can also add a 'visible' entity that follows
		 *                   the hit area around if the instance name in the _hitContainer is specified in data.  A group is required in this case
		 *                   to add the new visible entity to.  The passed in entity will NOT be added.
		 */
		public function makeHit(entity:Entity, type:String, componentData:* = null, group:Group = null):Entity
		{
			var hitTypes:Vector.<Class> = new Vector.<Class>;
			var display:Display = entity.get(Display);
			
			if(display)
			{
				addHitComponent(entity, type, hitTypes, display.displayObject, group, componentData)
				
				if(group)
				{
					addHitSystemForType(type, group);
				}
				
				return(entity);
			}
			else
			{
				trace("HitCreator :: Error!  Cannot use 'makeHit' on an entity without a Display component.");
				return(null);
			}
		}
		
		private function addHitType(type:Class, hitTypes:Vector.<Class>, clip:DisplayObjectContainer = null):*
		{
			addType(type, hitTypes);
			
			return(new type());
		}
		
		private function addType(type:Class, hitTypes:Vector.<Class>):void
		{
			if (hitTypes.indexOf(type) < 0)
			{
				hitTypes.push(type);
			}
		}
			
		/**
		 * Turns HitData into Entity containing BitmapHit & Hit components defined within HitData.
		 * Adds entity to group.
		 */
		private function addBitmapHit(hitTypes:Vector.<Class>, hitData:HitData, group:Group, soundEffects:Dictionary = null):Entity
		{
			var bitmapHitEntity:Entity = new Entity();
			var bitmapHit:BitmapHit = new BitmapHit();
			var hitComponents:Dictionary = hitData.components;
			var hitComponent:Component;
			
			for each (var currentComponent:HitDataComponent in hitComponents)
			{
				hitComponent = addHitComponent(bitmapHitEntity, currentComponent.type, hitTypes, null, null, currentComponent);
			}
			
			bitmapHit.data = currentComponent;
			bitmapHit.color = hitData.color;
			bitmapHitEntity.add(bitmapHit);
			bitmapHitEntity.add(hitData);
			bitmapHitEntity.add(new Id(hitData.id));
			
			addHitSoundsToEntity(bitmapHitEntity, soundEffects, group.shellApi);
			
			group.addEntity(bitmapHitEntity);
			
			return(bitmapHitEntity);
		}
		
		private function addHit(clip:DisplayObjectContainer, hitTypes:Vector.<Class>, hitData:HitData, group:Group = null, soundEffects:Dictionary = null):Entity
		{
			var ignore:Boolean = false;
			
			if(hitData)
			{
				if(hitData.color)
				{
					ignore = true;
				}
			}
			
			if (clip is MovieClip && !ignore)
			{				
				var hit:Entity = new Entity();
				var hitAdded:Boolean = false;
				
				var spatial:Spatial = new Spatial();
				spatial.x = clip.x;
				spatial.y = clip.y;
				
				var display:Display = new Display();
				display.displayObject = clip;
				display.isStatic = true;
				display.visible = showHits;
	
				clip.mouseEnabled = false;
				clip.mouseChildren = false;
				
				// If a clip isn't using the default value of 'instance' than map the id to the entity.
				if(clip.name.indexOf("instance") < 0)
				{
					hit.add(new Id(clip.name));
				}
				
				hit.add(spatial);
				hit.add(new Sleep());
				hit.add(display);
				
				if(hitData != null)
				{
					hit.add(hitData);
					
					var hitComponents:Dictionary = hitData.components;
					
					if(hitComponents != null)
					{
						for each (var currentComponent:HitDataComponent in hitComponents)
						{
							if(addHitComponent(hit, currentComponent.type, hitTypes, clip, group, currentComponent) != null)
							{
								hitAdded = true;
							}
						}
					}
				}
				else
				{
					// Derive the hitType from its name if it doesn't have any data associated with it.  This is for simple hittypes like 'bounce' that can work with
					//   default values.
					var hitType:String = getHitType(clip.name.toLowerCase());
					
					if(addHitComponent(hit, hitType, hitTypes, clip, group) != null)
					{
						hitAdded = true;
					}
				}
				
				if(hitAdded)
				{
					if(group != null) 
					{ 
						addHitSoundsToEntity(hit, soundEffects, group.shellApi);
						group.addEntity(hit); 
					}
					return(hit);
				}
			}
					
			return(null);
		}
		
		private function getHitType(name:String):String
		{
			var allHitTypes:Array = [HitType.CEILING, HitType.WALL, HitType.BOUNCE, 
								     HitType.CLIMB, HitType.MOVER, HitType.INTERACTION, HitType.ANIMATION, HitType.HAZARD,
									 HitType.MOVING_PLATFORM, HitType.MOVING_HIT, HitType.PLATFORM, HitType.SCENE, HitType.WATER, 
									 HitType.PLATFORM_TOP, HitType.ZONE, HitType.RADIAL, HitType.WIRE_BOUNCE, HitType.REFLECTIVE, HitType.LOOPER,
									 HitType.PLATFORM_REBOUND];
			var hitType:String;
			
			for(var n:Number = 0; n < allHitTypes.length; n++)
			{
				hitType = allHitTypes[n];
				
				if (name.indexOf(hitType) > -1)
				{
					return(hitType);
				}
			}
			
			// unnamed movieclips default to platforms.
			if(name.indexOf("instance") > -1)
			{
				return(HitType.PLATFORM);
			}
			
			return(null);
		}
		
		private function setupMovingHit(hit:Entity, data:MovingHitData, clip:DisplayObjectContainer):void
		{
			var sleep:Sleep = hit.get(Sleep);
			var spatial:Spatial = hit.get(Spatial);
			var makeVisible:Boolean = false;
			var visibleEntity:Entity = null;
			
			sleep.ignoreOffscreenSleep = true;
			sleep.sleeping = false;
			
			hit.get(Display).isStatic = false;
			hit.add(data);
						
			hit.add(new Motion());
		}

		// Adds a new entity in the game which follows a hidden platform as the visible component.
		private function addVisibleEntity(target:DisplayObjectContainer, data:HitDataComponent, spatial:Spatial):Entity
		{
			var visibleClip:MovieClip = target.parent[data.visible];
			
			if(visibleClip != null)
			{
				visibleClip.mouseChildren = false;
				visibleClip.mouseEnabled = false;
				
				var visible:Entity = new Entity();
				var visibleDisplay:Display = new Display();
				var visibleSpatial:Spatial = new Spatial();
				visibleDisplay.displayObject = visibleClip;
				EntityUtils.syncSpatial(visibleSpatial, visibleClip);
				
				var followTarget:FollowTarget = new FollowTarget();
				followTarget.target = spatial;
				followTarget.rate = 1;
				
				if(data.followProperties)
				{
					followTarget.properties = new Vector.<String>;
					
					for(var n:int = 0; n < data.followProperties.length; n++)
					{
						followTarget.properties.push(data.followProperties[n]);
					}
				}
	
				var id:Id = new Id();
				id.id = data.visible;
				visible.add(id);
				
				visible.add(visibleDisplay);
				visible.add(visibleSpatial);
				visible.add(followTarget);
				
				return(visible);
			}
			
			trace("HitCreator :: Visible displayObject " + data.visible + " not found.");
			
			return(null);
		}
		
		// Adds multiple entities in the game which follows a hidden platform as the visible component
		private function addVisibleEntities(target:DisplayObjectContainer, name:String, data:HitDataComponent, spatial:Spatial):Entity
		{
			var visibleClip:MovieClip = target.parent[name];
			
			if(visibleClip != null)
			{
				visibleClip.mouseChildren = false;
				visibleClip.mouseEnabled = false;
				
				var visible:Entity = new Entity();
				var visibleDisplay:Display = new Display();
				var visibleSpatial:Spatial = new Spatial();
				visibleDisplay.displayObject = visibleClip;
				EntityUtils.syncSpatial(visibleSpatial, visibleClip);
				
				var followTarget:FollowTarget = new FollowTarget();
				followTarget.target = spatial;
				followTarget.rate = 1;
				
				if(data.followProperties)
				{
					followTarget.properties = new Vector.<String>;
					
					for(var n:int = 0; n < data.followProperties.length; n++)
					{
						followTarget.properties.push(data.followProperties[n]);
					}
				}
				
				var id:Id = new Id();
				id.id = name;
				visible.add(id);
				
				visible.add(visibleDisplay);
				visible.add(visibleSpatial);
				visible.add(followTarget);
				
				return(visible);
			}
			trace("HitCreator :: Visible displayObject " + name + " not found.");
			
			return(null);
		}
		
		
		/**
		 * Creates Component defined by hitType, and adds to Entity.
		 * If data is passed it is used to defined the Component's variables. 
		 */
		private function addHitComponent(entity:Entity, hitType:String, hitTypes:Vector.<Class>, clip:DisplayObjectContainer = null, group:Group = null, componentData:*=null):Component
		{
			var hitComponent:*;
			var labelData:LabelData;
			var display:Display = entity.get(Display);
			var visibleEntity:Entity;
			var savedRotation:Number;
			var xml:XML;
			
			switch(hitType)
			{				
				case HitType.WALL :
					hitComponent = addHitType(Wall, hitTypes, clip);
					break;
				
				case HitType.CEILING :
					hitComponent = addHitType(Ceiling, hitTypes, clip);
					break;
				
				// configure with MoverHitData to set the resultant bounce velocity
				case HitType.BOUNCE :
					hitComponent = addHitType(Bounce, hitTypes, clip);
					hitComponent.velocity = new Point(0, -800);
					
					if(componentData != null)
					{
						if(componentData.velocity != null) { hitComponent.velocity = componentData.velocity; }
						if(componentData.animate != null) { hitComponent.animate = componentData.animate; }
						if(componentData.timeline != null) { hitComponent.timeline = componentData.timeline; }
					}
					
					break;
				
				case HitType.CLIMB :
					hitComponent = addHitType(Climb, hitTypes, clip);
					break;
				
				// configure with MoverHitData to setup the movement applied to a collider.
				case HitType.MOVER :
					if(componentData != null)
					{
						hitComponent = addHitType(Mover, hitTypes, clip);
						hitComponent.velocity = componentData.velocity;
						hitComponent.acceleration = componentData.acceleration;
						hitComponent.rotationVelocity = componentData.rotationVelocity;
						hitComponent.friction = componentData.friction;
						hitComponent.stickToPlatforms = componentData.stickToPlatforms;
						hitComponent.overrideVelocity = componentData.overrideVelocity;
					}
					break;
				
				// configure with WaterHitData to set splash color
				case HitType.WATER :
					hitComponent = addHitType(Water, hitTypes, clip);
					hitComponent.splashColor1 = 0xFF66ccff;
					hitComponent.splashColor2 = 0x330099ff;

					if(componentData != null)
					{
						if(componentData.splashColor1 != null) { hitComponent.splashColor1 = componentData.splashColor1; }
						if(componentData.splashColor2 != null) { hitComponent.splashColor2 = componentData.splashColor2; }
						if( !isNaN(componentData.density) ) { hitComponent.density = componentData.density; }	// density is 1 by default
						if( !isNaN(componentData.viscosity) ) { hitComponent.viscosity = componentData.viscosity; }	// viscosity is .98 by default
						if( componentData.sceneWide ) { hitComponent.sceneWide = componentData.sceneWide; }
					}
					break;
				
				// configure with MovingHitData for path and velocity
				case HitType.MOVING_HIT :
					addHitType(Motion, hitTypes, clip);
					setupMovingHit(entity, componentData, clip);
					
					if(componentData.visible == null)
					{
						if(display) { display.visible = true; }
					}
				break;
								
				// configure with MovingHitData to set the path and velocity.
				case HitType.MOVING_PLATFORM :
					addHitType(Motion, hitTypes, clip);
					setupMovingHit(entity, componentData, clip);
					
					if(componentData.visible == null)
					{
						if(display) { display.visible = true; }
					}
				
				// configure with MoverHitData to set the friction of the platform.
				case HitType.PLATFORM_TOP :
				case HitType.PLATFORM :
				case HitType.PLATFORM_REBOUND :
					if(hitType == HitType.PLATFORM_REBOUND)
					{
						hitComponent = addHitType(PlatformRebound, hitTypes, clip);
					}
					else
					{
						hitComponent = addHitType(Platform, hitTypes, clip);
					}
					hitComponent.top = (hitType == HitType.PLATFORM_TOP);
					
					if(clip)
					{
						savedRotation = clip.rotation;
						clip.rotation = 0;
						hitComponent.height = clip.height * .5;
						clip.rotation = savedRotation;
					}
					
					var depth:int = 0;
					
					if(componentData != null)
					{
						if(componentData.friction != null)
						{
							hitComponent.friction = new Point();
							hitComponent.friction.x = componentData.friction.x;
							hitComponent.friction.y = componentData.friction.y;
							break;
						}
						
						if(hitComponent.hasOwnProperty("bounce") && componentData.hasOwnProperty("bounce"))
						{
							hitComponent.bounce = componentData.bounce;
						}
						
						xml = HitDataComponent(componentData).xml;
						if(xml && xml.hasOwnProperty("depth"))
						{
							depth = xml.depth;
						}
					}
					
					var platformDepthCollision:PlatformDepthCollision = new PlatformDepthCollision();
					platformDepthCollision.depth = depth;
					entity.add(platformDepthCollision);
					break;
				
				case HitType.INTERACTION :
					hitComponent = addHitType(SceneInteraction, hitTypes, clip);

					if(componentData != null)
					{
						labelData = componentData.label;
					}
					
					if(labelData == null)
					{
						labelData = new LabelData();
						labelData.type = ToolTipType.CLICK;
					}
					
					if(labelData.offset == null)
					{
						var interactionBounds:Rectangle = clip.getBounds(clip.parent);
						
						labelData.offset = new Point();
						labelData.offset.x = (interactionBounds.x - clip.x) + interactionBounds.width * .5;
						labelData.offset.y = (interactionBounds.y - clip.y) + interactionBounds.height;
					}
					
					if(labelData.id == null)
					{
						labelData.id = clip.name;
					}
					
					if(group != null)
					{
						group.addEntity(ToolTipCreator.addToEntity(entity, labelData.type, labelData.text, labelData.offset, false));
					}
					
					display.alpha = 1;
					display.visible = true;
					clip.mouseEnabled = true;
					InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
					break;
				
				case HitType.ANIMATION :
					display.visible = true;
					break;
				
				// Configure knockback velocity and cooldown with HazardHitData.
				case HitType.HAZARD :
					hitComponent = addHitType(Hazard, hitTypes, clip);					
					if(componentData != null)
					{
						Hazard(hitComponent).velocity = HazardHitData(componentData).knockBackVelocity;
						Hazard(hitComponent).coolDown = HazardHitData(componentData).knockBackCoolDown;
						Hazard(hitComponent).interval = HazardHitData(componentData).knockBackInterval;
						Hazard(hitComponent).velocityByHitAngle = HazardHitData(componentData).velocityByHitAngle;
						Hazard(hitComponent).slipThrough = HazardHitData(componentData).slipThrough;
						
						if(componentData.visible == null)
						{
							if(display) { display.visible = true; }
						}
						
						if(display) { display.isStatic = false; }
					}
					else
					{
						Hazard(hitComponent).velocity = new Point(200, 200);
						Hazard(hitComponent).coolDown = 1;
						Hazard(hitComponent).interval = 0;
					}					
					break;
				
				case HitType.SCENE :
					var spatial:Spatial = entity.get(Spatial);					
					var motion:Motion = new Motion();
					
					motion.acceleration.y = 1320;
					motion.maxVelocity = new Point(700, 900);
					motion.minVelocity = new Point(32, 32);
					
					entity.add(motion);
					// this allows this hit to respond to 'scene' collisions like walls and platforms.
					hitComponent = addHitType(SceneCollider, hitTypes, clip);
					
					var waterCollider:WaterCollider = new WaterCollider();
					//waterCollider.buoyancy = 2.5;
					entity.add(waterCollider);
					
					entity.add(new BitmapCollider());
					entity.add(new CurrentHit());
					
					if(componentData.visible == null)
					{
						if(display) { display.visible = true; }
					}
					
					display.isStatic = false;
					break;
				
				// This hitType should be setup in scene with getEntityById
				case HitType.ZONE :
					hitComponent = addHitType(Zone, hitTypes, clip);
					break;
				
				// Configure velocity rebound multiplier with RadialHitData.
				case HitType.RADIAL :
					hitComponent = addHitType(Radial, hitTypes, clip);
					hitComponent.rebound = .5;
					
					if(clip)
					{
						savedRotation = clip.rotation;
						clip.rotation = 0;
						hitComponent.height = clip.height * .5;
						clip.rotation = savedRotation;
					}
					
					if(componentData != null)
					{
						if(!isNaN(componentData.rebound))
						{
							hitComponent.rebound = Math.abs(componentData.rebound);
						}
					}
					break;
				
				case HitType.WIRE_BOUNCE:
					display.visible = true;
					hitComponent = addHitType(BounceWire, hitTypes, clip);
					if(componentData != null)
					{
						hitComponent.hitChild = componentData.hitChild;
						hitComponent.radius = componentData.radius;
						hitComponent.lineColor = componentData.lineColor;
						hitComponent.lineSize = componentData.lineSize;		
						hitComponent.tension = componentData.tension;
						hitComponent.dampening = componentData.dampening;
					}
					break;
				
				case HitType.REFLECTIVE:
					xml = HitDataComponent(componentData).xml;
					
					display.displayObject = DisplayUtils.convertToBitmap(display.displayObject).bitmap;
					display.visible = true;
					display.alpha 	= xml.alpha;
					
					hitComponent = addHitType(Reflective, hitTypes, clip);
					hitComponent.surface 	= xml.surface;
					hitComponent.type 		= xml.type;
					hitComponent.offsetX	= xml.offsetX;
					hitComponent.offsetY	= xml.offsetY;
					break;
				
				case HitType.LOOPER:
					hitComponent = addHitType( Looper, hitTypes, clip );
					display.isStatic = false;
					
					entity.add( new Sleep( true, true )). add( new Motion());
					break;
				
				case HitType.EMITTER:
					entity.add( componentData );
					break;
			}
			
			if(hitComponent != null)
			{
				entity.add(hitComponent);
				entity.add(new EntityIdList());
			}
			
			if(componentData != null && entity != null && group != null )
			{
				spatial = entity.get(Spatial);	
				if(componentData.visibles != null)
				{
					var name:String;
					for each( name in componentData.visibles )
					{
						if(!group.getEntityById(name)) { group.addEntity(addVisibleEntities(clip, name, componentData, spatial)); }
					}
				}
				if(componentData.visible != null)
				{
					if(!group.getEntityById(componentData.visible)) { group.addEntity(addVisibleEntity(clip, componentData, spatial)); }
				}
			}
			
			return(hitComponent);
		}
		
		public function addHitSystemForType(type:String, group:Group):void
		{
			if(group)
			{
				switch(type)
				{
					case HitType.PLATFORM :
						group.addSystem(new PlatformHitSystem(), SystemPriorities.resolveCollisions);
						break;
					case HitType.PLATFORM_REBOUND :
						// need to sync up with bitmap hit data before this is really usable....
						group.addSystem(new PlatformReboundHitSystem(), SystemPriorities.resolveCollisions);
						break;
					case HitType.CEILING :
						group.addSystem(new CeilingHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case HitType.MOVING_HIT :
						group.addSystem(new MovingHitSystem(), SystemPriorities.move);
						break;
					
					case HitType.BOUNCE :
						group.addSystem(new BounceHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case HitType.CLIMB :
						group.addSystem(new ClimbHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case HitType.MOVER :
						group.addSystem(new MoverHitSystem(), SystemPriorities.resolveParentCollisions);
						break;
					
					case HitType.HAZARD :
						group.addSystem(new HazardHitSystem(), SystemPriorities.resolveCollisions);
						break;
					case HitType.ZONE :
						group.addSystem(new ZoneHitSystem(), SystemPriorities.resolveCollisions);
						break;
					
					case HitType.REFLECTIVE :
						if(PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM)
						{
							group.addSystem(new ReflectionSystem());
						}
						break;
					
					case HitType.WIRE_BOUNCE :
						group.addSystem(new BounceWireSystem(), SystemPriorities.resolveCollisions);
						break;
				}
			}
		}
		
		public var showHits:Boolean = false;
	}
}