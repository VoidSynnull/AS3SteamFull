package game.scenes.backlot.digitalDreamScapes
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Angry;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Stomp;
	import game.data.animation.entity.character.Wave;
	import game.scenes.backlot.BacklotEvents;
	import game.scene.template.PlatformerGameScene;
	import game.util.ArrayUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class DigitalDreamScapes extends PlatformerGameScene
	{
		private var isAnimating:Boolean = false;
		private var animations:Array = [Proud, Angry, Laugh, Stomp, Grief, Cry, Salute, Wave];
		
		private var larry:Entity;
		private var creature:Entity;
		
		public function DigitalDreamScapes()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/digitalDreamScapes/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var backlot:BacklotEvents;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			backlot = events as BacklotEvents;
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			this.setupChickens();
			this.setupTVCamera();
			this.setupAnimations();
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == backlot.WHITE_HAT)
			{
				SceneUtil.lockInput(this);
				CharUtils.moveToTarget(player, larry.get(Spatial).x, larry.get(Spatial).y, false, giveLarryHat);
			}
			if(event == backlot.FOUND_HERO)
			{
				CharUtils.moveToTarget(larry, getEntityById("door1").get(Spatial).x, getEntityById("door1").get(Spatial).y,false, exitLarry);
			}
		}
		
		private function exitLarry(entity:Entity):void
		{
			SceneUtil.lockInput(this, false);
			removeEntity(larry);
			removeEntity(creature);
		}
		
		private function giveLarryHat(entity:Entity):void
		{
			shellApi.removeItem(backlot.WHITE_HAT);
			SceneUtil.lockInput(this);
			SkinUtils.setSkinPart(larry, SkinUtils.HAIR, "wwannouncer",true);
			Dialog(larry.get(Dialog)).sayById("finally");
		}
		
		private function setupChickens():void
		{
			var timeline:Timeline;
			
			for(var i:int = 1; i <= 3; i++)
			{
				var clip:MovieClip = this._hitContainer["chicken" + i];
				
				var chicken:Entity = EntityUtils.createSpatialEntity(this, clip);
				var display:Display = chicken.get(Display);
				display.isStatic = true;
				
				var audioRange:AudioRange = new AudioRange(1200, .5, 1, Quad.easeIn);
				chicken.add(new Audio()).add(audioRange).add(new Id("chicken"+i));
				
				ToolTipCreator.addToEntity(chicken);
				
				var doll:Timeline = TimelineUtils.convertClip(clip["chicken"], this, null, chicken).get(Timeline);
				var text:Timeline = TimelineUtils.convertClip(clip["text"], this, null, chicken).get(Timeline);
				
				var interaction:Interaction = InteractionCreator.addToEntity(chicken, [InteractionCreator.DOWN]);
				interaction.down.add(Command.create(this.chickenClicked, doll, text));
			}
		}
		
		private function chickenClicked(chicken:Entity, doll:Timeline, text:Timeline):void
		{
			Audio(chicken.get(Audio)).play("effects/chicken_bgok_01.mp3");
			doll.gotoAndPlay(0);
			text.gotoAndPlay(0);
		}
		
		private function setupTVCamera():void
		{
			var clip:MovieClip = this._hitContainer["tv"]["cameraScreen"];
			clip.scaleX = clip.scaleY = 0.7;
			
			//TV
			var npc:Entity = this.getEntityById("creature");
			npc.get(Display).setContainer(clip);
			
			//Camera
			var camera:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["camera"]);
			var display:Display = camera.get(Display);
			display.isStatic = true;
			
			ToolTipCreator.addToEntity(camera);
			camera.add(new Tween());
			
			TimelineUtils.convertClip(this._hitContainer["camera"], this, camera, null, false);
			var timeline:Timeline = camera.get(Timeline);
			timeline.gotoAndStop("zoomOutEnd");
			
			var interaction:Interaction = InteractionCreator.addToEntity(camera, [InteractionCreator.DOWN]);
			interaction.down.add(Command.create(this.cameraClicked, clip));
		}
		
		private function cameraClicked(camera:Entity, clip:MovieClip):void
		{
			var timeline:Timeline = camera.get(Timeline);
			
			if(!timeline.playing)
			{
				timeline.playing = true;
				
				var tween:Tween = camera.get(Tween);
				
				//Little hacky, but it works.
				var scale:Number = 1;
				if(timeline.currentIndex == 24) scale = 0.7;
				else if(timeline.currentIndex == 49) scale = 1;
				
				tween.to(clip, 0.8, {scaleX:scale, scaleY:scale, ease:Linear.easeNone});
			}
		}
		
		private function setupAnimations():void
		{
			this.larry = this.getEntityById("larry");
			this.creature = this.getEntityById("creature");
			
			if(shellApi.checkEvent(backlot.FOUND_HERO))
			{
				removeEntity(larry);
				removeEntity(creature);
			}
			
			SceneUtil.addTimedEvent(this, new TimedEvent(5, 0, this.playAnimation));
		}
		
		private function playAnimation():void
		{
			var dialog:Dialog = this.larry.get(Dialog);
			
			if(!dialog.speaking && !this.isAnimating)
			{
				this.isAnimating = true;
				
				var animation:Class = ArrayUtils.getRandomElement(this.animations);
				CharUtils.setAnim(this.larry, animation);
				CharUtils.setAnim(this.creature, animation);
				
				var timeline:Timeline = this.larry.get(Timeline);
				timeline.handleLabel("ending", Command.create(function(scene:DigitalDreamScapes):void { scene.isAnimating = false; }, this));
			}
		}
	}
}