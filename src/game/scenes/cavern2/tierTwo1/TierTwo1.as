package game.scenes.cavern2.tierTwo1
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.components.hit.Platform;
	import game.components.timeline.Timeline;
	import game.scenes.cavern2.shared.Cavern2Scene;
	import game.util.PlatformUtils;
	import game.util.TimelineUtils;
	
	public class TierTwo1 extends Cavern2Scene
	{
		private var skull:Timeline;
		public function TierTwo1()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/cavern2/tierTwo1/";
			
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
			super.loaded();
			var clip:MovieClip = _hitContainer["skullDoor"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			skull = TimelineUtils.convertClip(clip, this).get(Timeline);
			if(shellApi.checkEvent(cavern2.MOUTH_DROPPED))
			{
				skull.gotoAndStop("opened");
				removeEntity(getEntityById("magneticWall"));
			}
			else
			{
				getEntityById("floorOfMouth").remove(Platform);
			}
		}
		
		override protected function onEventTriggered(event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null):void
		{
			if(event == cavern2.MOUTH_DROPPED)
			{
				skull.play();
				removeEntity(getEntityById("magneticWall"));
				getEntityById("floorOfMouth").add(new Platform());
			}
			super.onEventTriggered(event, makeCurrent, init, removeEvent);
		}
	}
}