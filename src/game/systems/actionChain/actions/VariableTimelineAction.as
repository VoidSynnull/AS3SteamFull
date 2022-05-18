package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.entity.VariableTimeline;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Play entity variable timeline
	public class VariableTimelineAction extends ActionCommand
	{
		private var startLabel:String;
		private var waitLabel:String;
		
		public var stopAtLabel:Boolean = true;
		
		private var _callback:Function;

		/**
		 * If true, just wait for the end of the variable timeline.
		 */
		public var waitEnd:Boolean = false;

		/**
		 * Play entity variable timeline 
		 * @param entity			Entity with timeline
		 * @param startLabel		Label to start animation
		 * @param waitLabel			Label to end animation
		 */
		public function VariableTimelineAction( entity:Entity, startLabel:String = null, waitLabel:String = "ending" ) 
		{
			super.entity = entity;

			this.startLabel = startLabel;
			this.waitLabel = waitLabel;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			var t:VariableTimeline = super.entity.get( VariableTimeline ) as VariableTimeline;

			if ( this.startLabel != null ) 
			{
				t.gotoAndPlay( this.startLabel );
			} 
			else 
			{
				t.playing = true;
			}

			if ( this.waitLabel != null ) 
			{
				this._callback = callback;
				t.handleLabel( this.waitLabel, this.onLabel, true );
			} 
			else if ( this.waitEnd ) 
			{
				// later make a different function. at the moment they both take the same stupid parameters.
				t.onTimelineEnd.addOnce( this.onLabel );
			} 
			else 
			{
				callback();
			}
		}

		private function onLabel( e:Entity, tl:VariableTimeline ):void 
		{
			if ( this.stopAtLabel ) {
				tl.playing = false;
			}
			this._callback();
		}
	}
}