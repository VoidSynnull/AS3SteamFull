package game.scenes.backlot.backlotTopDown
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.group.Scene;
	import engine.systems.MotionSystem;
	
	import game.components.motion.Edge;
	import game.components.audio.HitAudio;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionControlBase;
	import game.components.motion.MotionTarget;
	import game.components.motion.Navigation;
	import game.components.entity.Sleep;
	import game.components.entity.character.Player;
	import game.components.entity.collider.BitmapCollider;
	import game.components.hit.CurrentHit;
	import game.components.entity.collider.ItemCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.WeaponControlInput;
	import game.scenes.virusHunter.shared.components.WeaponSlots;
	import game.scenes.virusHunter.shared.creators.LifeBarCreator;
	import game.systems.input.MotionControlInputMapSystem;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.systems.ui.ProgressBarSystem;
	
	import game.scene.template.AudioGroup;
	
	public class CartGroup extends DisplayGroup
	{
		public function CartGroup( container:DisplayObjectContainer = null )
		{
			super(container);
			this.id = "cartGroup";
		}
		
		override public function destroy():void
		{			
			super.groupContainer = null;
			super.destroy();
		}
		
		public function setupScene( scene:Scene, vehicleContainer:DisplayObjectContainer, loadedCallback:Function = null, audioGroup:AudioGroup = null ):void
		{
			_targetGroup = scene;
			
			// this group should inherit properties of the scene.
			super.groupPrefix = scene.groupPrefix;
			super.container = scene.container;
			super.groupContainer = vehicleContainer;
			
			// add it as a child group to give it access to systemManager.
			scene.addChildGroup(this);
			_loadedCallback = loadedCallback;
			
			scene.addSystem(new MoveToTargetSystem(super.shellApi.viewportWidth, super.shellApi.viewportHeight), SystemPriorities.moveControl);  // maps control input position to motion components.
			scene.addSystem(new MotionSystem(), SystemPriorities.move);						// updates velocity based on acceleration and friction.
			super.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			scene.addSystem(new MotionControlInputMapSystem(), SystemPriorities.update);    // maps input button presses to acceleration.
			scene.addSystem(new MotionTargetSystem(), SystemPriorities.move);
			scene.addSystem(new MotionControlBaseSystem(), SystemPriorities.move);
			scene.addSystem(new NavigationSystem(), SystemPriorities.update);			    // This system moves an entity through a series of points for autopilot.
			scene.addSystem(new TargetEntitySystem(), SystemPriorities.update);	
			scene.addSystem(new ProgressBarSystem(), SystemPriorities.lowest);
			_audioGroup = audioGroup;
		}
		
		public function loadCart(  x:Number, y:Number, isPlayer:Boolean = false, id:String = null ):void
		{
			super.shellApi.loadFile( super.shellApi.assetPrefix + "scenes/backlot/backlotTopDown/cart.swf", vehicleLoaded, x, y, isPlayer, id );
			_loading++;
		}
		
		private function parseEnemyData( xml:XML ):void
		{
			//	var enemyDataParser:EnemyDataParser = new EnemyDataParser();
		}
		
		private function vehicleLoaded(clip:MovieClip, x:Number, y:Number, isPlayer:Boolean = false, id:String = null):void
		{
			var entity:Entity = create(super.groupContainer, clip, x, y, _targetGroup.sceneData.bounds, id);
			
			_targetGroup.addEntity(entity);
			
			if(isPlayer)
			{
				InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.KEY_DOWN], clip["selectable"]);
				// add an item collider so this entity can pick up items.
				entity.add(new ItemCollider());
				entity.add(new Player());
			}
			
			
			var lifeBarCreator:LifeBarCreator = new LifeBarCreator(super.parent, super.groupContainer);
			lifeBarCreator.create(entity, "scenes/virusHunter/shared/lifeBar.swf", new Point(0, Edge(entity.get(Edge)).rectangle.top - 20));
			
			_loading--;
			
			if(_loading == 0)
			{
				allShipsLoaded();
			}
		}
		
		public function create( container:DisplayObjectContainer, clip:MovieClip, x:Number, y:Number, bounds:Rectangle, id:String = null ):Entity
		{
			var entity:Entity = new Entity();		
			var spatial:Spatial = new Spatial(x, y);			
			var motion:Motion = new Motion();
			motion.friction 	= new Point(250, 250);
			motion.minVelocity 	= new Point(0, 0);
			motion.maxVelocity 	= new Point(400, 400);
			
			var motionControlBase:MotionControlBase = new MotionControlBase();
			motionControlBase.acceleration = 1200;
			motionControlBase.stoppingFriction = 500;
			motionControlBase.accelerationFriction = 200;
			motionControlBase.maxVelocityByTargetDistance = 500;
			motionControlBase.freeMovement = false;
			
			var edge:Edge = new Edge();
			edge.unscaled.setTo(-50, -50, 100, 100);
			//			
			var damageTarget:DamageTarget = new DamageTarget();
			//			damageTarget.damageFactor = new Dictionary();
			//			damageTarget.damageFactor[WeaponType.ENEMY_GUN] = 1;
			//			damageTarget.maxDamage = 4;
			//			damageTarget.cooldown = .5;
			//			damageTarget.reactToInvulnerableWeapons = false;
			//			
			var movieClipHit:MovieClipHit = new MovieClipHit("v");
			clip.mouseEnabled = false;
			movieClipHit.hitDisplay = clip["hit"];
			movieClipHit.hitDisplay.mouseEnabled = false;
			
			var display:Display = new Display(clip, container);
			
			entity.add(damageTarget);
			entity.add(edge);
			entity.add(spatial);
			entity.add(display);
			entity.add(motion);
			entity.add(new MotionControl());
			entity.add(new MotionTarget());
			entity.add(new Navigation());
			entity.add(new RadialCollider());
			entity.add(new BitmapCollider());
			entity.add(new SceneCollider());
			entity.add(new ZoneCollider());
			entity.add(movieClipHit);
			entity.add(new MotionBounds(bounds));
			entity.add(new Audio());
			entity.add(new HitAudio());
			entity.add(new CurrentHit());
			entity.add(motionControlBase);
			entity.add(new WeaponSlots());
			entity.add(new WeaponControlInput(Keyboard.SPACE));
			entity.add(new Tween());
			
			if(id != null) { entity.add(new Id(id)); }
			
			var platformCollider:PlatformCollider = new PlatformCollider();
			//platformCollider.stickToPlatforms = false;
			
			entity.add(platformCollider);
			
			var sleep:Sleep = new Sleep();
			sleep.ignoreOffscreenSleep = true;
			entity.add(sleep);
			
			container.addChild(clip);
			
			if(_audioGroup) 
			{ 
				_audioGroup.addAudioToEntity( entity ); 
			}
			
			return(entity);
		}
		
		private function allShipsLoaded():void
		{
			_loadedCallback();
		}
		
		private var _audioGroup:AudioGroup;
		private var _loadedCallback:Function;
		private var _loading:Number = 0;
		private var _targetGroup:Scene;
		[Inject]
		public var _systemManager:Engine;
	}
}