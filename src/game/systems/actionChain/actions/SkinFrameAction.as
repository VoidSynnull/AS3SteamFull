package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	
	import game.components.timeline.Timeline;
	import game.data.animation.Animation;
	import game.systems.actionChain.ActionCommand;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import flash.display.MovieClip;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Play or stop at a frame in an avatar part timeline
	public class SkinFrameAction extends ActionCommand 
	{
		private var partType:String;
		private var startFrame:*;
		private var mode:String;
		private var endLabel:*;
		private var childName:String;

		private var _callback:Function;
		
		/**
		 * Play or stop at a frame in an avatar part timeline
		 * @param char			Entity whose part timeline will be played
		 * @param partType		Name of part type
		 * @param startFrame	Frame label to start at
		 * @param mode			Play mode (play, stop, gotoAndPlay, gotoAndStop)
		 * @param endLabel		Frame label to stop at - if no end label given, then it completes on the last frame
		 * @param childName		Name of child clip whose timeline will be played
		 */
		public function SkinFrameAction( char:Entity, partType:String, startFrame:* = 0, mode:String = "play", endLabel:* = Animation.LABEL_ENDING, childName:String = null ) 
		{
			entity = char;

			this.partType = partType;
			this.startFrame = startFrame;
			this.mode = mode;
			this.endLabel = endLabel;
			this.childName = childName;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			_callback = callback;
			
			// get timeline
			var part:Entity = SkinUtils.getSkinPartEntity(entity, partType);
			var timeline:Timeline;
			if (childName)
			{
				var clip:MovieClip = MovieClip(part.get(Display).displayObject);
				part = TimelineUtils.convertClip(clip[childName], group);
				timeline = part.get(Timeline);
			}
			else
			{
				timeline = part.get(Timeline);
			}
			
			switch(mode)
			{
				case "gotoAndPlay":
					timeline.gotoAndPlay(startFrame);
					break;
				case "gotoAndStop":
					timeline.gotoAndStop(startFrame);
					break;
				case "stop":
					timeline.stop();
					break;
				case "play":
					timeline.play();
					break;
			}
			TimelineUtils.onLabel( part, endLabel, doneAnim );
		}
		
		/**
		 * When part timeline done 
		 */
		private function doneAnim():void
		{
			_callback();
		}
	}
}