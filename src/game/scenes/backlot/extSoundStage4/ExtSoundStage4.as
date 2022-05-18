package game.scenes.backlot.extSoundStage4
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.components.motion.ShakeMotion;
	import game.components.scene.SceneInteraction;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.PointItem;
	import game.scenes.backlot.BacklotEvents;
	import game.scene.template.PlatformerGameScene;
	import game.systems.motion.ShakeMotionSystem;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class ExtSoundStage4 extends PlatformerGameScene
	{
		private var jack:Entity;
		private var bus:Entity;
		private var lift:Entity;
		
		public function ExtSoundStage4()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/extSoundStage4/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var _events:BacklotEvents;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_events = events as BacklotEvents;
			
			this.setupBus();
			this.setupLift();
			this.setupLight();
		}
		
		private function setupBus():void
		{
			//Bus
			this.addSystem(new ShakeMotionSystem());
			
			this.bus = EntityUtils.createSpatialEntity(this, this._hitContainer["bus"]);
			this.bus.add(new SpatialAddition());
			bus.add(new Audio());
			
			var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-1, -1, 1, 1));
			shake.active = false;
			this.bus.add(shake);
			this.bus.add(new Tween());
			
			//Jack
			this.jack = this.getEntityById("jackInteraction");
			jack.add(new Audio());
			
			TimelineUtils.convertClip(this._hitContainer["jackInteraction"], this, this.jack, null, false);
			
			var timeline:Timeline = this.jack.get(Timeline);
			
			var interaction:SceneInteraction = this.jack.get(SceneInteraction);
			interaction.offsetX = 20;
			interaction.reached.add(this.pushJack);
		}
		
		private function pushJack(player:Entity, jack:Entity):void
		{
			var timeline:Timeline = this.jack.get(Timeline);	
			if(timeline.currentIndex != -1 && timeline.currentIndex != 19) return;
			
			CharUtils.setAnim(this.player, PointItem);
			this.player.get(Timeline).handleLabel("pointing", this.moveBusUp);
		}
		
		private function moveBusUp():void
		{
			var timeline:Timeline = this.jack.get(Timeline);
			
			if(!timeline.playing)
			{
				timeline.gotoAndPlay(0);
				
				Audio(jack.get(Audio)).play("effects/steel_grate_01.mp3");
				
				this.bus.get(ShakeMotion).active = true;
				
				var tween:Tween = this.bus.get(Tween);
				var spatial:Spatial = this.bus.get(Spatial);
				tween.to(spatial, 0.5, {rotation:spatial.rotation - 3});
				
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, this.moveBusDown));
			}
		}
		
		private function moveBusDown():void
		{
			var tween:Tween = this.bus.get(Tween);
			var spatial:Spatial = this.bus.get(Spatial);
			tween.to(spatial, 0.5, {rotation:spatial.rotation + 3});
			
			var timeline:Timeline = this.jack.get(Timeline);
			timeline.playing = true;
			
			function stopShake(bus:Entity):void 
			{ 
				bus.get(ShakeMotion).active = false; 
				Audio(bus.get(Audio)).play("effects/ls_heavy_metal_verb_01.mp3");
			};
			timeline.handleLabel("end", Command.create(stopShake, this.bus));
		}
		
		private function setupLift():void
		{
			this.lift = TimelineUtils.convertClip(this._hitContainer["lift"], this, null, null, false);
			
			var handle:Entity = this.getEntityById("handleInteraction");
			handle.add(new Audio());
			
			var interaction:SceneInteraction = handle.get(SceneInteraction);
			interaction.reached.add(this.moveLift);
		}
		
		private function moveLift(player:Entity, handle:Entity):void
		{
			var timeline:Timeline = this.lift.get(Timeline);
			if(!timeline.playing)
			{
				timeline.playing = true;
				Audio(handle.get(Audio)).play("effects/medium_mechanical_movement_01.mp3");
			}
		}
		
		private function setupLight():void
		{
			var light:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["recordLight"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["recordLight"], this, light, null, false);
			var lightStatus:Timeline = light.get(Timeline);
			if(!super.shellApi.checkEvent(_events.COMPLETE_STAGE_4))
			{
				lightStatus.gotoAndPlay(0);
			}
			else
			{
				lightStatus.gotoAndStop(0);
				var lightClip:MovieClip = Display(light.get(Display)).displayObject as MovieClip;
				ColorUtil.colorize( lightClip.recordingLight, 0x00FF00 );
			}
		}
	}
}