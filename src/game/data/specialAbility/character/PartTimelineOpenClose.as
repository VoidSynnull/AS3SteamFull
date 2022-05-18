// Used by:
// Card 2676 using item limited_percyjackson_sword
// Card 3001 using item pball1
// Card 3002 using item priding1, priding2, priding3
// Card 3044 using facial probot4_1, probot4_2, probot4_3
// Card 3326 using facial hazmat1
// Card 3331 using facial store_scidoctor
// Card 3358 using facial atlantis3_pilot

package game.data.specialAbility.character 
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.components.timeline.Timeline;
	import game.data.animation.Animation;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;

	/**
	 * Plays part timeline at labels "open"/"close" to toggle states
	 * and lets you play the animation when the Special Ability is activated
	 * 
	 * required params:
	 * partType		String		Name of part type
	 */
	public class PartTimelineOpenClose extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				partEntity = CharUtils.getPart(super.entity, _partType);
				timeline = partEntity.get(Timeline);
				
				if(isOpen)
					doClose();
				else
					doOpen();
			}
		}
		
		// Functions for opening and closing
		private function doOpen():void
		{	
			super.setActive( true );
			timeline.gotoAndPlay("open");
			timeline.handleLabel("close", openComplete);
		}
		
		private function openComplete():void
		{
			timeline.stop();
			isOpen = true;
			super.setActive( false );
		}
		
		private function doClose():void
		{	
			super.setActive( true );
			timeline.gotoAndPlay("close");
			timeline.handleLabel(Animation.LABEL_ENDING, closeComplete);
		}
		
		private function closeComplete():void
		{
			timeline.stop();
			isOpen = false;
			super.setActive( false );
		}
		
		public var required:Array = ["partType"];
		
		public var _partType:String;
		public var _childClip:String; // NOT USED
		
		private var partEntity:Entity;
		private var partClip:MovieClip;
		private var timeline:Timeline;
		private var timelineMC:MovieClip;
		private var isOpen:Boolean = false;
	}
}