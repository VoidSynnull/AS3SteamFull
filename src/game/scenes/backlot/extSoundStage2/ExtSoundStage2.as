package game.scenes.backlot.extSoundStage2
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.timeline.Timeline;
	import game.scenes.backlot.BacklotEvents;
	import game.scene.template.PlatformerGameScene;
	import game.util.ColorUtil;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class ExtSoundStage2 extends PlatformerGameScene
	{
		public function ExtSoundStage2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/extSoundStage2/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var _events:BacklotEvents
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_events = events as BacklotEvents;
			
			this.setupSwingingObjects();
			this.setupLight();
		}
		
		private function setupSwingingObjects():void
		{
			this.addSystem(new SwingSystem(this.player));
			
			for(var i:int = 0; i <= 4; i++)
			{
				var clip:MovieClip = this._hitContainer["swing"]["b" + i];
				
				var swing:Entity = EntityUtils.createMovingEntity(this, clip);
				swing.add(new Swing());
			}
		}
		
		private function setupLight():void
		{
			var light:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["recordLight"], _hitContainer);
			TimelineUtils.convertClip(_hitContainer["recordLight"], this, light, null, false);
			var lightStatus:Timeline = light.get(Timeline);
			if(!super.shellApi.checkEvent(_events.COMPLETE_STAGE_2))
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