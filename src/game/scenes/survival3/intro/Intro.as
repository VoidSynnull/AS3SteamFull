package game.scenes.survival3.intro
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.systems.PositionalAudioSystem;
	
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Walk;
	import game.data.sound.SoundModifier;
	import game.scene.template.CutScene;
	import game.scenes.survival3.Survival3Events;
	import game.scenes.survival3.radioTower.RadioTower;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class Intro extends CutScene
	{		
		private const INTRO_MUSIC:String = "Survival_3_Intro_Cutscene.mp3";
		private const FOREST_AMBIANCE:String = "forest_ambiance_01_loop.mp3";
		private const WINTER_WINDS:String = "winter_wind_01_loop.mp3";
		private const WATER_SOUND:String = "water_flow_02_loop.mp3";
		private const BIRD_SOUNDS:String = "geese_ambiance_01.mp3";
		
		private var _volume:Number = 1;
		
		public function Intro()
		{
			super();
			configData("scenes/survival3/intro/", Survival3Events(super.events).PLAYED_INTRO);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			SceneUtil.removeIslandParts(this);
			super.init(container);
		}
		
		override public function load():void
		{
			if(shellApi.checkEvent(completeEvent))
			{
				shellApi.loadScene(RadioTower);
				return
			}
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			setUpWater();
			sceneAudio.play(SoundManager.AMBIENT_PATH + WINTER_WINDS, true, null, 1);
		}
		
		private function setUpWater():void
		{
			addSystem(new PositionalAudioSystem());
			var clip:MovieClip = new MovieClip();
			clip.x = 1075;
			clip.y = 750;
			var waterAudio:Entity = EntityUtils.createSpatialEntity(this, clip, screen);
			var range:AudioRange = new AudioRange(1000,0 ,1, Quad.easeIn);
			waterAudio.add(new Audio()).add(range);
			Audio(waterAudio.get(Audio)).play(SoundManager.EFFECTS_PATH + WATER_SOUND, true, SoundModifier.POSITION);
			TweenUtils.entityTo(waterAudio, Spatial, 7, {x:-75, y:300, ease:Linear.easeNone});
			audioGroup.addAudioToEntity(waterAudio, "waterFlow");
		}
		
		override public function setUpCharacters():void
		{
			setEntityContainer(player, screen.player.player);
			
			ColorUtil.colorize(EntityUtils.getDisplayObject(player),0x2E5D8A);
			
			CharUtils.setAnim(player, Walk);
			
			start();
		}
		
		override public function onLabelReached(label:String):void
		{
			if(label.indexOf("run") != -1)
			{
				CharUtils.setAnim(player, Walk);
			}
			if(label.indexOf("stand") != -1)
			{
				CharUtils.setAnim(player, Stand);
			}
			if(label.indexOf("lookUp") != -1)
			{
				//look up
				var head:Entity = CharUtils.getJoint(player, CharUtils.HEAD_JOINT);
				TweenUtils.entityTo(head, Spatial, 1, {rotation:20});
				//grab the hair as well
				var hair:Entity = CharUtils.getJoint(player, CharUtils.HAIR);
				if(hair != null)
					TweenUtils.entityTo(hair, Spatial, 1, {rotation:20});
				sceneAudio.setVolume(_volume += 5);
			}
			if(label.indexOf("geese") != -1)
			{
				sceneAudio.setVolume(_volume += 5);
				shellApi.triggerEvent(label);
			}
		}
		
		override public function end():void
		{
			super.end();
			shellApi.loadScene(RadioTower);
		}
	}
}