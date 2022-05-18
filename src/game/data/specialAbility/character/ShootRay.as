// Used by:
// Card 2896 using facial ??? (shoot on space bar)

package game.data.specialAbility.character
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.character.CharacterWander;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.ConfettiBlast;
	import game.scene.template.PlatformerGameScene;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.DiscZone;

	/**
	 * Shoot projectile ray swf from facial part to simulate rays from eyes
	 * 
	 * Required params:
	 * rayPath			String		Path to ray swf such as limited/Incredibles2Quest/ray.swf
	 * 
	 * Optional params:
	 * speed			Number		Ray speed (default is 1800)
	 * offsetX			Number		Horizontal offset from facial in either direction to allow for face so that ray exits from the end of the face; a positive number outward from hand (default is 10)
	 * offsetY			Number		Vertical offset from facial part; usually a negative number (default is -5)
	 * targetPrefix		String		Target prefix for instance names in hit/interactive container (these objects in scene will explode when shot)
	 * min				Number		Minimum size of shard during explosion (default is 4)
	 * max				Number		Maximum size of shard during explosion (default is 7)
	 * colors			Array		Color array of color values of shard colors (default is confetti colors)
	 * edges			Boolean		Shoot edges of scene
	 * inset			Number		Inset from right edge of screen for obstacle location before it is shootable (default is 0, larger values will cause the object to appear more on screen before it can blasted)
	 */
	public class ShootRay extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			_loaded = false;
			
			// load ray
			super.loadAsset(_rayPath, loadComplete);
			if(_makeIcicle)
				super.loadAsset(_iciclePath, loadCompleteIce);
		}
		/**
		 * when ice clip is loaded 
		 * @param clip
		 */
		private function loadCompleteIce(clip:MovieClip):void
		{
			_icicleClip = clip;
			_icicle = new Entity();
			_icicle.add(new Display(clip));
			_icicle.add(new Spatial());
		}
		/**
		 * when ray clip is loaded 
		 * @param clip
		 */
		private function loadComplete(clip:MovieClip):void
		{
			// return if no clip
			if (clip == null)
				return;
			
			super.setActive(true);
			
			// remember ray clip
			_rayClip = clip;
			// set loaded flag
			_loaded = true;
			
			// if target prefix, then get all targets in scene that start with prefix
			if ((_targetPrefix) && (_targets == null))
			{
				var hitContainer:MovieClip = MovieClip(PlatformerGameScene(super.group).hitContainer);
				_targets = [];
				if(_targetNPCs)
				{
					var npcList:NodeList = group.systemManager.getNodeList( NpcNode );
					var npcNode:NpcNode;
					for( npcNode = npcList.head; npcNode; npcNode = npcNode.next )
					{
						// get NPC entity and display object
						var npcEntity:Entity = npcNode.entity;
						_targets.push(npcEntity);
					}
				}
				else
				{
					for (var i:int = hitContainer.numChildren - 1; i!= -1; i--)
					{
						var child:DisplayObject = hitContainer.getChildAt(i);
						if (child.name.substr(0, _targetPrefix.length) == _targetPrefix)
						{
							_targets.push(super.group.getEntityById(child.name));
						}
					}
				}
			}
			
			shoot();
		}
		
		/**
		 * When avatar shoots 
		 */
		private function shoot():void
		{
			// if ray swf loaded
			if (_loaded)
			{
				// set starting location of ray in scene				
				var facialSpatial:Spatial = CharUtils.getPart(super.entity, _part).get(Spatial);
				var avatar:DisplayObject = DisplayObject(super.entity.get(Display).displayObject);
				// point relative to avatar
				var point:Point = new Point(facialSpatial.x - _offsetX / avatar.scaleY, facialSpatial.y + _offsetY / avatar.scaleY);
				point = avatar.localToGlobal(point);
				// point relative to scene
				point = avatar.parent.globalToLocal(point);
				
				// get avatar facing direction
				var dir:Number = 1;
				// Flip the object if you're facing left
				if (super.entity.get(Spatial).scaleX > 0)
				{
					dir = -1;
				}
				
				if (_ray == null)
				{
					_ray = new Entity();
					var display:Display = new Display(_rayClip, super.entity.get(Display).container);
					_ray.add(display);
					
					var spatial:Spatial = new Spatial();
					var motion:Motion = new Motion();
					
					// flip if going left
					if (dir == -1)
						spatial.scaleY = -1;
					
					_ray.add(spatial);
					_ray.add(motion);
					
					super.group.addEntity(_ray);
				}
				else
				{
					spatial = _ray.get(Spatial);
					motion = _ray.get(Motion);
				}
				spatial.x = point.x;
				spatial.y = point.y;
				
				// get rotation and angle of avatar
				var rotation:Number = super.entity.get(Spatial).rotation;
				// if flipped to right, then flip rotation
				if (dir == 1)
					rotation = 180 - rotation;
				var angle:Number = rotation / 180 * Math.PI;
				var firingSpeedX:Number = -_speed * Math.cos(angle);
				var firingSpeedY:Number = dir * _speed * Math.sin(angle);
				var radians:Number = Math.atan2(firingSpeedY, firingSpeedX);
				spatial.rotation = radians * 180 / Math.PI;
				motion.velocity = new Point(firingSpeedX, firingSpeedY);
				
				if (_edges)
				{
					// check edges of screen
					// get left edge (find center point, then shift to left applying camera scale)
					var edge:Number = shellApi.camera.viewport.x + shellApi.camera.viewport.width / 2 * (1 - 1 / shellApi.camera.scale);
					
					// if facing right
					if (dir == 1)
					{
						// get right edge (applying camera scale)
						edge += (shellApi.camera.viewport.width / shellApi.camera.scale);
						var dist:Number = edge - point.x;
					}
					else
					{
						dist = point.x - edge;
					}
					trace(dist);
					trace("scale " + PlatformerGameScene(super.group).container.scaleX);
					var yHit:Number = point.y - Math.sin(radians) * dist;
					explode(edge, yHit);
				}
			}
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			// if shooting then check collisions with special objects (look for closest one)		
			if (((_ray != null) && (_targetPrefix) && (_targets.length != 0)) || (_ray != null) && (_makeIcicle))
			{		
				var raySpatial:Spatial = _ray.get(Spatial);
				
				// don't explode things off screen
				var rightEdge:Number = shellApi.camera.viewport.x + shellApi.camera.viewport.width/PlatformerGameScene(super.group).container.scaleX;
				if (_ray.get(Motion).velocity.x > 0)
				{
					if (raySpatial.x > rightEdge)
						return;
				}
				else
				{
					if (raySpatial.x < shellApi.camera.viewport.x)
						return;
				}
				
				var len:int = _targets.length;
				var beyond:Boolean = true;
				var avatarX:Number = super.entity.get(Spatial).x;
				if(_makeIcicle)
				{
					//makeIcicle();
				}
				for (var i:int = len-1; i!=-1; i--)
				{
					var target:Entity = _targets[i];
					var spatial:Spatial = target.get(Spatial);
					if(spatial == null)
						spatial = new Spatial(0,0);
					// if within bounds of clip (clip has reg point in center)
					// assume anything that lies in the path of the ray should get hit
					var forwardDist:Number = spatial.x - raySpatial.x;
					if ((forwardDist > 0) && (spatial.x < rightEdge - _inset) && (Math.abs(raySpatial.y - spatial.y) < spatial.height))
					{
						// remove from list of targets
						//_targets.splice(i,1);
						if(_makeIcicle)
						{
							makeIcicle(target);
						}
						else
						{
							// make invisible
							target.get(Display).visible = false;
							// create explosion
							explode(spatial.x, spatial.y);
							// remove from scene
							super.group.removeEntity(target);
						}
					}
					// if avatar is in front of target, then turn off beyond flag
					else if ((beyond) && (avatarX < spatial.x))
					{
						beyond = false;
					}
				}
				// if avatar is beyond all obstacles, then stop shooting
				if (beyond)
				{
					// turn off special ability
					super.setActive(false);
				}
			}
		}
		private function makeIcicle(target:Entity):void
		{
			
			var wander:CharacterWander = target.get(CharacterWander);
			if(wander)
				wander.pause = true;// this apparentally means didally squat
			//lock that char and hide it
			EntityUtils.lockSceneInteraction(target);
			EntityUtils.freeze(target,true);
			CharUtils.freeze(target, true);
			var icicle:Entity = new Entity();
			icicle = EntityUtils.createDisplayEntity(super.group,_icicleClip,super.entity.get(Display).container);
			icicle.add(new Spatial());
			icicle.get(Spatial).x = target.get(Spatial).x;
			icicle.get(Spatial).y = target.get(Spatial).y;
			SceneUtil.delay(this, 3, Command.create(revitalizeNpc, target,icicle));
	
		}
		
		
		private function revitalizeNpc(npc:Entity,icicle:Entity):void
		{
			var wander:CharacterWander = npc.get(CharacterWander);
			if(wander)
				wander.pause = false;
		
				SceneInteraction(npc.get(SceneInteraction)).activated = false;
				EntityUtils.lockSceneInteraction(npc, false);
				EntityUtils.freeze(npc,false);
				CharUtils.freeze(npc, false);
				removeEntity(icicle);

		}
		private function explode(x:Number, y:Number):void
		{
			// create explosion
			var explode:ConfettiBlast = new ConfettiBlast();
			explode.init(_colors, 30);						
			explode.addInitializer( new ChooseInitializer([new ImageClass(Blob, [_min, 0xFFFFFF], true),new ImageClass(Blob, [_max, 0xFFFFFF], true)]));
			explode.addInitializer( new Lifetime( 4, 12 ) );
			explode.addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 2 ) ) );
			explode.addAction( new Accelerate( 0, 500 ) );
			if (_explodeSound)
				AudioUtils.play(super.group, _explodeSound);
			EmitterCreator.create(super.group, PlatformerGameScene(super.group).hitContainer, explode, x, y, super.entity, "explode");
			
			// get explosion Entity
			var explosion:Entity = super.group.getEntityById("explosionEffect");
			if (explosion != null)
			{
				explosion.get(Timeline).gotoAndPlay(2);
				explosion.get(Spatial).x = x;
				explosion.get(Spatial).y = y;
			}
		}
				
		public var required:Array = ["rayPath"];
		
		public var _rayPath:String;
		public var _speed:Number = 1800;
		public var _offsetX:Number = 10;
		public var _offsetY:Number = -5;
		public var _targetPrefix:String;
		public var _min:Number = 4;
		public var _max:Number = 7;
		public var _explodeSound:String;
		public var _colors:Array;
		public var _edges:Boolean = false;
		public var _inset:Number = 0;
		public var _part:String = SkinUtils.FACIAL;
		public var _makeIcicle:Boolean = false;
		public var _iciclePath:String;
		public var _targetNPCs:Boolean = false;
		
		private var _ray:Entity;
		private var _icicle:Entity;
		private var _loaded:Boolean;
		private var _rayClip:MovieClip;
		private var _icicleClip:MovieClip;
		private var _targets:Array;
		private var _hitContainer:MovieClip;
	}
}