package game.scenes.backlot.extSoundStage3
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.motion.TargetSpatial;
	import game.components.timeline.Timeline;
	import game.components.motion.RadiusControl;
	import game.components.scene.SceneInteraction;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.Stand;
	import game.scenes.backlot.BacklotEvents;
	import game.scene.template.PlatformerGameScene;
	import game.systems.motion.RadiusToTargetSystem;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class ExtSoundStage3 extends PlatformerGameScene
	{
		public function ExtSoundStage3()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/extSoundStage3/";
			
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
			
			this.setupDinoEyes();
			this.setupCondiments();
			this.setupCactus();
			this.setupLight();
		}
		
		private function setupDinoEyes():void
		{
			this.addSystem(new RadiusToTargetSystem());
			
			for(var i:int = 1; i <= 2; i++)
			{
				var cover:MovieClip = _hitContainer["cover" + i];
				var clip:MovieClip = this._hitContainer["pupil" + i];
				var pupil:Entity = EntityUtils.createSpatialEntity(this, clip);
				
				Display(pupil.get(Display)).displayObject.mask = cover;
				
				pupil.add(new RadiusControl(10, clip.x, clip.y));
				pupil.add(new TargetSpatial(this.player.get(Spatial)));
			}
		}
		
		private function setupCondiments():void
		{
			var array:Array = ["ketchup", "mustard", "paper"];
			
			for(var i:int = 0; i < array.length; i++)
			{
				var entity:Entity = this.getEntityById(array[i] + "Interaction");
				
				var clip:MovieClip = this._hitContainer[array[i]];
				TimelineUtils.convertClip(clip, this, entity, null, false);
				
				var timeline:Timeline = entity.get(Timeline);
				
				var interaction:SceneInteraction = entity.get(SceneInteraction);
				interaction.approach = false;
				
				interaction.triggered.add(Command.create(
					function play(player:Entity, interaction:Entity, timeline:Timeline):void
					{
						if(!timeline.playing)
							timeline.gotoAndPlay("begin");
					}, timeline));
			}
		}
		
		private function setupCactus():void
		{
			var cactus:Entity = this.getEntityById("cactusInteraction");
			
			var clip:MovieClip = cactus.get(Display).displayObject;
			TimelineUtils.convertClip(clip, this, cactus, null, false);
			
			var timeline:Timeline = cactus.get(Timeline);
			timeline.handleLabel("duck", Command.create(
				function(player:Entity):void
				{
					CharUtils.setAnim(player, DuckDown);
				}, this.player), false);
			
			timeline.handleLabel("end", Command.create(
				function(player:Entity):void
				{
					CharUtils.setAnim(player, Stand);
					FSMControl(player.get(FSMControl)).active = true;
				}, this.player), false);
			
			var interaction:SceneInteraction = cactus.get(SceneInteraction);
			interaction.reached.add(Command.create(
				function(player:Entity, cactus:Entity, timeline:Timeline):void
				{
					if(!timeline.playing)
						timeline.gotoAndPlay("begin");
					
				}, timeline));
		}
		
		private function setupLight():void
		{
			var light:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["recordLight"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["recordLight"], this, light, null, false);
			var lightStatus:Timeline = light.get(Timeline);
			if(!super.shellApi.checkEvent(_events.COMPLETE_STAGE_3))
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