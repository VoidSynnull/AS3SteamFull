package game.scenes.survival3.shared
{	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.motion.MotionControl;
	import game.components.timeline.Timeline;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.survival3.Survival3Events;
	import game.scenes.survival3.shared.components.RadioSignal;
	import game.scenes.survival3.shared.components.SignalGui;
	import game.scenes.survival3.shared.systems.RadioSignalSystem;
	import game.scenes.survival3.shared.systems.SignalGuiSystem;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.TimelineUtils;

	public class Survival3Scene extends PlatformerGameScene
	{
		public function Survival3Scene()
		{
			super();
		}
		
		public var bitmapQuailty:Number;
	
		override public function loaded():void
		{
			bitmapQuailty = (PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_LOW) ? 1 : PerformanceUtils.qualityLevel/PerformanceUtils.QUALITY_MEDIUM * .5 + .5;
			_events = super.events as Survival3Events;
			
			super.loaded();
			
			addSystem(new RadioSignalSystem());
			signal = new RadioSignal(shellApi.camera.camera.area.bottom);
			player.add(signal);
			
			if(shellApi.checkEvent(_events.POWERED_RADIO))
				setUpRadio();
			else
			{
				if(shellApi.checkHasItem(_events.RADIO))
					shellApi.eventTriggered.add(onEventTriggered);
				Display(signalHud.get(Display)).visible = false;
			}
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == _events.POWERED_RADIO)
			{
				setUpRadio();
			}
		}
		
		public var signal:RadioSignal;
		public var signalHud:Entity;
		private function setUpRadio():void
		{
			addSystem(new SignalGuiSystem());
			Display(signalHud.get(Display)).visible = true;
			signalHud.add(new SignalGui(signal));
		}
		
		protected override function addUI(container:Sprite):void
		{
			super.addUI(container);
			
			shellApi.loadFile(shellApi.assetPrefix + SURVIVAL3_HUD, addSurvival3Hud);
		}
		
		private function addSurvival3Hud(hud:MovieClip):void
		{
			var hudEntity:Entity = EntityUtils.createSpatialEntity(this, hud, overlayContainer);
			Display(hudEntity.get(Display)).moveToBack();
			var clip:MovieClip = hud["radioHUD"];
			signalHud = EntityUtils.createSpatialEntity(this, clip, hud);
			var hudSpatial:Spatial = signalHud.get(Spatial);
			hudSpatial.x = 10 + hudSpatial.width / 2;
			hudSpatial.y = shellApi.camera.viewportHeight - 10;
			TimelineUtils.convertClip(clip, this, signalHud,null,false);
			var time:Timeline = signalHud.get(Timeline);
			time.gotoAndStop(time.data.duration - 1);
		}
		
		private var _events:Survival3Events;
		private static const SURVIVAL3_HUD:String = 'scenes/survival3/shared/hud.swf';
		
	}
}
