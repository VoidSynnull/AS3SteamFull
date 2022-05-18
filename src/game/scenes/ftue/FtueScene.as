package game.scenes.ftue
{
	import flash.utils.getQualifiedClassName;
	
	import engine.group.DisplayGroup;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.managers.interfaces.IIslandManager;
	import game.scene.template.PlatformerGameScene;
	import game.ui.hud.FTUEAdsHud;
	import game.ui.hud.Hud;
	import game.ui.tutorial.TutorialGroup;
	import game.util.CharUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	
	public class FtueScene extends PlatformerGameScene
	{
		public var ftue:FtueEvents;
		public var tutorial:TutorialGroup;
		public const CAMERA_PAN_SPEED:Number = .1;
		public const CAMERA_PLAYER_SPEED:Number = .2;
		public var version:int = 1;
		
		public function FtueScene()
		{
			super();
		}
				
		override public function load():void
		{
			ftue = events as FtueEvents;
			
			var islandManager:IIslandManager = shellApi.islandManager;
			if (PlatformUtils.inBrowser) {
				if (getQualifiedClassName(islandManager.hudGroupClass) != getQualifiedClassName(FTUEAdsHud)) {
					shellApi.islandManager.hudGroupClass = FTUEAdsHud;		// temporary change to boost ad impressions 3/2/16
				}
			}
			super.load();
		}
		
		override public function loaded():void
		{
			//player.remove(Sleep);
			shellApi.eventTriggered.add(onEventTriggered);
			
			tutorial = new TutorialGroup(overlayContainer);
			tutorial.complete.addOnce(tutorialFinished);
			this.addChildGroup(tutorial);
			// asset should be changed depending on mobile or not
			tutorial.createGesture(null);
			
			// possibly re enable later
			var hud:Hud = getGroupById( Hud.GROUP_ID ) as Hud;

			if (PlatformUtils.inBrowser) {
				hud.hideButton(Hud.HOME, false);		// temporary change to boost ad impressions 3/2/16
				hud.hideButton(Hud.MAP);		// when Hud.HOME is re-hidden, we need to un-hide this one
			}
			hud.hideButton(Hud.FRIENDS);
			hud.hideButton(Hud.STORE);
			hud.hideButton(Hud.REALMS);

			super.loaded();
		}
		
		/*private function gestureCreated(entity:Entity):void
		{
			var gest:Gesture = entity.get(Gesture);
			
			gest.up.spatialData.rotation = 5;
			gest.up.spatialData.x = 50;
			gest.up.spatialData.y = -25;
			
			gest.up.spatialData.positionSpatial(gest.animation.get(Spatial));
			
			gest.down.spatialData.rotation = -20;
			gest.down.spatialData.scaleY = .85;
			gest.down.spatialData.x = 0;
			gest.down.spatialData.y = 0;
			
			addSystem(new ShadowSystem());
			
			var shadow:Shadow = new Shadow();
			shadow.offSetX = -30;
			shadow.offSetY = 30;
			shadow.minAlpha = .1;
			shadow.maxAlpha = .9;
			shadow.scaleGrowth = .5;
			gest.animation.add(shadow);
			
			var ripple:Ripple = new Ripple();
			ripple.init(2, .66, 16,8, 2,0xFFFFFF,false);
			
			gest.ripple = EmitterCreator.create(this, EntityUtils.getDisplayObject(entity), ripple, 0,0, gest.animation, "ripple",null, false);
		}*/
		
		protected function tutorialFinished(group:DisplayGroup):void
		{
			// TODO Auto Generated method stub
			
		}
		
		public function onEventTriggered(event:String = null, makeCurrent:Boolean = false, init:Boolean = false, removeEvent:String = null):void
		{
			if(event.indexOf(ftue.NO_USE) >= 0)
			{
				if(!shellApi.checkEvent(ftue.FIX_BROKE_PLANE) && event == ftue.NO_USE+ftue.WRENCH)
					Dialog(player.get(Dialog)).sayById(ftue.NO_USE+ftue.WRENCH);
				else
					Dialog(player.get(Dialog)).sayById(ftue.NO_USE);
			}
		}
		
		public function returnControls(...args):void
		{
			CharUtils.lockControls(player, false, false);
			SceneUtil.setCameraTarget(this, player, false, CAMERA_PLAYER_SPEED);
			SceneUtil.lockInput(this, false);
			FSMControl(player.get(FSMControl)).active = true;
		}
		
		public const TUTORIAL_ALPHA:Number = .75;
	}
}