package game.scenes.tutorial.tutorial2
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.display.BitmapWrapper;
	import game.data.scene.hit.MovingHitData;
	import game.data.sound.SoundModifier;
	import game.scenes.tutorial.tutorial.TutorialCommon;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ColorsInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	
	public class Tutorial2 extends TutorialCommon
	{
		public function Tutorial2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/tutorial/tutorial2/";
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			setupConveyor();
			setupWindmill();
			setupPlaneSmoke();
			setupAnimations();
			
			// setup door
			var door:Entity = super.getEntityById("exitRight");		
			// if guest then hide door and hotspot
			if (shellApi.profileManager.active.isGuest)
			{
				door.get(Display).visible = false;
				ToolTipCreator.removeFromEntity(door);
				_hitContainer["exit_sign"].visible = false;
				
			}
			else
			{
				var doorInt:SceneInteraction = door.get(SceneInteraction);
				doorInt.reached.add(doorReached);
			}
		}
		
		private function doorReached(player:Entity, door:Entity):void
		{
			shellApi.track("ExitTutorial", _shardManager.getShardCount());
		}
		
		private function setupAnimations():void
		{
			for each (var anim:String in ["alligator","antelope","armadillo","giraffe","parrot","seagull","zebra"])
			{
				setupAnimal(anim);
			}
		}
		
		override protected function runPath(char:Entity):void
		{
			var spatial:Spatial = char.get(Spatial);
			spatial.x = -100;
			spatial.y = 480;
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(new Point(2310,962));
			path.push(new Point(3120, 960));
			CharUtils.followPath(char, path, runPath2);
		}
		
		private function runPath2(char:Entity):void
		{
			var spatial:Spatial = char.get(Spatial);
			spatial.x = 3450;
			spatial.y = 820;
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(new Point(4320,948));
			CharUtils.followPath(char, path, hideNPC);
		}

		private function hideNPC(char:Entity):void
		{
			var spatial:Spatial = char.get(Spatial);
			spatial.x = 4800;
			spatial.y = 617;
		}

		/////////////////////////////////////////////////////////////////
				
		private function setupPlaneSmoke():void
		{
			var emitter2D:Emitter2D = new Emitter2D();
			
			emitter2D.counter = new Random(4, 8);
			emitter2D.addInitializer(new ImageClass(Blob, [20]));
			emitter2D.addInitializer(new ScaleImageInit(0.7, 1.5));
			emitter2D.addInitializer(new Position(new LineZone(new Point(-20, 0), new Point(20, 0))));
			emitter2D.addInitializer(new Velocity(new LineZone(new Point(0, -60), new Point(0, -80))));
			emitter2D.addInitializer(new Lifetime(2, 4));
			emitter2D.addInitializer(new ColorsInit([0x444444, 0x555555, 0x666666, 0x777777]));
			
			emitter2D.addAction(new Age());
			emitter2D.addAction(new Move());
			emitter2D.addAction(new RandomDrift(250, 50));
			emitter2D.addAction(new ScaleImage(0.5, 1.5));
			emitter2D.addAction(new Fade());
			emitter2D.addAction(new Accelerate(-80, -60));
			
			var entity:Entity = EmitterCreator.create(this, this._hitContainer, emitter2D, 0, 0, null, "planeSmoke");
			var spatial:Spatial = entity.get(Spatial);
			spatial.x = 1734;
			spatial.y = 836;
			
			var display:DisplayObject = entity.get(Display).displayObject;
			display.parent.setChildIndex(display, 0);
			
			entity.add(new Sleep());
			
			this.convertToBitmap(this._hitContainer["planeSheet"]);
		}
		
		private function setupWindmill():void
		{
			var background:Entity = super.getEntityById("animations");
			var display:Display = background.get(Display);
			var clip:MovieClip = display.displayObject["windmillBlades"];
			var windmill:Entity = new Entity();
			var motion:Motion = new Motion();
			motion.rotationVelocity = 40;
			
			var wrapper:BitmapWrapper = super.convertToBitmapSprite(clip);
			super.convertToBitmapSprite(display.displayObject["windmillBase"]);
			
			windmill.add(motion);
			windmill.add(new Spatial());
			windmill.add(new Sleep());
			windmill.add(new Display(wrapper.sprite));
			clip.mouseEnabled = false;
			clip.mouseChildren = false;
			super.addEntity(windmill);
		}
		
		private function setupConveyor():void
		{
			MovieClip(super._hitContainer).conveyorArt.mouseChildren = true;
			MovieClip(super._hitContainer).conveyorArt.mouseEnabled = false
			MovieClip(super._hitContainer).conveyorArt.conveyorButton.mouseEnabled = true;
			ButtonCreator.createButtonEntity( MovieClip(super._hitContainer).conveyorArt.conveyorButton, this, handleConveyorClicked );
			MovieClip(super._hitContainer).conveyorArt.conveyorButton.mouseChildren = false;
			MovieClip(super._hitContainer).conveyorArt.conveyorButton.buttonStates.gotoAndStop(1);
			
			var conveyor:Entity = getEntityById("conveyor");
			TimelineUtils.convertClip(MovieClip(super._hitContainer).conveyorArt.prop1.blade, this, null, conveyor);
			TimelineUtils.convertClip(MovieClip(super._hitContainer).conveyorArt.prop2.blade, this, null, conveyor);
			
			var audioRange:AudioRange = new AudioRange(1200,0,1,Quad.easeIn);
			conveyor.add(audioRange).add(new Audio());
			Audio(getEntityById("conveyor").get(Audio)).play("effects/Plane_H_loop_01_loop.mp3",true,SoundModifier.POSITION,.65);
		}
		
		private function handleConveyorClicked(entity:Entity):void
		{
			MovieClip(super._hitContainer).conveyorArt.conveyorButton.buttonStates.gotoAndStop(2);
			var conveyor:Entity = super.getEntityById("conveyor");
			var movingHitData:MovingHitData = conveyor.get(MovingHitData);
			
			AudioUtils.play(this,"effects/ping_05.mp3");
			
			if(movingHitData.pause)
			{
				movingHitData.pause = false;
			}
			Audio(conveyor.get(Audio)).stop("effects/Plane_H_loop_01_loop.mp3","effects");
			Audio(conveyor.get(Audio)).play("effects/Plane_L_loop_01_loop.mp3",true,SoundModifier.POSITION);
		}
		
		override protected function getCoinOffset(coinNum:int):Point
		{
			var offsetY:Number = -70;
			var offsetX:Number = 200;
			if (coinNum == 6)
			{
				offsetY = 30;
			}
			else if (coinNum == 8)
			{
				offsetY = 30;
				offsetX = 240;
			}
			return new Point(offsetX, offsetY);
		}
	}
}