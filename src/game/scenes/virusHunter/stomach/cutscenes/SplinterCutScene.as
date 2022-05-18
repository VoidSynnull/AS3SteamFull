package game.scenes.virusHunter.stomach.cutscenes
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	import game.util.TimelineUtils;
	
	public class SplinterCutScene extends Popup
	{
		private var joe:Entity;
		
		public function SplinterCutScene(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = 0.8;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/virusHunter/stomach/splinterCutScene/";
			super.init(container);
			super.autoOpen = false;
			
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["eating.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.screen = super.getAsset("eating.swf", true) as MovieClip;
			super.loaded();
			
			var scaleX:Number = this.shellApi.viewportWidth / 960;
			var scaleY:Number = this.shellApi.viewportHeight / 640;
			var max:Number = Math.max(scaleX, scaleY);
			
			this.screen.content.scaleX = max;
			this.screen.content.scaleY = max;
			
			//this.screen.content.y += 50;
			
			var entity:Entity;
			var timeline:Timeline;
			
			entity = TimelineUtils.convertClip(this.screen.content.char2, this);
			timeline = entity.get(Timeline);
			timeline.gotoAndPlay("start");
			
			entity = TimelineUtils.convertClip(this.screen.content, this);
			timeline = entity.get(Timeline);
			timeline.handleLabel("end", this.close);
			
			this.open();
		}
	}
}
