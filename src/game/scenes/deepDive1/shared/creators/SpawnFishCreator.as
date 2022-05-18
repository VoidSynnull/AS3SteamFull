package game.scenes.deepDive1.shared.creators
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.EntityType;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.motion.Edge;
	import game.components.audio.HitAudio;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.entity.Parent;
	import game.components.entity.Sleep;
	import game.components.motion.TargetSpatial;
	import game.components.motion.RotateControl;
	import game.components.motion.RotateToVelocity;
	import game.components.motion.TargetEntity;
	import game.managers.EntityPool;
	import game.scene.template.AudioGroup;
	import game.scenes.deepDive1.shared.components.Spawn;
	import game.scenes.deepDive1.shared.data.FishData;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.Utils;

	/**
	 * Used by  SpawnSystem to create entities
	 * @author Billy Belfield
	 * 
	 */
	public class SpawnFishCreator
	{
		public function SpawnFishCreator(group:Group, container:DisplayObjectContainer, pool:EntityPool)
		{
			_group = group;
			_container = container;
			_pool = pool;
			_total = new Dictionary();
		}
		
		/**
		 * Used by SpawnSystem to create entities
		 * @param data
		 * @param x
		 * @param y
		 * @param parent
		 * @param childNumber
		 * @return 
		 * 
		 */
		public function createFromData(data:FishData, x:Number, y:Number, parent:Entity = null, childNumber:int = 0):Entity
		{
			var motion:Motion;
			var spatial:Spatial;
			var sleep:Sleep;
			var entity:Entity = _pool.request(data.type);
			var init:Boolean = false;

			var type:EntityType;
			
			if(!_total[data.type]) { _total[data.type] = 0; }
			_total[data.type]++;
			
			var aimTarget:Spatial = this.target;
			
			if(parent)
			{
				aimTarget = parent.get(Spatial);
			}
			
			if(entity == null)
			{
				init = true;
				entity = new Entity();
				motion = new Motion();

				sleep = new Sleep();
				sleep.useEdgeForBounds = true;
				sleep.ignoreOffscreenSleep = data.ignoreOffscreenSleep;
				spatial = new Spatial();
				spatial.scale = data.scale;
				type = new EntityType(data.type);

				var randomVelocity:Number = Utils.randInRange(data.minVelocity, data.maxVelocity);
				var dx:Number = aimTarget.x - x;
				var dy:Number = aimTarget.y - y;
				var angle:Number = Math.atan2(dy, dx) + (data.targetOffset - Math.random() * (data.targetOffset * 2));
				spatial.rotation = angle * (180 / Math.PI);
				motion.velocity.x = Math.cos(angle) * randomVelocity;
				motion.velocity.y = Math.sin(angle) * randomVelocity;
				
				if(data.asset != null)
				{
					_group.shellApi.loadFile(_group.shellApi.assetPrefix + data.asset, assetLoaded, entity, _container);
				} 
				else if(data.clip != null)
				{
					entity.add(new Display(data.clip));
				}
				
				entity.add(spatial);
				entity.add(new Id(data.type + _total[data.type]));
				entity.add(new Audio());
				entity.add(new AudioRange(600, 0.01, 1));
				entity.add(new HitAudio());
				//if(_audioGroup) { _audioGroup.addAudioToEntity(entity); }
				entity.add(sleep);
				entity.add(motion);
				entity.add(new Edge(200, 200, 200, 200));
				//entity.add(damageTarget);
				entity.add(type);
				entity.add(new EntityType(data.type));
				//entity.add(hit);
				//entity.add(hazard);
				//entity.add(new PointValue(data.value));
				
				// fish specific
				var rotToVel:RotateToVelocity = new RotateToVelocity(0,0.7);
				rotToVel.pause = true;
				rotToVel.mirrorHorizontal = true;
				rotToVel.originY = spatial.scaleY;
				entity.add(rotToVel);
				
				if(data.component != null)
				{
					entity.add(new data.component());
				}
				
				if(data.followTarget)
				{
					var motionControlBase:MotionControlBase = new MotionControlBase();
					motionControlBase.acceleration = data.acceleration;
					motionControlBase.freeMovement = true;
					motionControlBase.accelerate = true;
					
					entity.add(motionControlBase);
					entity.add(new MotionTarget());
					entity.add(new TargetEntity(0, 0, aimTarget, false));
				}
				
				if(data.faceTarget)
				{
					entity.add(new TargetSpatial(aimTarget));
					
					var rotateControl:RotateControl = new RotateControl();
					rotateControl.origin = spatial;
					rotateControl.ease = data.rotationEasing;
					entity.add(rotateControl);
				}
				
				_group.addEntity(entity);
			}
			else
			{
				motion = entity.get(Motion);
				sleep = entity.get(Sleep);
				sleep.sleeping = false;
				entity.ignoreGroupPause = false;
				sleep.ignoreOffscreenSleep = data.ignoreOffscreenSleep;
				spatial = entity.get(Spatial);
			}
			
			spatial.x = x;
			spatial.y = y;

			//_audioGroup.addAudioToEntity(entity, "enemy");
			
			return(entity);
		}
		
		public function releaseEntity(entity:Entity, releaseToPool:Boolean = true):void
		{
			var sleep:Sleep = entity.get(Sleep);
			sleep.sleeping = true;
			entity.ignoreGroupPause = true;
			sleep.ignoreOffscreenSleep = true;
			
			var id:Id = entity.get(Id);
			var type:EntityType = entity.get(EntityType);
			var released:Boolean = false;
			
			if(releaseToPool) 
			{ 
				if(_pool.release(entity, type.type))
				{
					released = true;
				}
			}
			else
			{
				released = true;
				_group.removeEntity(entity);
			}
			
			if(released)
			{
				var parent:Parent = entity.get(Parent);
				
				if(parent)
				{
					var spawn:Spawn = parent.parent.get(Spawn);
					
					if(spawn)
					{
						spawn.totalFromThisSpawn--;
					}
				}
				
				_total[type.type]--;
			}
		}
		
		private function assetLoaded(clip:MovieClip, entity:Entity, container:DisplayObjectContainer):void
		{
			var spr:Sprite = DisplayUtils.convertToBitmapSprite(clip).sprite;
			
			container.addChild(spr);
			
			entity.add(new Display(spr,container));
			EntityUtils.getDisplay(entity).moveToBack();
			
			if(clip.totalFrames < 2 && clip.numChildren == 1)
			{
				//DisplayUtils.cacheAsBitmap(clip);
				DisplayUtils.convertToBitmapSprite(clip).sprite;
			}
			clip.mouseChildren = false;
			clip.mouseEnabled = false;
		}
		
		/**
		 * Creates Entities that spawn off screen. 
		 * @param entityType
		 * @param data
		 * @param group
		 * @param max
		 * @param rate
		 * @param target
		 * @param targetOffset
		 * @return 
		 */
		public function createOffscreenSpawn(entityType:String, data:FishData, group:Group, max:Number = 10, rate:Number = .5, target:Spatial = null, targetOffset:Number = 0):Spawn
		{
			if(target == null)
			{
				target = group.shellApi.player.get(Spatial);
			}
			
			var entity:Entity = new Entity();
			entity.add(new Id(String(entityType)));
			var spawn:Spawn = new Spawn(entityType, rate, new Rectangle(0, 0, group.shellApi.viewportWidth, group.shellApi.viewportHeight), target, data);
			spawn.distanceFromAreaEdge = 100;
			spawn.max = max;
			spawn.targetOffset = targetOffset;
			
			entity.add(spawn);
			
			var spatial:Spatial = entity.get(Spatial);
			
			if(spatial == null)
			{
				spatial = new Spatial();
				entity.add(spatial);
			}
			
			group.addEntity(entity);
			
			return(spawn);
		}
		
		public function getTotal(entityType:String = null):int 
		{ 
			if(entityType == null)
			{
				var grandTotal:int = 0;
				
				for each(var typeTotal:int in _total)
				{
					grandTotal += typeTotal;
				}
				
				return(grandTotal);
			}
			else
			{
				return(_total[entityType]);
			}
		}
		
		public var target:Spatial;
		private var _pool:EntityPool;
		private var _group:Group;
		private var _container:DisplayObjectContainer;
		private var _total:Dictionary;
		private var _audioGroup:AudioGroup;
	}
}