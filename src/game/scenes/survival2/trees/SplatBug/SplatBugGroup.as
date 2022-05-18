package game.scenes.survival2.trees.SplatBug
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.sound.SoundModifier;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class SplatBugGroup extends Group
	{		
		private const INSECT_SOUND:String = "small_insect_movement_01_loop.mp3";
		private const SQUISH_SOUND:String = "squish_02.mp3";
		
		public function SplatBugGroup(scene:Group, container:DisplayObjectContainer, bugs:int)
		{
			var range:AudioRange = new AudioRange(500, 0, 1, Quad.easeIn);
			scene.addSystem(new SplatBugSystem());
			for(var i:int = 0; i <=bugs; i++)
			{
				var clip:MovieClip = container["splatBug"+i];
				if(clip == null)
					continue;
				var splatBug:Entity = EntityUtils.createSpatialEntity(scene, clip, container);
				TimelineUtils.convertClip(clip, scene, splatBug, null, false);
				splatBug.add(new SplatBug(clip)).add(new Audio()).add(range);
				var interaction:Interaction = InteractionCreator.addToEntity(splatBug, ["click"], clip);
				interaction.click.add(splat);
				ToolTipCreator.addToEntity(splatBug);
				Audio(splatBug.get(Audio)).play(SoundManager.EFFECTS_PATH+INSECT_SOUND, true, SoundModifier.POSITION);
			}
		}
		
		private function splat(bug:Entity):void
		{
			Timeline(bug.get(Timeline)).gotoAndStop(1);
			bug.remove(SplatBug);
			ToolTipCreator.removeFromEntity(bug);
			Audio(bug.get(Audio)).play(SoundManager.EFFECTS_PATH+SQUISH_SOUND, false, SoundModifier.POSITION);
			Audio(bug.get(Audio)).stop(SoundManager.EFFECTS_PATH+INSECT_SOUND, "effects");
		}
	}
}