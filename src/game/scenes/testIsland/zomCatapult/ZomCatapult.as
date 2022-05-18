package game.scenes.testIsland.zomCatapult
{
	import com.greensock.easing.Elastic;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.motion.MotionControl;
	import game.components.motion.nape.NapeMotion;
	import game.components.motion.nape.NapeSpace;
	import game.components.timeline.Timeline;
	import game.creators.motion.nape.NapeCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Dizzy;
	import game.scene.template.GameScene;
	import game.scene.template.NapeGroup;
	import game.scenes.testIsland.zomCatapult.components.CatapultArm;
	import game.scenes.testIsland.zomCatapult.components.Projectile;
	import game.scenes.testIsland.zomCatapult.components.Zombie;
	import game.scenes.testIsland.zomCatapult.creators.ZombieCreator;
	import game.scenes.testIsland.zomCatapult.systems.ProjectileSystem;
	import game.scenes.testIsland.zomCatapult.systems.ZombieSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.DestinationSystem;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import nape.callbacks.CbEvent;
	import nape.callbacks.CbType;
	import nape.callbacks.InteractionCallback;
	import nape.callbacks.InteractionListener;
	import nape.callbacks.InteractionType;
	import nape.callbacks.PreCallback;
	import nape.callbacks.PreFlag;
	import nape.dynamics.CollisionArbiter;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	
	public class ZomCatapult extends GameScene
	{
		
		private static const ROCK:String 					= "rock";
		private static const BALL:String					= "ball";
		private static const SINK:String					= "sink";
		private static const COW:String						= "cow";
		private static const TRASH:String					= "trash";
		
		public function ZomCatapult()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/testIsland/zomCatapult/";
			
			super.init(container);
			
			// SVN Test
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			//SceneUtil.setCameraPoint(this, 400 , 1100, true);
			//shellApi.player.remove(CharacterMovement);
			
			Rectangle(super.sceneData.bounds).height -= 100;
			setupPhysics();
			Rectangle(super.sceneData.bounds).height += 100;
			
			// preload
			shellApi.loadFile(shellApi.assetPrefix + "scenes/testIsland/zomCatapult/trash.swf");
			
			setupEntities();
			startIntro();
		}
		
		private function setupEntities():void
		{
			// TODO Auto Generated method stub
			_arm = EntityUtils.createSpatialEntity(this, _hitContainer["arm"]);
			_arm.add(new CatapultArm());
			_base = EntityUtils.createDisplayEntity(this, _hitContainer["base"]);
			
			DisplayUtils.convertToBitmapSprite(_hitContainer["base"]);
			
			_catapultHit = EntityUtils.createDisplayEntity(this, _hitContainer["catapultHitArea"]);
			interaction = InteractionCreator.addToEntity(_catapultHit, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			
			readyCatapult();
			
			Spatial(player.get(Spatial)).x = 255;
			Spatial(player.get(Spatial)).y = super.sceneData.bounds.height;
			
			shellApi.player.remove(CharacterMovement);
			shellApi.player.remove(CharacterMotionControl);
			
			// create test zombie
			zombieCreator = new ZombieCreator(this);
			zombieCreator.create(6);
			
			super.addSystem(new DestinationSystem(), SystemPriorities.update);
			super.addSystem(new ZombieSystem(), SystemPriorities.update);
			super.addSystem(new ProjectileSystem(), SystemPriorities.update);
			super.addSystem(new TimelineControlSystem());
			super.addSystem(new TimelineClipSystem());
			
			// setup conveyor
			shellApi.loadFile(shellApi.assetPrefix + "scenes/testIsland/zomCatapult/conveyor.swf", createConveyor);
		}
		
		private function createConveyor(clip:MovieClip):void
		{
			_conveyor = EntityUtils.createSpatialEntity(this, clip);
			Spatial(_conveyor.get(Spatial)).y = this.shellApi.viewportHeight+Spatial(_conveyor.get(Spatial)).height;
			_conveyorAni = TimelineUtils.convertClip(clip, this, null, _conveyor, false, 60);
			this.overlayContainer.addChild(clip);
		}
		
		private function startIntro():void{
			SceneUtil.setCameraPoint(this, this.sceneData.bounds.width - 100, Spatial(this.player.get(Spatial)).y, false, 0.012);
			SceneUtil.addTimedEvent(this, new TimedEvent(6, 1, resetCamera));
		}
		
		private function onDown(entity:Entity):void{
			_arm.remove(Tween);
			TweenUtils.entityTo(_arm, Spatial, 4, {rotation:-30});
			TweenUtils.entityTo(_arm, CatapultArm, 4, {power:1.0});
			
			interaction.down.removeAll();
			interaction.up.add(onUp);
			interaction.releaseOutside.add(onUp);
			
			// start tweening power
		}
		
		private function onUp(entity:Entity):void{
			_arm.remove(Tween);
			TweenUtils.entityTo(_arm, Spatial, 2, {rotation:30, ease:Elastic.easeOut, onComplete:resetCatapult});
			
			throwProjectile(CatapultArm(_arm.get(CatapultArm)).power, TRASH);
			
			interaction.up.removeAll()
			interaction.releaseOutside.removeAll();
			
			// reset power
			CatapultArm(_arm.get(CatapultArm)).power = 0.0;
		}
		
		private function resetCatapult():void{
			_arm.remove(Tween);
			CatapultArm(_arm.get(CatapultArm)).power = 0.0;
			TweenUtils.entityTo(_arm, Spatial, 1, {rotation:0, onComplete:readyCatapult});
		}
		
		private function readyCatapult():void{
			interaction.down.add(onDown);
		}
		
		public function throwProjectile(power:Number, projectile:String = null):void{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"whoosh_09.mp3");
			
			_resettingCamera = false;
			
			// hide conveyor
			TweenUtils.entityTo(_conveyor, Spatial, 0.3, {y:this.shellApi.viewportHeight+Spatial(_conveyor.get(Spatial)).height});
			
			var ballSize:Number = 20;
			var projectileEntity:Entity;
			
			switch(projectile){
				case ROCK:
					projectileEntity = addRock();
					break;
				case SINK:
					projectileEntity = addSink();
					break;
				case TRASH:
					projectileEntity = addTrash();
					break;
				default : 
					projectileEntity = addBall();
					break;
			}
			
			p++;
			projectileEntity.add(new Id("p"+p));
			projectileEntity.add(new Projectile());
			
			var body:Body = projectileEntity.get(NapeMotion).body;
			
			// give it a cbType to listen for collisions
			body.cbTypes.add(_projectileCollisionType);
			body.cbTypes.add(_projectileCollisionType2);
			body.userData.entity = projectileEntity;
			
			// give it some velocity
			var minX:Number = 500;
			var minY:Number = -900;
			
			var x:Number = minX + (power*800);
			var y:Number = minY - (power*1000);
			
			body.velocity = new Vec2(x, y);
			
			Projectile(projectileEntity.get(Projectile)).body = body;
			
			// track with camera
			SceneUtil.setCameraTarget(this, projectileEntity);
			
			_focusedProjectile = projectileEntity;
		}
		
		private function stopCamera(projectileEntity:Entity):void{
			var spatial:Spatial = projectileEntity.get(Spatial);
			if(spatial)
				SceneUtil.setCameraPoint(this, spatial.x, spatial.y);
		}
		
		private function resetCamera():void{
			if(num_zombies <= 0){
				youWin();
			} else {
				SceneUtil.setCameraTarget(this, player);
				TweenUtils.entityTo(_conveyor, Spatial, 0.3, {y:this.shellApi.viewportHeight});
				Timeline(_conveyorAni.get(Timeline)).gotoAndPlay(1);
			}
		}
		
		private function setupPhysics():void{
			_napeGroup = new NapeGroup();
			_napeGroup.setupGameScene(this, _debug);
			
			var areaWidth:int = super.sceneData.bounds.width;
			var areaHeight:int = super.sceneData.bounds.height;	
			
			var spaceEntity:Entity = _napeGroup.getEntityById(NapeCreator.SPACE_ENTITY);
			_napeSpace = spaceEntity.get(NapeSpace);
			
			_groundCollisionType = new CbType();
			_projectileCollisionType = new CbType();
			_projectileCollisionType2 = new CbType();
			zombieCollisionType = new CbType();
			
			_napeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, _groundCollisionType, _projectileCollisionType, handleLand));
			_napeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, _projectileCollisionType2, zombieCollisionType, handleHitZombie));
			
			_napeGroup.floor.cbTypes.add(_groundCollisionType);
			
			//_napeSpace.space.listeners.add(new PreListener(InteractionType.COLLISION, _groundCollisionType, _projectileCollisionType, projToGround, 0, true));
		}
		
		private function handleLand($collision:InteractionCallback):void{
			// remove projectile's cbyType
			var body:Body =  $collision.int2.castBody;
			//body.cbTypes.remove(_projectileCollisionType);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"whack_03.mp3");
			
			if(!_resettingCamera){
				//stopCamera(body.userData.entity as Entity);
				SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, resetCamera));
				_resettingCamera = true;
			}
		}
		
		private function handleHitZombie($collision:InteractionCallback):void{
			var zombieBody:Body = $collision.int2.castBody;
			var zombieEntity:Entity = zombieBody.userData.entity as Entity;
			
			var projectileBody:Body = $collision.int1.castBody;
			var projectileEntity:Entity = projectileBody.userData.entity as Entity;
			var projectile:Projectile = projectileEntity.get(Projectile);
			
			//trace(projectileEntity+":"+projectile+":"+Id(projectileEntity.get(Id)).id+":"+Id(_focusedProjectile.get(Id)).id);

			if(projectile){
				if(projectile.power > 0){
					AudioUtils.play(this, SoundManager.EFFECTS_PATH+"whack_01.mp3");
				} else {
					AudioUtils.play(this, SoundManager.EFFECTS_PATH+"whack_02.mp3");
				}
				Zombie(zombieEntity.get(Zombie)).health -= projectile.power;
				projectile.power = 0;
			}
			
			// destroy projectile
			if(projectileEntity.get(NapeMotion) != null){
				NapeMotion(projectileEntity.get(NapeMotion)).body.space = null;
			}
			
			// if not resetting camera and its the same projectile, reset the camera
			if(projectileEntity.get(Id) != null){
				if(!_resettingCamera && Id(projectileEntity.get(Id)).id == Id(_focusedProjectile.get(Id)).id){
					SceneUtil.addTimedEvent(this, new TimedEvent(1.5, 1, resetCamera));
					_resettingCamera = true;
				}
			}
				
			this.removeEntity(projectileEntity);
			
			if(Zombie(zombieEntity.get(Zombie)).health <= 0){
				if(!Zombie(zombieEntity.get(Zombie)).ko){
					Zombie(zombieEntity.get(Zombie)).ko = true;
					MotionUtils.zeroMotion(zombieEntity);
					zombieEntity.remove(MotionControl);
					CharUtils.setAnim(zombieEntity, Dizzy);
					num_zombies--;
				}
			}
		}
		
		private function youWin():void{
			AudioUtils.play(this, SoundManager.MUSIC_PATH+"important_item.mp3");
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Whew! You knocked out all Zombies! Time for the next round!", restart)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
		}
		
		public function youLose():void{
			
			AudioUtils.play(this, SoundManager.MUSIC_PATH+"danger.mp3", 1.7);
			
			var cameraEntity:Entity = this.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			camera.scaleTarget = 1.2;
			
			SceneUtil.setCameraTarget(this, player);
			
			CharUtils.setAnim(player, Dizzy);
			
			SkinUtils.setSkinPart(player, SkinUtils.EYES, "zombie", false);
			SkinUtils.setSkinPart(player, SkinUtils.SKIN_COLOR, 0x63679F, false);
			
			interaction.down.removeAll();
			interaction.up.removeAll();
			interaction.releaseOutside.removeAll();
			
			lost = true;
			
			SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, showYouLose));
		}
		
		private function showYouLose():void{
			var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "Zomg! You were overrun by zombies!", restart)) as ConfirmationDialogBox;
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
		}
		
		private function restart():void{
			shellApi.loadScene(ZomCatapult);
		}
		
		private function removeZombie():void{
			
		}
		
		private function projToGround($collision:PreCallback):PreFlag{
			var colArb:CollisionArbiter = $collision.arbiter.collisionArbiter;
			return PreFlag.IGNORE;
		}
		
		private function addRock():Entity
		{
			//var rockShape:Circle = new Circle(25);
			var rockShape:Polygon = new Polygon(Polygon.box(25, 25));
			
			rockShape.material = Material.steel();
			
			var ball:Body = new Body(BodyType.DYNAMIC);
			ball.shapes.add(rockShape);
			ball.angularVel = 1;
			
			var entity:Entity = _napeGroup.creator.createNapeObject(187, 1087, _napeSpace.space, ball, "ball");
			
			EntityUtils.loadAndSetToDisplay(super.hitContainer, "scenes/testIsland/zomCatapult/rock.swf", entity, this, setupNapeObject);
			
			return entity;
		}
		
		private function addSink():Entity
		{
			//var rockShape:Circle = new Circle(25);
			var rockShape:Polygon = new Polygon(Polygon.box(30, 20));
			
			
			rockShape.material = Material.steel();
			
			var ball:Body = new Body(BodyType.DYNAMIC);
			ball.shapes.add(rockShape);
			ball.angularVel = 1;
			
			var entity:Entity = _napeGroup.creator.createNapeObject(187, 1087, _napeSpace.space, ball, "ball");
			
			EntityUtils.loadAndSetToDisplay(super.hitContainer, "scenes/testIsland/zomCatapult/sink.swf", entity, this, setupNapeObject);
			
			return entity;
		}
		
		private function addTrash():Entity
		{
			//var rockShape:Circle = new Circle(25);
			var rockShape:Polygon = new Polygon(Polygon.regular(20,25,5));
			
			
			rockShape.material = Material.steel();
			
			var ball:Body = new Body(BodyType.DYNAMIC);
			ball.shapes.add(rockShape);
			ball.angularVel = 1;
			
			var entity:Entity = _napeGroup.creator.createNapeObject(187, 1087, _napeSpace.space, ball, "ball");
			
			EntityUtils.loadAndSetToDisplay(super.hitContainer, "scenes/testIsland/zomCatapult/trash.swf", entity, this, setupNapeObject);
			
			return entity;
		}
		
		private function addBall():Entity
		{
			var ballShape:Circle = new Circle(20);
			ballShape.material = Material.rubber();      // apply a material preset to make the ball bouncy.
			
			var ball:Body = new Body(BodyType.DYNAMIC);
			ball.shapes.add(ballShape);
			ball.angularVel = 1;
			
			var entity:Entity = _napeGroup.creator.createNapeObject(187, 1087, _napeSpace.space, ball, "ball");
			
			EntityUtils.loadAndSetToDisplay(super.hitContainer, "scenes/examples/standaloneMotion/ball2.swf", entity, this, setupNapeObject);
			
			return entity;
		}
		
		private function setupNapeObject(display:MovieClip, entity:Entity):void
		{
			if(_debug)
			{
				Display(entity.get(Display)).visible = false;
			}
			
			// move width/height setting here too
			_napeGroup.addEntity(entity);
			DisplayUtils.moveToOverUnder(Display(entity.get(Display)).displayObject, Display(_arm.get(Display)).displayObject, false);
		}
		
		//private var _projectile:Entity;
		
		private var _arm:Entity;
		private var _base:Entity;
		private var _catapultHit:Entity;
		private var _conveyor:Entity;
		private var _conveyorAni:Entity;
		
		public var zombieCreator:ZombieCreator;
		
		private var _power:Number = 0.0;
		
		public var _napeGroup:NapeGroup;
		private var _debug:Boolean = false;
		private var _napeSpace:NapeSpace;
		
		private var _groundCollisionType:CbType;
		private var _projectileCollisionType:CbType;
		private var _projectileCollisionType2:CbType;
		public var zombieCollisionType:CbType;
		
		private var _focusedProjectile:Entity;
		
		private var interaction:Interaction;
		
		private var _resettingCamera:Boolean;
		private var p:int = 1;
		
		public var num_zombies:int = 6;
		
		public var lost:Boolean;
		
	}
}