package game.scenes.testIsland.wheelOfFortune
{
	import flash.display.DisplayObjectContainer;
	import flash.text.TextField;
	
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ui.CardGroup;
	import game.scenes.hub.town.wheelPopup.WheelOfFortuneGroup;
	import game.scenes.hub.town.wheelPopup.WheelPopup;
	import game.util.SceneUtil;
	
	public class WheelOfFortune extends PlatformerGameScene
	{
		private var wheelOfFortuneGroup:WheelOfFortuneGroup;
		
		private var tf:TextField;
		public function WheelOfFortune()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/testIsland/wheelOfFortune/";
			
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
			shellApi.eventTriggered.add(onEventTriggered);
		}
		
		private function onEventTriggered(event:String,...args):void
		{
			if(event == "openWheelPopup")
			{
				addChildGroup(new WheelPopup(overlayContainer)).removed.addOnce(receivePrize);
			}
			if(event.indexOf("getCoins_") == 0)
			{
				SceneUtil.getCoins(this,int(event.substr(9))/5, player);
			}
		}
		
		private function receivePrize(wheelPopup:WheelPopup):void
		{
			trace(wheelPopup.prize.prize);
			if(wheelPopup.prize.unique)
			{
				shellApi.showItem(wheelPopup.prize.prize, CardGroup.STORE);
			}
			else
			{
				SceneUtil.getCoins(this,int(wheelPopup.prize.prize)/5, player);
			}
		}
	}
}