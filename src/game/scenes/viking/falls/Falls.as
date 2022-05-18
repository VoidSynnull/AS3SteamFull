package game.scenes.viking.falls
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.FollowClipInTimeline;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.sound.SoundModifier;
	import game.scene.template.CutScene;
	import game.scenes.viking.beach.Beach;
	import game.systems.entity.FollowClipInTimelineSystem;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Falls extends CutScene
	{
		public function Falls()
		{
			super();
			configData("scenes/viking/falls/", null);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			this.addSystem(new FollowClipInTimelineSystem());
			
			this.setupLogParticles();
			this.setupRiverParticles();
			
			var timeline:Timeline = this._sceneEntity.get(Timeline);
			timeline.handleLabel("jump", this.onSplash);
		}
		
		private function setupRiverParticles():void
		{
			var emitter:Emitter2D = new Emitter2D();
			emitter.counter = new Steady(50);
			emitter.addInitializer(new ImageClass(Dot, [2], true, 50));
			emitter.addInitializer(new Position(new RectangleZone(0, 0, 80, 0)));
			emitter.addInitializer(new Velocity(new RectangleZone(-10, -100, 50, -100)));
			emitter.addInitializer(new Lifetime(1));
			emitter.addInitializer(new ScaleImageInit(0.5, 1));
			emitter.addInitializer(new RotateVelocity(-20, 20));
			emitter.addAction(new ColorChange(0xFF22A0D2, 0xFFFFFFFF));
			emitter.addAction(new Rotate());
			emitter.addAction(new RandomDrift(100, 20));
			emitter.addAction(new Move());
			emitter.addAction(new Age());
			emitter.addAction(new Accelerate(0, 260));
			
			var entity:Entity = EmitterCreator.create(this, this.screen.cliff2, emitter);
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = 0;
			spatial.y = -287;
		}
		
		private function setupLogParticles():void
		{
			var emitter:Emitter2D = new Emitter2D();
			emitter.counter = new Steady(100);
			emitter.addInitializer(new ImageClass(Dot, [2], true, 50));
			emitter.addInitializer(new Position(new RectangleZone(-10, -10, 10, 10)));
			emitter.addInitializer(new Velocity(new RectangleZone(-100, -150, -100, -100)));
			emitter.addInitializer(new Lifetime(0.5));
			emitter.addInitializer(new ScaleImageInit(0.5, 1));
			emitter.addInitializer(new RotateVelocity(-20, 20));
			emitter.addAction(new ColorChange(0xFF22A0D2, 0xFFFFFFFF));
			emitter.addAction(new Rotate());
			emitter.addAction(new RandomDrift(100, 20));
			emitter.addAction(new Move());
			emitter.addAction(new Age());
			emitter.addAction(new Accelerate(0, 360));
			
			var entity:Entity = EmitterCreator.create(this, this.screen, emitter);
			DisplayUtils.moveToOverUnder(Display(entity.get(Display)).displayObject, this.screen.log, true);
			entity.add(new FollowClipInTimeline(this.screen.log, new Point(-60, 20), null, true));
		}
		
		private function onSplash():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "kids_screaming_01.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			var emitter:Emitter2D = new Emitter2D();
			emitter.counter = new Blast(100);
			emitter.addInitializer(new ImageClass(Dot, [4]));
			emitter.addInitializer(new Position(new RectangleZone(-50, -10, 50, 50)));
			emitter.addInitializer(new Velocity(new RectangleZone(100, 0, 400, 100)));
			emitter.addInitializer(new Lifetime(1));
			emitter.addInitializer(new ScaleImageInit(0.5, 1));
			emitter.addAction(new ColorChange(0xFF22A0D2, 0xFFFFFFFF));
			emitter.addAction(new RandomDrift(100, 100));
			emitter.addAction(new Move());
			emitter.addAction(new Age());
			emitter.addAction(new Accelerate(0, 1000));
			
			var entity:Entity = EmitterCreator.create(this, this.screen.cliff2, emitter);
			DisplayUtils.moveToBack(Display(entity.get(Display)).displayObject);
			
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = 145;
			spatial.y = -392;
		}
		
		override public function end():void
		{
			super.end();
			
			this.shellApi.loadScene(Beach);
		}
	}
}