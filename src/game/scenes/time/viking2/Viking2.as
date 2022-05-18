package game.scenes.time.viking2{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Tween;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.part.SkinPart;
	import game.components.hit.Zone;
	import game.components.render.Light;
	import game.components.render.LightOverlay;
	import game.creators.render.LightCreator;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.time.TimeEvents;
	import game.scenes.time.shared.TimeDeviceButton;
	import game.scenes.time.viking.Viking;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	
	public class Viking2 extends PlatformerGameScene
	{
		public function Viking2()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/time/viking2/";
			//super.showHits = true;
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
			tEvents = super.events as TimeEvents;
			super.shellApi.eventTriggered.add(handleEventTriggered);
			setupTorchLight();
			setupEndingZones();
			placeTimeDeviceButton();
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "resetTorch")
			{
				// restore torch light
				Tween(player.get(Tween)).pauseAllTweens(true);
				LightOverlay(torchLightBlackness.get(LightOverlay)).darkAlpha = 0.3;
				Light(player.get(Light)).lightAlpha = 0;
			}
			if(event == "killedTorch")
			{
				// restart
				super.shellApi.loadScene(Viking,2431,725);
				CharUtils.lockControls(player, false, false);
			}
		}
		
		private function setupTorchLight():void
		{
			var light:LightCreator = new LightCreator();
			var sprite:Sprite = new Sprite();
			sprite.mouseEnabled = false;
			sprite.x -= shellApi.viewportWidth / 2;
			sprite.y -= shellApi.viewportHeight / 2;
			uiLayer.parent.addChildAt(sprite, uiLayer.parent.getChildIndex(this.uiLayer));
			torchLightBlackness = light.setupLight(this, sprite, 0.3);
			light.addSimpleLight(this.shellApi.player, 200);
			
			Light(player.get(Light)).matchOverlayDarkAlpha = true;
			
			// bring to front of scene
			_hitContainer.setChildIndex(_hitContainer["torch"], _hitContainer.numChildren-1);
			
			// equip torch
			SkinUtils.setSkinPart(player,CharUtils.ITEM,"torch",false,startDarkening);
			torch = SkinUtils.getSkinPartEntity(player,CharUtils.ITEM);
		}
		
		private function startDarkening(part:SkinPart):void
		{
			var tween:Tween = player.get(Tween);
			if(!tween)
			{
				tween = new Tween();
				player.add(tween);
			}
			var light:Entity = getEntityById("lightOverlay");
			tween.to(light.get(LightOverlay), caveTimelimit, {darkAlpha:1.0, onComplete:outOfTime});
			tween.to(player.get(Light),caveTimelimit/2,{delay:caveTimelimit/2, lightAlpha:1});
			if(torch){
				// strink that torch flame to go with the encroaching darkenss
				var flame:MovieClip = MovieClip(torch.get(Display).displayObject)["active_obj"]["flame"];
				flame.scaleX = flame.scaleY = 1.5;
				tween.to(flame,caveTimelimit*1.2,{scaleX:0, scaleY:0, ease:Quad.easeIn});
			}
		}
		
		private function outOfTime():void
		{	
			shellApi.triggerEvent("torch_burnout");
			Dialog(player.get(Dialog)).sayById("burnout");
			CharUtils.lockControls(player, true, true);
		}
		
		private function fellInWater(zoneId:String, characterId:String ):void
		{	
			shellApi.triggerEvent("torch_wet");
			Dialog(player.get(Dialog)).sayById("wetTorch");		
			
			Tween(player.get(Tween)).pauseAllTweens(true);
			Light(player.get(Light)).lightAlpha = 1;
			Light(player.get(Light)).darkAlpha = 1;
			LightOverlay(torchLightBlackness.get(LightOverlay)).darkAlpha = 1;
			
			var torchResetZone:Zone = getEntityById("zone2").get(Zone);
			torchResetZone.entered.remove(stopDarkening);
			CharUtils.lockControls(player, true, true);
		}
		
		private function stopDarkening(zoneId:String, characterId:String ):void
		{
			shellApi.triggerEvent("resetTorch");
		}
		
		private function setupEndingZones():void
		{	
			var torchResetZone:Zone = getEntityById("zone2").get(Zone);
			torchResetZone.entered.add(stopDarkening);
			var torchDrownZone:Zone = getEntityById("zone1").get(Zone);
			torchDrownZone.entered.addOnce(fellInWater);
		}
		
		private function placeTimeDeviceButton():void
		{
			if(shellApi.checkHasItem(TimeEvents(events).TIME_DEVICE))
			{
				timeButton = new Entity();
				timeButton.add(new TimeDeviceButton())
				TimeDeviceButton(timeButton.get(TimeDeviceButton)).placeButton(timeButton,this);
			}
		}
		private var timeButton:Entity;
				
		private var torchLightBlackness:Entity;
		private var caveTimelimit:Number = 28;
		private var tEvents:TimeEvents;
		private var torch:Entity;
	}
	
}