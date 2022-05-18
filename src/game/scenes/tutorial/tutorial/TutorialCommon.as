package game.scenes.tutorial.tutorial
{
	import com.greensock.easing.Quad;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.data.ui.ToolTipType;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.hub.shared.managers.ShardManager;
	import game.scenes.hub.town.Town;
	import game.scenes.tutorial.TutorialEvents;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class TutorialCommon extends PlatformerGameScene
	{
		public function TutorialCommon()
		{
			super();
		}
		
		// all assets ready
		override public function loaded():void
		{
			_events = (super.events as TutorialEvents);
			super.loaded();
			
			setupHover();
			setupPilot();
			setupRunners();
			setupRunners();
			setupRunners();
			
			if(!PlatformUtils.isMobileOS)
			{
				CharacterMotionControl(super.player.get(CharacterMotionControl)).allowAutoTarget = false;
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, restoreAirControl));
			}
			
			var hudClip:MovieClip = MovieClip(DisplayGroup(this).container.addChild(hitContainer["hud"]));
			hudClip.x = -shellApi.camera.viewport.width/2/this.container.scaleX;
			hudClip.y = -shellApi.camera.viewport.height/2/this.container.scaleY;
			var hud:Entity = TimelineUtils.convertClip(hudClip, this, null, null, false);
			var timeline:Timeline = hud.get(Timeline);

			_shardManager = new ShardManager(this, doWinSequence, timeline);
			_shardManager.addShards(super._hitContainer);
			
			shellApi.eventTriggered.add(onEventTriggered);
		}
		
		private function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if (event == "winDone")
			{
				// go to home island
				shellApi.loadScene(Town, 4720, 880);
			}
		}
		
		protected function setupAnimal(anim:String):void
		{
			var clip:MovieClip = MovieClip(_hitContainer[anim]);
			if (clip == null)
				clip = this.getEntityById("animations").get(Display).displayObject[anim];
			var entity:Entity = TimelineUtils.convertClip(clip, this);
			var timeline:Timeline = Timeline(entity.get(Timeline));
			entity.add(new Spatial(clip.x, clip.y));
			entity.add(new Display(clip));
			timeline.labelReached.add(Command.create(checkLabel, timeline));
			ToolTipCreator.addToEntity(entity, ToolTipType.CLICK, null, new Point(0,0));
			var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
			interaction.click.add(onClickAnimal);
			switch(anim)
			{
				case "parrot":
					CharUtils.assignDialog(entity, this, anim, false, 0.25, 0);
					break;
				case "fox":
					CharUtils.assignDialog(entity, this, anim, false, 0.3, 0);
					break;
				case "dog2":
					CharUtils.assignDialog(entity, this, anim, false, -0.25, 0);
					break;
			}
		}
		
		private function checkLabel(label:String, timeline:Timeline):void
		{
			switch(label)
			{
				case "loopEnd":
				case "clickEnd":
					timeline.gotoAndPlay("loop");
					break;
				case "clickLoop":
					timeline.gotoAndPlay("click");
					break;
			}
		}
		
		private function onClickAnimal(entity:Entity):void
		{
			var id:String = entity.get(Id).id;
			switch(id)
			{
				case "fox":
					entity.get(Dialog).setThoughtBalloon();
					CharUtils.sayDialog(entity, "default");
					return;
				case "dog2":
				case "parrot":
					CharUtils.sayDialog(entity, "default");
					CharUtils.dialogComplete(entity, Command.create(dialogDone, entity));
			}
			entity.get(Timeline).gotoAndPlay("click");
		}
		
		private function dialogDone(dialog:DialogData, entity:Entity):void
		{
			entity.get(Timeline).gotoAndPlay("loop");
			entity.get(Dialog).resetBalloon();
		}
		
		protected function setupPilot():void
		{
			if(this.shellApi.checkEvent(TutorialEvents.FOUND_ALL_COINS))
			{
				var pilot:Entity = super.getEntityById("pilot");
				pilot.add( new Sleep( true, true ));
			}
		}
		
		protected function setupHover():void
		{
			var char:Entity = this.getEntityById("amelia");
			
			var hover:MovieClip = _hitContainer["hovercraft"];
			_hoverCraft = EntityUtils.createMovingEntity(this, hover, _hitContainer);

			var charGroup:CharacterGroup = CharacterGroup(this.getGroupById(CharacterGroup.GROUP_ID));
			charGroup.removeFSM(char);
			
			char.add(new Motion()); // turn off falling 
			
			var spatial:Spatial = char.get(Spatial);
			spatial.rotation = 0;
			
			// add spatial offset if necessary
			spatial.x = 0;
			spatial.y = -40;
			
			CharUtils.setDirection(char, false);
			
			// remove sleep
			Sleep(char.get(Sleep)).sleeping = false;
			Sleep(char.get(Sleep)).ignoreOffscreenSleep = true;
			
			var display:Display = char.get(Display);
			display.setContainer(EntityUtils.getDisplayObject(_hoverCraft));
			
			_hoverCraft.get(Spatial).scaleX *= -1;
		}
		
		private function setupRunners():void
		{
			var runner1:Entity = this.getEntityById("runner1");
			doDelay();
			SceneUtil.delay(this, _npcDelay, Command.create(runPath, runner1));
			var runner2:Entity = this.getEntityById("runner2");
			doDelay();
			SceneUtil.delay(this, _npcDelay, Command.create(runPath, runner2));
			var runner3:Entity = this.getEntityById("runner3");
			doDelay();
			SceneUtil.delay(this, _npcDelay, Command.create(runPath, runner3));
			var runner4:Entity = this.getEntityById("runner4");
			doDelay();
			SceneUtil.delay(this, _npcDelay, Command.create(runPath, runner4));
			var runner5:Entity = this.getEntityById("runner5");
			doDelay();
			SceneUtil.delay(this, _npcDelay, Command.create(runPath, runner5));
			var runner6:Entity = this.getEntityById("runner6");
			doDelay();
			SceneUtil.delay(this, _npcDelay, Command.create(runPath, runner6));
		}
		
		private function doDelay():void
		{
			var time:int = 10;
			var variation:int = 5;
			var delay:int = time + Math.floor(variation * Math.random());
			_npcDelay += delay;
		}
		
		protected function runPath(char:Entity):void
		{
			// to be overridden
		}
		
		private function restoreAirControl():void
		{
			CharacterMotionControl(super.player.get(CharacterMotionControl)).allowAutoTarget = true;
		}
		
		private function doWinSequence(coinNum:int, test:Boolean = false):void
		{
			trace("coin " + coinNum);
			_test = test;
			var point:Point = getCoinOffset(coinNum);
			var offsetX:Number = point.x;
			var offsetY:Number = point.y;
			// get player spatial
			var spatial:Spatial = shellApi.player.get(Spatial);
			// set starting position
			_hoverCraft.get(Spatial).x = spatial.x + offsetX;
			_hoverCraft.get(Spatial).y = spatial.y - 700;
			// hide NPC
			var pilot:Entity = super.getEntityById("pilot");
			pilot.add( new Sleep( true, true ));
			// tween to location
			TweenUtils.entityTo( _hoverCraft, Spatial, 1, { x:spatial.x + offsetX, y:spatial.y + offsetY, ease:Quad.easeOut, onComplete:winDialog } );
		}
		
		protected function getCoinOffset(coinNum:int):Point
		{
			// to be overridden
			return new Point(0,0);
		}
		
		private function winDialog():void
		{
			if (!_test)
			{
				var amelia:Entity = this.getEntityById("amelia");
				CharUtils.sayDialog(amelia,"win");
			}
		}
		
		protected var _events:TutorialEvents;
		protected var _shardManager:ShardManager;
		private var _hoverCraft:Entity;
		private var _test:Boolean = false;
		private var _npcDelay:int = 0;
	}
}