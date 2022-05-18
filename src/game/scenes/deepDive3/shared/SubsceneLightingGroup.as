package game.scenes.deepDive3.shared
{
	import com.greensock.plugins.HexColorsPlugin;
	import com.greensock.plugins.TweenPlugin;
	
	import ash.core.Entity;
	
	import engine.components.Tween;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.render.Light;
	import game.components.render.LightOverlay;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive3.DeepDive3Events;
	import game.util.AudioUtils;
	
	TweenPlugin.activate([HexColorsPlugin]);
	
	public class SubsceneLightingGroup extends Group
	{
		
		public function SubsceneLightingGroup(scene:SubScene)
		{
			_scene = scene;
			this.id = GROUP_ID;
		}
		
		override public function added():void{
			
			// init default lighting of scene per stage
			if(super.shellApi.checkEvent(_events3.STAGE_2_ACTIVE)){
				lightOverlayEntity = _scene.addLight(super.shellApi.player, 400, .2, true, false, 0x000033, 0x000033);
			} else if(super.shellApi.checkEvent(_events3.STAGE_1_ACTIVE)){
				lightOverlayEntity = _scene.addLight(super.shellApi.player, 400, .7, true, false, 0x4A0066, 0x4A0066);
			} else {
				lightOverlayEntity = _scene.addLight(super.shellApi.player, 400, .9, true, false, 0x000033, 0x000033);
			}
			
			lightOverlay = lightOverlayEntity.get(LightOverlay);
			playerLight = super.shellApi.player.get(Light);
			
			_defaultColor = lightOverlay.color;
			_defaultDarkAlpha = playerLight.darkAlpha;
			_defaultLightAlpha = playerLight.lightAlpha;
		}
		
		public function tweenLightColor($color:uint = 0x0000FF, $duration:Number = 1, $yoyo:Boolean = false, $completeHandler:Function = null, $loop:Boolean = false):void{
			if(!lightOverlayEntity.get(Tween)){
				lightOverlayEntity.add(new Tween());
			}
			
			var tween:Tween = lightOverlayEntity.get(Tween);
			
			var myColor:Object = {hex:lightOverlay.color};
			if(!$loop){
				tween.to(myColor, $duration, {hexColors:{hex:$color}, onUpdate:applyColor, yoyo:$yoyo, onComplete:$completeHandler});
			} else {
				tween.to(myColor, $duration, {hexColors:{hex:$color}, onUpdate:applyColor, yoyo:$yoyo, repeat:-1, onComplete:$completeHandler});
			}
			function applyColor():void {
				lightOverlay.color = myColor.hex;
				playerLight.color = myColor.hex;
				playerLight.color2 = myColor.hex;
			}
		}
		
		public function tweenLightAlpha($darkAlpha:Number, $lightAlpha:Number = 0, $duration:Number = 1, $yoyo:Boolean = false, $completeHandler:Function = null, $loop:Boolean = false):void{
			if(!lightOverlayEntity.get(Tween)){
				lightOverlayEntity.add(new Tween());
			}
			
			var tween:Tween = lightOverlayEntity.get(Tween);
			
			if(!$loop){
				tween.to(lightOverlay, $duration, {darkAlpha:$darkAlpha, yoyo:$yoyo});
				tween.to(playerLight, $duration, {darkAlpha:$darkAlpha, lightAlpha:$lightAlpha, yoyo:$yoyo, onComplete:$completeHandler});
			} else {
				tween.to(lightOverlay, $duration, {darkAlpha:$darkAlpha, yoyo:$yoyo, repeat:-1});
				tween.to(playerLight, $duration, {darkAlpha:$darkAlpha, lightAlpha:$lightAlpha, yoyo:$yoyo, repeat:-1, onComplete:$completeHandler});
			}
		}
		
		public function updateToStage1($completeHandler:Function = null):void{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "power_on_07.mp3", 0.7);
			tweenLightColor(0x4A0066, 2, false, $completeHandler);
			tweenLightAlpha(.7);
		}
		
		public function updateToStage2($completeHandler:Function = null):void{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "power_on_07.mp3", 0.7);
			tweenLightColor(0x000033, 2, false, $completeHandler);
			tweenLightAlpha(.2);
		}
		
		public function flickerLights($completeHandler:Function = null):void{
			if(!lightOverlayEntity.get(Tween)){
				lightOverlayEntity.add(new Tween());
			}
			
			var tween:Tween = lightOverlayEntity.get(Tween);
			tween.to(lightOverlay, 0.3, {darkAlpha:0.4, yoyo:true, repeat:1});
			tween.to(playerLight, 0.3, {darkAlpha:0.4, lightAlpha:0.4, yoyo:true, repeat:1, onComplete:$completeHandler});
		}
		
		public function activateMemoryModule():void{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "power_on_08.mp3");
			tweenLightColor(0x48E88F, 0.5, false, restoreDefaultLighting);
			tweenLightAlpha(.5);
		}
		
		public function activateMemory():void{
			tweenLightColor(0xAF6D8B, 2, false);
			tweenLightAlpha(.7, 0, 2);
		}
		
		public function restoreDefaultLighting():void{
			tweenLightColor(_defaultColor, 1);
			tweenLightAlpha(_defaultDarkAlpha);
		}
		
		public function alarmFlash():void{
			tweenLightColor(0x4A0066, 1, true, null, true);
			tweenLightAlpha(.8, 0.4, 1, true, null, true);
		}
		
		public static function startLights( lightOverlayEntity:Entity ):void 
		{
			var tween:Tween = lightOverlayEntity.get( Tween );
			var lightOverlay:LightOverlay = lightOverlayEntity.get( LightOverlay );
			if(!tween)
			{
				tween = new Tween();
				lightOverlayEntity.add( tween );
			}
			
			tween.to( lightOverlay, 1, { darkAlpha:0.8, yoyo:true, repeat:-1 });
			
			var myColor:Object = { hex:lightOverlay.color };
			tween.to(myColor, 1, { hexColors:{ hex:0x4A0066 }, onUpdate:applyColor, yoyo:true, repeat:-1 });
			
			function applyColor():void 
			{
				lightOverlay.color = myColor.hex;
			}
			
		}
		
		public var lightOverlayEntity:Entity;
		public var playerLight:Light;
		public var lightOverlay:LightOverlay;
		
		private var _events3:DeepDive3Events;
		private var _scene:SubScene;
		
		private var _defaultColor:uint;
		private var _defaultDarkAlpha:Number;
		private var _defaultLightAlpha:Number;
		
		public static const GROUP_ID:String = "subsceneLightingGroup";
	}
}