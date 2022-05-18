package game.scenes.con3.intro
{
	import flash.display.DisplayObjectContainer;
	
	import game.scene.template.CutScene;
	import game.scenes.con3.Con3Events;
	import game.scenes.con3.hq.Hq;

	public class Intro extends CutScene
	{		
		public function Intro()
		{
			super();
			configData("scenes/con3/intro/");
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.init( container );
		}
		
		override public function load():void
		{
			if(this.shellApi.checkEvent(Con3Events(events).PLAYED_INTRO_CUTSCENE))
			{
				this.shellApi.loadScene(Hq);
				return;
			}
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			start();
		}
		
		override public function end():void
		{
			this.shellApi.completeEvent(Con3Events(events).PLAYED_INTRO_CUTSCENE);
			shellApi.loadScene( Hq );
		}
	}
}