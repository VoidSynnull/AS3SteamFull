package game.scenes.arab1.cave
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.GravityWellCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.Hazard;
	import game.components.hit.ValidHit;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.scene.template.AudioGroup;
	import game.scenes.arab1.Arab1Events;
	import game.scenes.arab1.shared.Arab1Scene;
	import game.scenes.arab1.shared.components.QuickSand;
	import game.scenes.arab1.shared.components.SandScorpion;
	import game.scenes.arab1.shared.systems.QuickSandSystem;
	import game.scenes.arab1.shared.systems.SandScorpionSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.GravityWellSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.actions.ScaleAll;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class Cave extends Arab1Scene
	{		
		private var _events:Arab1Events;
		private var _sceneObjectCreator:SceneObjectCreator;
		private var _rope:Entity;
		
		private var ROPE_SOUND:String = SoundManager.EFFECTS_PATH + "bush_rustle_01.mp3";
		
		public function Cave()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab1/cave/";
			//showHits  = true;
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			setupQuickSand();
			setupScorpions();
			setupPushBoxes();
			setupTriggers();
			setupRopeDrop();
			
			setupDust();
			
			shellApi.eventTriggered.add(handleEvents);
			super.loaded();
		}
		
		private function setupRopeDrop():void
		{
			var inter:SceneInteraction = getEntityById("ropeInteraction").get(SceneInteraction);
			_rope = EntityUtils.createMovingTimelineEntity(this,_hitContainer["rope"],_hitContainer, false);
			var ropeHit:Entity = getEntityById("climb");
			Display(ropeHit.get(Display)).isStatic = false;
			if(!shellApi.checkEvent(_events.CAVE_ROPE_LOWERED)){
				EntityUtils.position(ropeHit, 530, -700);
				inter.reached.addOnce(ropeDown);
			}
			else{
				EntityUtils.position(ropeHit, 530, 570);
				Timeline(_rope.get(Timeline)).gotoAndStop("down");
			}
		}
		
		private function ropeDown(...p):void
		{
			Timeline(_rope.get(Timeline)).play();
			EntityUtils.position(getEntityById("climb"), 530, 570);
			AudioUtils.play(this, ROPE_SOUND, 1);
			shellApi.completeEvent(_events.CAVE_ROPE_LOWERED);
		}
		
		private function setupTriggers():void
		{
			var campZone:Zone = getEntityById("campZone").get(Zone);
			campZone.entered.addOnce(saySomething);
		}
		
		private function saySomething(...p):void
		{
			Dialog(player.get(Dialog)).sayById("campSite");
		}
		
		private function setupQuickSand():void
		{
			this.addSystem(new QuickSandSystem(), SystemPriorities.moveComplete);
			this.addSystem(new GravityWellSystem());
			player.add(new GravityWellCollider());

			var sandPlatform:Entity;
			//var sandGraphic:Entity;
			var sandCount:int = 3;
			for (var i:int = 0; i < sandCount; i++) 
			{
				DisplayUtils.moveToTop(_hitContainer["quickSand"+i]);
				DisplayUtils.moveToTop(_hitContainer["flow"+i]);
				TimelineUtils.convertAllClips(_hitContainer["flow"+i],null,this,true,25);
				sandPlatform = getEntityById("quickSandPlat"+i);
				var p:Point = EntityUtils.getPosition(sandPlatform);
				var quickSand:QuickSand = new QuickSand();
				quickSand.startingPoint = EntityUtils.getPosition(sandPlatform);
				sandPlatform.add(quickSand);
				sandPlatform.get(Display).visible = false;
			}
		}
		
		private function setupScorpions():void
		{
			this.addSystem(new SandScorpionSystem(), SystemPriorities.move);
			
			var count:int = 3;
			var scorp:Entity;
			var scorpComp:SandScorpion;
			for (var i:int = 0; _hitContainer["scorpion"+i] != null; i++) 
			{
				scorp = EntityUtils.createMovingEntity(this,_hitContainer["scorpion"+i],_hitContainer);
				scorp = TimelineUtils.convertClip(_hitContainer["scorpion"+i],this,scorp);
				scorp.add(new Id("scorpion"+i));
				scorp.add(new Sleep(false,true));
				scorpComp = new SandScorpion();
				scorpComp.delay = .8;
				var hazard:Entity = getEntityById("scorpHazard"+i);
				scorpComp.hazard = hazard.get(Hazard);
				Display(hazard.get(Display)).visible = false;
				hazard.add(new FollowTarget(scorp.get(Spatial),1));
				scorpComp.zone = getEntityById("scorpionZone"+i).get(Zone);
				scorp.add(scorpComp);
			}
		}
				
		private function setupPushBoxes():void
		{
			_sceneObjectCreator = new SceneObjectCreator();
			
			super.addSystem(new SceneObjectHitRectSystem());
			
			super.player.add(new SceneObjectCollider());
			super.player.add(new RectangularCollider());
			super.player.add( new Mass(100) );
			
			var box:Entity;
			var clip:MovieClip;
			var bounds:Rectangle;
			for (var i:int = 0; _hitContainer["box"+i] != null; i++) 
			{
				clip = _hitContainer["bounds"+i];
				bounds = new Rectangle(clip.x,clip.y,clip.width,clip.height);
				_hitContainer.removeChild(clip);
				clip = _hitContainer["box"+i] ;
				box = _sceneObjectCreator.createBox(clip,0,super.hitContainer,clip.x, clip.y,null,null,bounds,this,null,null,400);
				SceneObjectMotion(box.get(SceneObjectMotion)).rotateByPlatform = false;
				box.add(new Id("box"+i));
				box.add(new WallCollider());
				// box sounds
				var audioGroup:AudioGroup = AudioGroup(getGroupById(AudioGroup.GROUP_ID));
					audioGroup.addAudioToEntity(box, "box");
				new HitCreator().addHitSoundsToEntity(box,audioGroup.audioData,shellApi,"box");
			}
			var validHit:ValidHit = new ValidHit("boxWall");
			validHit.inverse = true;
			player.add(validHit);
		}
		
		private function handleEvents(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "gotItem_" + _events.SALT){
				Dialog(player.get(Dialog)).sayById("noHideOut");
			}
		}
		
		
		private function setupDust():void
		{
			var clip:DisplayObjectContainer = _hitContainer["doorSand"];
			var bounds:Rectangle = clip.getBounds(_hitContainer);
			var sandStorm:Emitter2D = new Emitter2D()
			sandStorm.counter = new Random(0.3,0.5);
			sandStorm.addInitializer( new ImageClass( Blob, [50], true ) );
			sandStorm.addInitializer( new ColorInit(0xF2BA6F, 0xDBA764) );
			sandStorm.addInitializer(new Velocity(new PointZone(new Point(50,0))));
			sandStorm.addInitializer(new Position(new LineZone(new Point(bounds.left, bounds.top+20), new Point(bounds.left, bounds.bottom-50))));
			sandStorm.addInitializer( new Lifetime( 3, 2) );
			sandStorm.addInitializer( new RotateVelocity(0.2,0.8) );
			sandStorm.addAction(new Move());
			sandStorm.addAction(new Accelerate(100, 0));
			sandStorm.addAction(new RandomDrift(0, 100));
			sandStorm.addAction(new Rotate());
			sandStorm.addAction( new Fade(0.15,0) );
			sandStorm.addAction( new Age() );
			sandStorm.addAction( new ScaleAll(1, 1.5) );
			var sandStormEmitter:Entity = EmitterCreator.create(this, _hitContainer, sandStorm);
		}
		
		
		
		
		
		
		
		
	};
};