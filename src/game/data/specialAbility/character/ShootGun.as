// Used by:
// Card ???? using item ad_gh_blaster (shoot on space bar)
// item limited_gh_blaster in Galactic Hot Dogs Quest game (continuous shooting)
// Card ???? using item limited_plawman_game (continuous shooting)

package game.data.specialAbility.character
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.character.animation.RigAnimation;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.custom.ShootArm;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.ConfettiBlast;
	import game.scene.template.PlatformerGameScene;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.DiscZone;
	
	/**
	 * Shoot projectile swf from gun
	 * 
	 * Required params:
	 * bulletPath		String		Path to bullet such as limited/GalacticHotDogsQuest/bullet.swf
	 * 
	 * Optional params:
	 * speed			Number		Bullet speed (default is 1800)
	 * delay			Number		Delay between bullets, includes time to raise hand (default is 0.5)
	 * offsetX			Number		Horizontal offset from hand in either direction to allow for gun so that bullet exits from the end of the pistol; a positive number outward from hand (default is 40)
	 * offsetY			Number		Vertical offset from hand to top of pistol; usually a negative number (default is -13)
	 * continuous		Boolean		Guns shoots continuously (default if false)
	 * targetPrefix		String		Target prefix for instance names in hit/interactive container (these objects in scene will explode when shot)
	 * min				Number		Minimum size of shard during explosion (default is 4)
	 * max				Number		Maximum size of shard during explosion (default is 7)
	 * colors			Array		Color array of color values of shard colors (default is confetti colors)
	 */
	public class ShootGun extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			_loaded = false;
			
			// load bullet
			super.loadAsset(_bulletPath, loadComplete);
			
			// first let's check if there is already an RigAnimation in the next slot, which would be 1.
			var rigAnim:RigAnimation = CharUtils.getRigAnim( super.entity, 1 );
			
			// if there isn't an animation slot above our default then we add a new animation slot
			if ( rigAnim == null )
			{
				// we create a new animation slot Entity using the AnimationSlotCreator
				// if a slot priority isn't specified it will add one to the next available slot
				var animationSlot:Entity = AnimationSlotCreator.create( super.entity );
				
				// now that we have a new animation slot, let's get it's RigAnimation so we can set it later.
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
			}
			
			// We set the RigAnimation's next animation to be ShootArm or Salute (if not continuous)
			if (_continuous)
				rigAnim.next = ShootArm;
			else
				rigAnim.next = Salute;
			
			// We then specify which parts the animation should apply to.
			// We want the character to run while he shoots
			// so have the animation apply to the front hand and arm only
			rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.ARM_FRONT);
			
			// start delay, which includes time to raise hand
			if (_continuous)
				SceneUtil.addTimedEvent( super.group, new TimedEvent( _delay, 0, shoot ), "gunning");
			else
			{
				// wait for raised hand
				CharUtils.getTimeline(super.entity, 1).handleLabel("raised", shoot);
				
				// start delay, which includes time to raise hand
				SceneUtil.addTimedEvent(super.group, new TimedEvent( _delay, 1, resetGun ) );
			}
		}
		
		/**
		 * when bullet clip is loaded 
		 * @param clip
		 */
		private function loadComplete(clip:MovieClip):void
		{
			// return if no clip
			if (clip == null)
				return;
			
			super.setActive(true);
			
			// remember bullet clip
			_bulletClip = clip;
			// set loaded flag
			_loaded = true;
			
			// if target prefix, then get all targets in scene that start with prefix
			if(_targetPrefix)
			{
				var hitContainer:MovieClip = MovieClip(PlatformerGameScene(super.group).hitContainer);
				_targets = [];
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
		
		/**
		 * When avatar shoots 
		 */
		private function shoot():void
		{
			// if bullet loaded
			if (_loaded)
			{
				_shooting = true;
				
				// set starting location of bullet in scene				
				var handSpatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
				var avatar:DisplayObject = DisplayObject(super.entity.get(Display).displayObject);
				// point relative to avatar
				var point:Point = new Point(handSpatial.x - _offsetX / avatar.scaleY, handSpatial.y + _offsetY / avatar.scaleY);
				point = avatar.localToGlobal(point);
				// point relative to scene
				point = avatar.parent.globalToLocal(point);
				
				// get avatar facing direction
				var dir:Number = 1;
				// Flip the object if you're facing Left
				if (super.entity.get(Spatial).scaleX > 0)
					dir = -1;
				
				if (_bullet == null)
				{
					_bullet = new Entity();
					var display:Display = new Display(_bulletClip, super.entity.get(Display).container);
					_bullet.add(display);
					
					var spatial:Spatial = new Spatial();
					var motion:Motion = new Motion();
					
					_bullet.add(spatial);
					_bullet.add(motion);
					
					super.group.addEntity(_bullet);
				}
				else
				{
					spatial = _bullet.get(Spatial);
					motion = _bullet.get(Motion);
				}
				spatial.x = point.x;
				spatial.y = point.y;
				_startX = point.x;
				
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
			if ((_targetPrefix) && (_targets.length != 0))
			{
				// don't explode things off screen (use half screen width)
				if (Math.abs(_bulletClip.x - _startX) > 480)
					return;
				
				var len:int = _targets.length;
				var beyond:Boolean = true;
				var avatarX:Number = super.entity.get(Spatial).x;
				for (var i:int = len-1; i!=-1; i--)
				{
					var target:Entity = _targets[i];
					var spatial:Spatial = target.get(Spatial);
					// if within bounds of clip (clip has reg point in center)
					if ((Math.abs(_bulletClip.x - spatial.x) < spatial.width) && (Math.abs(_bulletClip.y - spatial.y) < spatial.height))
					{
						// remove from list of targets
						_targets.splice(i,1);
						// make invisible
						target.get(Display).visible = false;
						
						// create explosion
						explode(spatial.x, spatial.y);
						super.group.removeEntity(target);
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
					// turn off timer
					SceneUtil.getTimer( super.group, "gunning" ).active = false;
					// restore arm
					CharUtils.getRigAnim( super.entity, 1 ).manualEnd = true;
				}
			}
		}
		
		/**
		 * Reset gun and remove bullet 
		 */
		private function resetGun():void
		{
			_shooting = false;
			super.group.removeEntity(_bullet);
			_bullet = null;
			super.setActive(false);
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
		
		public var required:Array = ["bulletPath"];
		
		public var _bulletPath:String;
		public var _speed:Number = 1800;
		public var _delay:Number = 0.5;
		public var _offsetX:Number = 40;
		public var _offsetY:Number = -13;
		public var _continuous:Boolean = false;
		public var _edges:Boolean = false;
		public var _targetPrefix:String;
		public var _min:Number = 4;
		public var _max:Number = 7;
		public var _explodeSound:String;
		public var _colors:Array;
		
		private var _bullet:Entity;
		private var _loaded:Boolean;
		private var _bulletClip:MovieClip;
		private var _targets:Array;
		private var _startX:Number;
		private var _shooting:Boolean = false;
	}
}