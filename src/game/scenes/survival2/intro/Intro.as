package game.scenes.survival2.intro
{
	import flash.display.DisplayObjectContainer;
	
	import game.components.audio.HitAudio;
	import game.components.entity.character.CharacterMotionControl;
	import game.data.animation.entity.character.Climb;
	import game.data.animation.entity.character.ClimbDown;
	import game.data.animation.entity.character.Fall;
	import game.scene.template.CutScene;
	import game.scenes.survival2.Survival2Events;
	import game.scenes.survival2.trees.Trees;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class Intro extends CutScene
	{
		
		public function Intro()
		{
			super();
			configData("scenes/survival2/intro/",Survival2Events(events).PLAYED_INTRO);
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
				shellApi.loadScene(Trees);
				return
			}
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
		}
		
		override public function setUpCharacters():void
		{
			setEntityContainer(player, screen.New_Symbol_2);
			
			player.add(new CharacterMotionControl()).add(new HitAudio());
			CharacterMotionControl(player.get(CharacterMotionControl)).climbingUp = false;
			
			ColorUtil.colorize(EntityUtils.getDisplayObject(player),0x617A85);
			
			CharUtils.setAnim(player, Climb);
			
			start();
		}
		
		override public function onLabelReached(label:String):void
		{
			if( label.indexOf("wind") != -1)
			{
				CharUtils.setAnim(player, ClimbDown);
				CharacterMotionControl(player.get(CharacterMotionControl)).climbingUp = false;
			}
			
			if(label == "continue")
			{
				CharUtils.setAnim(player, Climb);
				CharacterMotionControl(player.get(CharacterMotionControl)).climbingUp = true;
			}
			
			if(label == "fall")
			{
				CharUtils.setAnim(player, Fall);
			}
		}
		
		override public function end():void
		{
			super.end();
			super.shellApi.loadScene( Trees, 3000, 0, "right" );
		}
	}
}