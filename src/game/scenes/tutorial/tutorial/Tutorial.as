package game.scenes.tutorial.tutorial
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Zone;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.WaterSplash;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.tutorial.tutorial.TutorialCommon;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	public class Tutorial extends TutorialCommon
	{
		public function Tutorial()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/tutorial/tutorial/";
			super.init(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			setupInstructions();
			setupWater();
			setupZones();
			setupDivingBoard();
			setupFish();
			setupAnimations();
			
			// force end tutorial so Amelia doesn't mention race when returning
			shellApi.completeEvent( "ftue_tutorial_completed", "hub" );
		}
		
		private function setupAnimations():void
		{
			for each (var anim:String in ["bird","chicken","dog1","dog2","hamster","fox","pelican","pig","warthog"])
			{
				setupAnimal(anim);
			}
		}
		
		override protected function runPath(char:Entity):void
		{
			var spatial:Spatial = char.get(Spatial);
			spatial.x = -100;
			spatial.y = 800;
			var path:Vector.<Point> = new Vector.<Point>();
			path.push(new Point(2350,660));
			path.push(new Point(3450,465));
			path.push(new Point(5630,647));
			path.push(new Point(5760,510));
			path.push(new Point(6080,688));
			path.push(new Point(6180,519));
			path.push(new Point(6450,519));
			CharUtils.followPath(char, path);
		}

		private function setupInstructions():void
		{
			var frame:int = ( PlatformUtils.isMobileOS ) ? 1 : 2;
			var clip:MovieClip;
			clip = _hitContainer["billboard_move"];
			clip.gotoAndStop(frame);
			clip.tf = TextUtils.refreshText( clip.tf, "Billy Bold");
			super.convertToBitmap( clip, 1 );
			clip = _hitContainer["billboard_talk"];
			clip.gotoAndStop(frame);
			clip.tf = TextUtils.refreshText( clip.tf, "Billy Bold");
			super.convertToBitmap( clip, 1 );
			clip = _hitContainer["billboard_jump"];
			clip.gotoAndStop(frame);
			clip.tf = TextUtils.refreshText( clip.tf, "Billy Bold");
			super.convertToBitmap( clip, 1 );
		}
		
		private function setupFish():void
		{
			var total:int = 2;
			var cluster:MovieClip;
			var parent:Entity;
			var display:Display;
			
			for(var n:int = 0; n < total; n++)
			{
				cluster = super.hitContainer["fishCluster" + (n + 1)];
				
				parent = new Entity();
				parent.add(new Spatial());
				display = new Display(cluster);
				display.isStatic = true;
				parent.add(display);
				parent.add(new Sleep());
				
				super.addEntity(parent);
				
				addFish(cluster.fish1, 0, 1, parent);
				addFish(cluster.fish2, 1, -1, parent);
			}
			
			super.addSystem(new FishSystem(), SystemPriorities.move);
		}
		
		private function addFish(clip:MovieClip, offset:Number, direction:Number, parent:Entity):void
		{
			var entity:Entity = new Entity();
			entity.add(new Fish(.03, offset, direction));
			entity.add(new Display(clip));
			entity.add(new Spatial());
			
			super.addEntity(entity);
			
			EntityUtils.addParentChild(entity, parent);
		}
		
		private function setupDivingBoard():void
		{
			var bounceHit:Entity = super.getEntityById("bounce");
			var board:Entity = new Entity();
			var clip:MovieClip = super.hitContainer["divingBoard"];
			super.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			board.add(new Spatial());
			board.add(new Display(clip));
			super.addEntity(board);
			TimelineUtils.convertClip(clip, this, board, null, false);
			bounceHit.add( new TriggerHit( board.get( Timeline )));
			super.addSystem(new TriggerHitSystem());
		}
		
		private function setupZones():void
		{	
			// TODO :: Probably want to refresh text in instructions?
			
			// only setup zone for jump tap nudges if on mobile
			if( PlatformUtils.isMobileOS )
			{
				var landZone:Zone = super.getEntityById("zoneLand").get(Zone);
				var shardZone:Zone = super.getEntityById("zoneShard").get(Zone);
				var tapZone:Zone = super.getEntityById("zoneTap").get(Zone);
				
				landZone.entered.add(handleZoneEntered);
				shardZone.entered.add(handleZoneEntered);
				tapZone.entered.add(handleZoneEntered);
			}
			else
			{
				super.removeEntity( super.getEntityById("zoneLand") );
				super.removeEntity( super.getEntityById("zoneShard") );
				super.removeEntity( super.getEntityById("zoneTap") );
			}
		}
		
		private function handleZoneEntered(zoneId:String, characterId:String):void
		{			
			switch(zoneId)
			{
				case "zoneTap" :
					_enteredTapZone = true;
					break;
				
				case "zoneShard" :
					_enteredTapZone = false;
					_reachedShardZone = true;
					break;
				
				case "zoneLand" :
					if(_enteredTapZone && !_reachedShardZone)
					{
						_enteredTapZone = false;
						var dialog:Dialog = super.shellApi.player.get(Dialog);
						dialog.say("Oh, it looks like I should tap where I want to jump.");
					}
					break;
			}
		}
		
		private function setupWater():void
		{
			_waterContainer = new Sprite();
			super._hitContainer.addChild(_waterContainer);
			
			var emitter:WaterLeak = new WaterLeak();
			var sleep:Sleep = new Sleep();
			_splash1 = EmitterCreator.create(this, _waterContainer, emitter );
			_splash1.get(Spatial).x = 4160;
			_splash1.get(Spatial).y = 120;
			_splash1.add(sleep);
			sleep.zone = new Rectangle(4160, 0, 100, 700);
			
			emitter.init();
			
			emitter = new WaterLeak();
			_splash2 = EmitterCreator.create(this, _waterContainer, emitter );
			_splash2.get(Spatial).x = 4490;
			_splash2.get(Spatial).y = 120;
			sleep = new Sleep();
			sleep.zone = new Rectangle(4490, 0, 100, 700);
			_splash2.add(sleep);
			emitter.init();
			
			SceneUtil.addTimedEvent(this, new TimedEvent(.4, 0, makeSplash));
			var waterAudio:Entity = EntityUtils.createSpatialEntity(this, new MovieClip(),_hitContainer);
			var audioRange:AudioRange = new AudioRange(1000,0,.75,Quad.easeIn);
			waterAudio.add(audioRange).add(new Audio());
			var waterPos:Spatial = waterAudio.get(Spatial);
			waterPos.x = 4300;
			waterPos.y = 700;
			Audio(waterAudio.get(Audio)).play("effects/water_fountain_01_loop.mp3",true,SoundModifier.POSITION);
		}
		
		private function makeSplash():void
		{
			var x:Number = 0;
			var y:Number = 684;
			
			if(!_splash1.sleeping && !_splashCycle)
			{
				x = 4160;
			}
			
			if(!_splash2.sleeping && _splashCycle)
			{
				x = 4490;
			}
			
			_splashCycle = !_splashCycle;
			
			if(x != 0)
			{
				var splash:WaterSplash = new WaterSplash();
				var splashEntity:Entity = EmitterCreator.create(this, _waterContainer, splash, x, y ); 
				splashEntity.add(new Sleep());
				splash.init(Utils.randNumInRange(.5, 1), 0x6BC3D9, 0xE1E8FF, 10);
				Emitter(splashEntity.get(Emitter)).remove = true;
				Emitter(splashEntity.get(Emitter)).removeOnSleep = true;
			}
		}
		
		override protected function getCoinOffset(coinNum:int):Point
		{
			var offsetX:Number = 200;
			var offsetY:Number = 30;
			if (coinNum == 1)
			{
				offsetX = 330;
				offsetY = -60;
			}
			return new Point(offsetX, offsetY);
		}
				
		private var _splash1:Entity;
		private var _splash2:Entity;
		private var _waterContainer:Sprite;
		private var _splashCycle:Boolean = false;
		private var _reachedShardZone:Boolean = false;
		private var _enteredTapZone:Boolean = false;
	}
}