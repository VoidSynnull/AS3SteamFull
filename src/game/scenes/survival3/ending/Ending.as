package game.scenes.survival3.ending
{
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.Jump;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Tremble;
	import game.data.comm.PopResponse;
	import game.scene.template.CutScene;
	import game.scenes.survival3.Survival3Events;
	import game.systems.entity.EyeSystem;
	import game.ui.popup.IslandEndingPopup;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	public class Ending extends CutScene
	{
		private var _volume:Number = 1;
		private const HELICOPTER:String = "helicopter_loop_01.mp3";
		
		public function Ending()
		{
			super();
			configData("scenes/survival3/ending/", Survival3Events(super.events).PLAYED_INTRO);
		}
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			sceneAudio.play(SoundManager.EFFECTS_PATH + HELICOPTER, true);
		}
		
		override public function setUpCharacters():void
		{
			setEntityContainer(player, screen.tower.player.Avatar1);
			
			CharUtils.setAnim(player, DuckDown);
			
			start();
		}
		
		override public function onLabelReached(label:String):void
		{
			if(label.indexOf("jump") != -1)
			{
				CharUtils.setAnim(player, Jump);
			}
			if(label.indexOf("stand") != -1)
			{
				CharUtils.setAnim(player, Stand);
				SkinUtils.setEyeStates( player, EyeSystem.CASUAL_STILL, null, true );
				shellApi.triggerEvent(label);
				sceneAudio.setVolume(++_volume);
			}
			var head:Entity;
			var hair:Entity;
			if(label.indexOf("lookUp") != -1)
			{
				head = CharUtils.getJoint(player, CharUtils.HEAD_JOINT);
				TweenUtils.entityTo(head, Spatial, 1, {rotation:20});
				//grab the hair as well
				hair = CharUtils.getJoint(player, CharUtils.HAIR);
				if(hair != null)
					TweenUtils.entityTo(hair, Spatial, 1, {rotation:20});
				
				sceneAudio.setVolume(++_volume);
			}
			if(label.indexOf("lookDown") != -1)
			{
				head = CharUtils.getJoint(player, CharUtils.HEAD_JOINT);
				TweenUtils.entityTo(head, Spatial, 1, {rotation:0});
				//grab the hair as well
				hair = CharUtils.getJoint(player, CharUtils.HAIR);
				if(hair != null)
					TweenUtils.entityTo(hair, Spatial, 1, {rotation:0});
				
				sceneAudio.setVolume(++_volume);
			}
			if(label.indexOf("scaredLookAtCamera") != -1)
			{
				CharUtils.setAnim(player, Tremble);
				SkinUtils.setEyeStates(player, EyeSystem.OPEN, null, true);
			}
		}
		
		override public function end():void
		{
			super.end();
			shellApi.completedIsland('', onCompletions);
		}

		private function onCompletions(response:PopResponse):void
		{
			SceneUtil.lockInput(this, false);
			this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
			//addChildGroup(new VictoryPopup(overlayContainer));
		}
	}
}