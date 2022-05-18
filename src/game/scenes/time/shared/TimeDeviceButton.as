package game.scenes.time.shared
{
	import flash.display.MovieClip;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.scene.template.PlatformerGameScene;
	import game.util.SceneUtil;
	
	public class TimeDeviceButton extends Component
	{
		public var scene:PlatformerGameScene;
		public var buttonTimeline:Timeline;
		private var owner:Entity;
		
		public function TimeDeviceButton()
		{
			super();
		}
		// place ui button to launch time device popup if player has the item
		public function placeButton( timeButton:Entity, scene:PlatformerGameScene ):void
		{
			//load button
			this.scene = scene;
			this.scene.shellApi.loadFile(scene.shellApi.assetPrefix + "scenes/" + scene.shellApi.island + "/shared/timeDeviceButton.swf", 
				Command.create( onDeviceLoaded, scene, timeButton));
		}
		
		private function onDeviceLoaded(clip:MovieClip, scene:PlatformerGameScene, timeButton:Entity):void
		{
			clip.x = 51;
			clip.y = scene.shellApi.viewportHeight-42;
			owner = timeButton = ButtonCreator.createButtonEntity(clip,scene, timeClickHandler,scene.overlayContainer,[InteractionCreator.CLICK,InteractionCreator.OVER,InteractionCreator.OUT],null,true,true);		
			Display(timeButton.get(Display)).container.setChildIndex(Display(timeButton.get(Display)).displayObject, 0);
			buttonTimeline = Timeline(timeButton.get(Timeline));
			buttonTimeline.gotoAndStop("up");
		}
		
		// manually flash completion lights
		public function flashButton(...p):void{
			buttonTimeline.gotoAndPlay("start");
		}
		
		private function timeClickHandler(timeButton:Entity):void
		{
			Timeline(timeButton.get(Timeline)).gotoAndStop("up");
			var popup:TimeDeviceView = scene.addChildGroup(new TimeDeviceView(scene.overlayContainer)) as TimeDeviceView;
			popup.id = "timeDevice";
			var interaction:Interaction = timeButton.get(Interaction);
			interaction.lock = true;
			popup.removed.addOnce(function(...args):void{interaction.lock = false;});
		}
	}
}