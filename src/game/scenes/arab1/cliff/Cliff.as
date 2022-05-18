package game.scenes.arab1.cliff
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.Hazard;
	import game.components.hit.ValidHit;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.scene.template.AudioGroup;
	import game.scenes.arab1.desert.particles.SandStorm;
	import game.scenes.arab1.shared.Arab1Scene;
	import game.scenes.arab1.shared.components.QuickSand;
	import game.scenes.arab1.shared.components.SandScorpion;
	import game.scenes.arab1.shared.systems.QuickSandSystem;
	import game.scenes.arab1.shared.systems.SandScorpionSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class Cliff extends Arab1Scene
	{
		private var _sceneObjectCreator:SceneObjectCreator;
		
		public function Cliff()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab1/cliff/";
			//showHits = true
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
			setupPushBoxes();
			setupScorpions();
			setupLizard();
			
			var _sandStorm:SandStorm = new SandStorm();
			var _sandStormEmitter:Entity = EmitterCreator.create(this, overlayContainer, _sandStorm);
			_sandStorm.init(this, overlayContainer.width+600, 0, 1400, overlayContainer.height);
			_sandStorm.stream();
			
			EntityUtils.getDisplay(getEntityById("bones")).visible = false;
			
			shellApi.eventTriggered.add(handleEvents);
			
			var validHit:ValidHit = new ValidHit("camelWall");
			validHit.inverse = true;
			player.add(validHit);
			
			super.loaded();
		}
				
		private function handleEvents(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			
		}
		
		private function setupLizard():void
		{
			var lizard:Entity = TimelineUtils.convertClip(_hitContainer["lizard"],this,null,null,true,20);
		}
				
		private function setupQuickSand():void
		{
			this.addSystem(new QuickSandSystem(), SystemPriorities.moveComplete);
			
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
		}
		
		private function setupScorpions():void
		{
			this.addSystem(new SandScorpionSystem(), SystemPriorities.move);
			
			var count:int = 2;
			var scorp:Entity;
			var scorpComp:SandScorpion;
			for (var i:int = 0; _hitContainer["scorpion"+i] != null; i++) 
			{
				scorp = EntityUtils.createMovingEntity(this,_hitContainer["scorpion"+i],_hitContainer);
				scorp = TimelineUtils.convertClip(_hitContainer["scorpion"+i],this,scorp);
				scorp.add(new Id("scorpion"+i));
				scorp.add(new Sleep(false,true));
				scorpComp = new SandScorpion();
				scorpComp.delay = .9;
				var hazard:Entity = getEntityById("scorpHazard"+i);
				scorpComp.hazard = hazard.get(Hazard);
				Display(hazard.get(Display)).visible = false;
				hazard.add(new FollowTarget(scorp.get(Spatial),1));
				scorpComp.zone = getEntityById("scorpionZone"+i).get(Zone);
				scorp.add(scorpComp);
			}
		}	

		
		
		
		
		
		
		
		
		
		
		
	}
}