package game.scenes.backlot.talent
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Dialog;
	import game.components.motion.MotionTarget;
	import game.components.entity.character.Character;
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.SkinPart;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.SkinCreator;
	import game.data.animation.entity.character.Cry;
	import game.data.character.part.SkinPartId;
	import game.scenes.backlot.BacklotEvents;
	import game.scene.template.PlatformerGameScene;
	import game.systems.motion.NavigationSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class Talent extends PlatformerGameScene
	{
		public function Talent()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/talent/";
			
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
			_events = super.events as BacklotEvents;
			super.loaded();
			
			//NavigationSystem(super.getSystem(NavigationSystem)).debug = true;
			
			setUpTalentAgent();
			
			super.shellApi.eventTriggered.add(onEventTriggered );
		}
		
		private function setUpTalentAgent():void
		{
			gracie = super.getEntityById("char5");
			var display:Display = gracie.get(Display);
			display.moveToBack();
			if(!super.shellApi.checkEvent(_events.TALK_TO_HARVEY))
			{
				var sceneInteraction:SceneInteraction = gracie.get(SceneInteraction);
				sceneInteraction.reached.addOnce(talk);
			}
			if(shellApi.checkEvent(_events.FOUND_GRACIE))
			{
				removeEntity(gracie);
			}
		}
		
		private function talk(player:Entity, talentAgent:Entity):void
		{
			SceneUtil.lockInput(this, true);
			CharUtils.lockControls(player);
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			trace(event);
			if(event == _events.TALK_TO_HARVEY)
			{
				SceneUtil.lockInput(this, false);
				CharUtils.lockControls(player, false, false);
			}
			
			if(event == _events.CRY)
			{
				CharUtils.setAnim(super.getEntityById("char4"),Cry,false,60);
			}
			
			if(event == _events.HEAD_SHOT)
			{
				if(player.get(Spatial).x > 700)
				{
					SceneUtil.lockInput(this);// removing the card unlocks the input dont know why // done through the dialog
					
					CharUtils.moveToTarget(player, gracie.get(Spatial).x - 100, gracie.get(Spatial).y, false, talkToGracie);
				}
			}
			
			if(event == _events.CHANGE_INTO_STAR)
			{
				SkinUtils.emptySkinPart(gracie,SkinUtils.FACIAL);
				
				var path:Vector.<Point> = new <Point>[new Point(675,150), new Point(625,350)];
				
				CharUtils.followPath( gracie, path, fnDoneMove );
			}
			
			if(event == _events.FOUND_GRACIE)
			{
				CharUtils.moveToTarget(gracie, getEntityById("door1").get(Spatial).x, getEntityById("door1").get(Spatial).y,false, exitGracie);
			}
		}
		
		private function talkToGracie(entity:Entity):void
		{
			CharUtils.setDirection(player, true);
			player.get(Dialog).sayById("help");
		}
		
		private function fnDoneMove(entity:Entity):void
		{
			CharUtils.setDirection(gracie, true);
			Dialog(gracie.get(Dialog)).sayById("at your service");
		}
		
		private function exitGracie(entity:Entity):void
		{
			removeEntity(gracie);
			SceneUtil.lockInput(this, false);
		}
		
		private var gracie:Entity;
		
		private var _events:BacklotEvents;
	}
}