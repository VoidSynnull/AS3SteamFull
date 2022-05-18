package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.timeline.Timeline;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Play entity timeline
	public class TimelineAction extends ActionCommand
	{
		private var startLabel:String;
		private var waitLabel:String;
		private var stopAtLabel:Boolean = true;
		
		private var _callback:Function;

		/**
		 * Play entity timeline 
		 * @param entity			Entity with timeline
		 * @param startLabel		Label to start animation
		 * @param waitLabel			Label to end animation
		 * @param stopAtLabel		Flag to stop at end label
		 */
		public function TimelineAction( entity:Entity, startLabel:String=null, waitLabel:String = "ending", stopAtLabel:Boolean = true )
		{
			this.entity = entity;
			this.waitLabel = waitLabel;
			this.startLabel = startLabel;
			this.stopAtLabel = stopAtLabel;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			var t:Timeline = entity.get( Timeline ) as Timeline;

			if (t)
			{
				if ( startLabel != null ) {
					t.gotoAndPlay( startLabel );
				} else {
					t.playing = true;
				}
	
				if ( waitLabel != null ) {
					this._callback = callback;
					t.handleLabel( waitLabel, onLabel, true );
				} else {
					callback();
				}
			}
		}

		private function onLabel():void
		{
			if ( stopAtLabel ) {
				var tl:Timeline = entity.get( Timeline );
				tl.playing = false;
			}
			_callback();
		}
	}
}