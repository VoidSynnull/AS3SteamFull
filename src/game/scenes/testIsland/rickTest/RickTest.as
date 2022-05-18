package game.scenes.testIsland.rickTest
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.components.entity.character.Character;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Cry;
	import game.data.character.CharacterData;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;

	
	public class RickTest extends PlatformerGameScene
	{
		
		public function RickTest()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/testIsland/rickTest/";
			
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
			
			// convert fans into timeline entities
			TimelineUtils.convertClip( super._hitContainer["fan1"], this );
			TimelineUtils.convertClip( super._hitContainer["fan2"], this );
			TimelineUtils.convertClip( super._hitContainer["fan3"], this );
									
			// catch events
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			var player:DisplayObjectContainer = super.player.get(Display).displayObject;
			var desk:MovieClip = super.getAsset("desk.swf");
			super._hitContainer.addChild( desk );
			super._hitContainer.swapChildren(desk,player); 			
			
			// mom1 doesn't face speaker
			super.getEntityById("mom1").get(Dialog).faceSpeaker = false;
			// hide gracie if used headshot
			if (super.shellApi.checkEvent("backlot_usedHeadshot"))
				super.getEntityById("gracie").get(Display).visible = false;
		}
		
		private function handleEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event)
			{
				case "mom2a":
					// make dakota cry, then mom2 speaks
					CharUtils.setAnim( super.getEntityById("dakota"), Cry );
					// both work. the second one doesn't require removing the listener
					//var vTimeline:Timeline = super.getEntityById("dakota").get(Timeline);
					//vTimeline.labelReached.add( onLabelReached );
					TimelineUtils.onLabel( super.getEntityById("dakota"), Animation.LABEL_ENDING, fnDoneCry );
					break;
				case "mom1-3":
					// reset dialog to beginning
					Dialog(super.getEntityById("mom1").get(Dialog)).setCurrentById("default");
					break;
				case "gracie1":
					// lock input
					SceneUtil.lockInput( this );
					break;
				case "gracie5":
					// complete event
					super.shellApi.completeEvent("backlot_talkToHarvey");
					// reset dialog to beginning
					var gracie:Entity = super.getEntityById("gracie");
					Dialog(gracie.get(Dialog)).setCurrentById("default");
					// restore input
					SceneUtil.lockInput( this, false );
					// remove glasses
					SkinUtils.setSkinPart( gracie, SkinUtils.FACIAL, "1" );
					// walk from behind desk
					CharUtils.moveToTarget(gracie, 650, 420, true, fnDoneJump).setDirectionOnReached( CharUtils.DIRECTION_RIGHT );
					// this didn't work
					//CharUtils.moveToTarget(super.getEntityById("gracie"), 500, 425, true, fnDoneJump);
					break;
				case "graciejump1":
					// walk offscreen
					CharUtils.moveToTarget(super.getEntityById("gracie"), 650, 420, false, fnDoneWalk);
					break;
			}
		}
		
		private function onLabelReached( label:String ):void
		{
			// when we reach the last frame we remove our listener.
			if ( label == Animation.LABEL_ENDING )
			{
				var vTimeline:Timeline = super.getEntityById("dakota").get(Timeline);
				vTimeline.labelReached.remove( onLabelReached );
				// mom2 speaks
				super.shellApi.triggerEvent("mom2b");
			}
		}
		
		private function fnDoneJump(aEntity:Entity):void
		{
			// player turns to face gracie
			CharUtils.setDirection(super.player, false);
			// gracie speaks
			super.shellApi.triggerEvent("graciejump");
		}
		
		private function fnDoneWalk(aEntity:Entity):void
		{
			// hide gracie and complete event
			aEntity.get(Display).visible = false;
			super.shellApi.completeEvent("backlot_usedHeadshot");
		}
		
		private function fnDoneCry():void
		{
			// mom2 speaks
			super.shellApi.triggerEvent("mom2b");
		}
	}
}